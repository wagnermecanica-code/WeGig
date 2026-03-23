import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_providers.g.dart';

/// Mensagens padronizadas para bloqueios intencionais no fluxo de denúncia.
///
/// Mantemos como constantes para a UI poder tratar como aviso (snackbar) e
/// evitar comparação com strings soltas espalhadas pelo app.
abstract final class ReportErrors {
  static const notLoggedIn = 'Você precisa estar logado para reportar';
  static const dailyLimitReached =
      'Você atingiu o limite de denúncias diárias. Tente novamente amanhã.';
  static const alreadyReported = 'Você já reportou este conteúdo anteriormente.';
}

/// Tipos de conteúdo reportável
enum ReportTargetType {
  post,
  profile,
}

/// Motivos pré-definidos para reportar POSTS/ANÚNCIOS
enum PostReportReason {
  spam('Spam ou propaganda enganosa'),
  inappropriate('Conteúdo inapropriado'),
  harassment('Assédio ou bullying'),
  falseInfo('Informações falsas'),
  scam('Golpe ou fraude'),
  violence('Violência ou ameaças'),
  hateSpeech('Discurso de ódio'),
  intellectualProperty('Violação de direitos autorais'),
  other('Outro');

  const PostReportReason(this.label);
  final String label;
}

/// Motivos pré-definidos para reportar PERFIS
enum ProfileReportReason {
  fakeProfile('Perfil falso ou impostor'),
  spam('Spam ou propaganda'),
  harassment('Assédio ou bullying'),
  inappropriateContent('Conteúdo inapropriado'),
  scam('Golpe ou fraude'),
  hateSpeech('Discurso de ódio'),
  underage('Menor de idade'),
  other('Outro');

  const ProfileReportReason(this.label);
  final String label;
}

/// Modelo de dados para um report
class ReportData {
  const ReportData({
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.description,
  });

  final ReportTargetType targetType;
  final String targetId;
  final String reason;
  final String? description;

  Map<String, dynamic> toFirestore(String reporterUid) {
    return {
      if (targetType == ReportTargetType.post) 'reportedPostId': targetId,
      if (targetType == ReportTargetType.profile) 'reportedProfileId': targetId,
      'reporterUid': reporterUid,
      'reason': reason,
      'description': description?.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'reportedBy': FieldValue.arrayUnion([reporterUid]),
    };
  }
}

/// Estado do report (classe simples sem Freezed)
class ReportState {
  const ReportState({
    this.isSubmitting = false,
    this.error,
    this.submitted = false,
    this.wasDuplicate = false,
  });

  final bool isSubmitting;
  final String? error;
  final bool submitted;
  final bool wasDuplicate;

  ReportState copyWith({
    bool? isSubmitting,
    String? error,
    bool? submitted,
    bool? wasDuplicate,
  }) {
    return ReportState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      submitted: submitted ?? this.submitted,
      wasDuplicate: wasDuplicate ?? this.wasDuplicate,
    );
  }
}

/// Provider para gerenciar submissão de reports
@riverpod
class ReportNotifier extends _$ReportNotifier {
  @override
  ReportState build() => const ReportState();

  /// Envia um report para o Firestore
  /// 
  /// Retorna true se o report foi enviado com sucesso
  Future<bool> submitReport(ReportData reportData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = state.copyWith(
        error: ReportErrors.notLoggedIn,
        isSubmitting: false,
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null, wasDuplicate: false);

    try {
      // Verificar se já reportou este item (idempotência).
      // NOTA: A query DEVE incluir reporterUid para Security Rules permitirem
      final targetField = reportData.targetType == ReportTargetType.post 
          ? 'reportedPostId' 
          : 'reportedProfileId';
      
      final existingReport = await FirebaseFirestore.instance
          .collection('reports')
          .where('reporterUid', isEqualTo: user.uid)
          .where(targetField, isEqualTo: reportData.targetId)
          .limit(1)
          .get();

      if (existingReport.docs.isNotEmpty) {
        // Em vez de bloquear o fluxo com erro (o que frequentemente parece bug),
        // tratamos como operação idempotente: não cria outro doc e retorna sucesso.
        debugPrint(
          'ℹ️ Report duplicado detectado (idempotente): ${reportData.targetType.name} ${reportData.targetId} (uid=${user.uid})',
        );
        state = state.copyWith(
          isSubmitting: false,
          submitted: true,
          wasDuplicate: true,
          error: null,
        );
        return true;
      }

      // Verificar rate limiting (máximo 10 reports por dia)
      // (executa APÓS o duplicate check para não penalizar tentativas idempotentes)
      final todayStart = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
      );
      
      final recentReports = await FirebaseFirestore.instance
          .collection('reports')
          .where('reporterUid', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .count()
          .get();

      if (recentReports.count != null && recentReports.count! >= 10) {
        state = state.copyWith(
          error: ReportErrors.dailyLimitReached,
          isSubmitting: false,
        );
        return false;
      }

      // Criar o report
      await FirebaseFirestore.instance
          .collection('reports')
          .add(reportData.toFirestore(user.uid));

      debugPrint('✅ Report enviado com sucesso: ${reportData.targetType.name} ${reportData.targetId}');

      state = state.copyWith(
        isSubmitting: false,
        submitted: true,
        wasDuplicate: false,
      );
      return true;
    } on FirebaseException catch (e) {
      debugPrint('❌ Erro Firebase ao enviar report: ${e.message}');
      state = state.copyWith(
        error: 'Erro ao enviar denúncia. Tente novamente.',
        isSubmitting: false,
      );
      return false;
    } catch (e) {
      debugPrint('❌ Erro ao enviar report: $e');
      state = state.copyWith(
        error: 'Erro inesperado. Tente novamente.',
        isSubmitting: false,
      );
      return false;
    }
  }

  /// Reseta o estado para permitir novo report
  void reset() {
    state = const ReportState();
  }
}
