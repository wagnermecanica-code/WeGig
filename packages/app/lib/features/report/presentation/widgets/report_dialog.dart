import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:core_ui/core_ui.dart';

import '../providers/report_providers.dart';
import 'package:wegig_app/core/firebase/blocked_profiles.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

class _ResolvedOwnerInfo {
  const _ResolvedOwnerInfo({
    required this.uid,
    this.profileId,
    this.name,
    this.username,
    this.photoUrl,
    this.city,
    this.neighborhood,
    this.state,
    this.isBand,
  });

  final String uid;
  final String? profileId;
  final String? name;
  final String? username;
  final String? photoUrl;
  final String? city;
  final String? neighborhood;
  final String? state;
  final bool? isBand;
}

/// Exibe um bottom sheet para reportar um post ou perfil.
/// 
/// [context] - BuildContext para exibir o dialog
/// [targetType] - Tipo de conteúdo sendo reportado (post ou profile)
/// [targetId] - ID do post ou perfil sendo reportado
/// [targetName] - Nome descritivo do alvo (para exibição)
void showReportDialog({
  required BuildContext context,
  required ReportTargetType targetType,
  required String targetId,
  String? targetName,
  String? ownerUid,
  String? ownerProfileId,
  String? ownerName,
  String? ownerUsername,
  String? ownerPhotoUrl,
  String? ownerCity,
  String? ownerNeighborhood,
  String? ownerState,
  bool? ownerIsBand,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ReportBottomSheet(
      parentContext: context,
      targetType: targetType,
      targetId: targetId,
      targetName: targetName,
      ownerUid: ownerUid,
      ownerProfileId: ownerProfileId,
      ownerName: ownerName,
      ownerUsername: ownerUsername,
      ownerPhotoUrl: ownerPhotoUrl,
      ownerCity: ownerCity,
      ownerNeighborhood: ownerNeighborhood,
      ownerState: ownerState,
      ownerIsBand: ownerIsBand,
    ),
  );
}

class _ReportBottomSheet extends ConsumerStatefulWidget {
  const _ReportBottomSheet({
    required this.parentContext,
    required this.targetType,
    required this.targetId,
    this.targetName,
    this.ownerUid,
    this.ownerProfileId,
    this.ownerName,
    this.ownerUsername,
    this.ownerPhotoUrl,
    this.ownerCity,
    this.ownerNeighborhood,
    this.ownerState,
    this.ownerIsBand,
  });

  final BuildContext parentContext;
  final ReportTargetType targetType;
  final String targetId;
  final String? targetName;
  final String? ownerUid;
  final String? ownerProfileId;
  final String? ownerName;
  final String? ownerUsername;
  final String? ownerPhotoUrl;
  final String? ownerCity;
  final String? ownerNeighborhood;
  final String? ownerState;
  final bool? ownerIsBand;

  @override
  ConsumerState<_ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends ConsumerState<_ReportBottomSheet> {
  String? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  final int _maxDescriptionLength = 200;

  void _showSnackAboveBottomSheet({
    required String message,
    required bool isError,
  }) {
    final parentContext = widget.parentContext;
    if (!parentContext.mounted) return;

    final screenHeight = MediaQuery.sizeOf(parentContext).height;
    // The sheet can occupy up to 85% of the screen. If we show a floating
    // SnackBar at the bottom, it can be covered by the sheet. Push it up.
    final bottomMargin = (screenHeight * 0.85).clamp(0.0, screenHeight - 120.0);

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Iconsax.close_circle : Iconsax.danger,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? Colors.red : Colors.orange,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(16, 16, 16, bottomMargin + 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final messenger = ScaffoldMessenger.of(parentContext);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(snackBar);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> get _reasons {
    if (widget.targetType == ReportTargetType.post) {
      return PostReportReason.values.map((e) => e.label).toList();
    } else {
      return ProfileReportReason.values.map((e) => e.label).toList();
    }
  }

  String get _targetTypeLabel {
    return widget.targetType == ReportTargetType.post ? 'post' : 'perfil';
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      _showSnackAboveBottomSheet(
        message: 'Selecione um motivo para a denúncia',
        isError: false,
      );
      return;
    }

    final reportData = ReportData(
      targetType: widget.targetType,
      targetId: widget.targetId,
      reason: _selectedReason!,
      description: _descriptionController.text.isNotEmpty 
          ? _descriptionController.text 
          : null,
    );

    final success = await ref
        .read(reportNotifierProvider.notifier)
        .submitReport(reportData);

    if (!mounted) return;

    if (success) {
      // Capture anything we need from providers BEFORE closing the bottom sheet.
      // After Navigator.pop, this widget can be disposed and `ref` becomes invalid.
      final wasDuplicate = ref.read(reportNotifierProvider).wasDuplicate;
      final blockerProfile = ref.read(activeProfileProvider);

      Navigator.of(context).pop();

      // Usa o context de fora do bottom sheet para snack/dialog (evita context desmontado).
      final parentContext = widget.parentContext;
      if (parentContext.mounted) {
        AppSnackBar.showSuccess(
          parentContext,
          wasDuplicate
              ? 'Denúncia já estava registrada. Obrigado por ajudar a manter o WeGig seguro.'
              : 'Denúncia enviada! Obrigado por ajudar a manter o WeGig seguro.',
        );
      }

      await _maybeAskToBlockOwner(
        parentContext,
        blockerProfile: blockerProfile,
      );
    } else {
      final error = ref.read(reportNotifierProvider).error;
      if (error != null) {
        final isWarning = error == ReportErrors.alreadyReported ||
            error == ReportErrors.dailyLimitReached ||
            error == ReportErrors.notLoggedIn;

        // While the bottom sheet is open, a SnackBar anchored at the bottom can be
        // visually covered by the sheet. Show it above the sheet.
        _showSnackAboveBottomSheet(
          message: error,
          isError: !isWarning,
        );
      }
    }
  }

  Future<void> _maybeAskToBlockOwner(
    BuildContext parentContext, {
    required ProfileEntity? blockerProfile,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    if (blockerProfile == null) return;

    final initialOwnerUid = (widget.ownerUid ?? '').trim();
    final resolved = await _resolveOwnerInfo(fallbackUid: initialOwnerUid);
    if (resolved == null) return;
    
    final ownerProfileId = (resolved.profileId ?? '').trim();
    if (ownerProfileId.isEmpty) return;
    if (ownerProfileId == blockerProfile.profileId) return;

    // Evita perguntar se já está excluído (bloqueado por mim OU me bloqueou).
    try {
      final excluded = await BlockedRelations.getExcludedProfileIds(
        firestore: FirebaseFirestore.instance,
        profileId: blockerProfile.profileId,
        uid: currentUser.uid,
      );
      if (excluded.contains(ownerProfileId)) return;
    } catch (_) {
      // Se falhar, ainda pode perguntar.
    }

    if (!parentContext.mounted) return;

      final ownerNameTrimmed = (resolved.name ?? '').trim();
      final ownerUsernameTrimmed = (resolved.username ?? '').trim();

      final ownerLabel = ownerNameTrimmed.isNotEmpty
          ? '\"$ownerNameTrimmed\"'
          : (ownerUsernameTrimmed.isNotEmpty ? '@$ownerUsernameTrimmed' : 'este perfil');

      final title = switch (widget.targetType) {
        ReportTargetType.post => 'Bloquear autor do post?',
        ReportTargetType.profile => 'Bloquear este perfil?',
      };

      final content = switch (widget.targetType) {
        ReportTargetType.post =>
          'Deseja bloquear $ownerLabel também?\n\nVocê deixará de ver posts e perfis desse perfil no feed e na busca.',
        ReportTargetType.profile =>
          'Deseja bloquear $ownerLabel também?\n\nVocê deixará de ver conteúdo desse perfil no feed e na busca.',
      };

    final shouldBlock = await showDialog<bool>(
      context: parentContext,
      builder: (ctx) {
        final screenHeight = MediaQuery.of(ctx).size.height;
        final maxDialogHeight = screenHeight * 0.6; // Máximo 60% da tela

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Iconsax.user_remove, color: AppColors.error),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxDialogHeight,
              minWidth: 280,
            ),
            child: SingleChildScrollView(
              child: Text(content),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Não'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Bloquear'),
            ),
          ],
        );
      },
    );

    if (shouldBlock != true) return;

    try {
      final firestore = FirebaseFirestore.instance;

      // Add to profiles/{profileId}.blockedProfileIds
      await BlockedProfiles.add(
        firestore: firestore,
        blockerProfileId: blockerProfile.profileId,
        blockedProfileId: ownerProfileId,
      );

      // Edge compartilhável para o bloqueado descobrir que foi bloqueado (reverse visibility).
      try {
        await BlockedRelations.create(
          firestore: firestore,
          blockedByProfileId: blockerProfile.profileId,
          blockedProfileId: ownerProfileId,
          blockedByUid: currentUser.uid,
          blockedUid: resolved.uid,
        );
      } catch (e) {
        debugPrint('⚠️ blocks edge write failed (non-critical): $e');
      }

      if (!parentContext.mounted) return;
      AppSnackBar.showSuccess(parentContext, 'Perfil bloqueado');
    } catch (_) {
      if (!parentContext.mounted) return;
      AppSnackBar.showError(parentContext, 'Não foi possível bloquear. Tente novamente.');
    }
  }

  Future<_ResolvedOwnerInfo?> _resolveOwnerInfo({required String fallbackUid}) async {
    final trimmedFallbackUid = fallbackUid.trim();
    if (trimmedFallbackUid.isNotEmpty) {
      return _ResolvedOwnerInfo(
        uid: trimmedFallbackUid,
        profileId: _trimOrNull(widget.ownerProfileId),
        name: _trimOrNull(widget.ownerName),
        username: _trimOrNull(widget.ownerUsername),
        photoUrl: _trimOrNull(widget.ownerPhotoUrl),
        city: _trimOrNull(widget.ownerCity),
        neighborhood: _trimOrNull(widget.ownerNeighborhood),
        state: _trimOrNull(widget.ownerState),
        isBand: widget.ownerIsBand,
      );
    }

    try {
      final firestore = FirebaseFirestore.instance;

      if (widget.targetType == ReportTargetType.post) {
        final doc = await firestore.collection('posts').doc(widget.targetId).get();
        final data = doc.data();
        if (data == null) return null;

        final uid = (data['authorUid'] as String?)?.trim() ?? '';
        if (uid.isEmpty) return null;

        return _ResolvedOwnerInfo(
          uid: uid,
          profileId: _trimOrNull(data['authorProfileId'] as String?),
          name: _trimOrNull(data['authorName'] as String?),
          username: _trimOrNull(data['authorUsername'] as String?),
          photoUrl: _trimOrNull(data['authorPhotoUrl'] as String?),
          city: _trimOrNull(data['city'] as String?),
          neighborhood: _trimOrNull(data['neighborhood'] as String?),
          state: _trimOrNull(data['state'] as String?),
          isBand: data['isBand'] as bool?,
        );
      }

      // ReportTargetType.profile
      // Para evitar vazar dados de um perfil potencialmente excluído (bloqueado/bloqueou),
      // só mostramos o prompt de bloqueio quando o caller já forneceu `ownerUid`.
      return null;
    } catch (e) {
      debugPrint('⚠️ Resolve owner info failed (non-critical): $e');
      return null;
    }
  }

  static String? _trimOrNull(String? value) {
    final v = (value ?? '').trim();
    return v.isEmpty ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportNotifierProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Iconsax.flag, color: Colors.orange.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Denunciar $_targetTypeLabel',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (widget.targetName != null)
                          Text(
                            widget.targetName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.close_circle, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: 16 + bottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instrução
                    Text(
                      'Por que você está denunciando este $_targetTypeLabel?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sua denúncia é anônima. O dono do conteúdo não saberá quem reportou.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lista de motivos
                    ..._reasons.map((reason) => _buildReasonTile(reason)),

                    const SizedBox(height: 20),

                    // Campo de descrição opcional
                    Text(
                      'Descreva o problema (opcional)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLength: _maxDescriptionLength,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Explique por que isso viola as regras...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        counterStyle: TextStyle(color: Colors.grey.shade500),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 24),

                    // Botões de ação
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: reportState.isSubmitting 
                                ? null 
                                : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: reportState.isSubmitting || _selectedReason == null
                                ? null
                                : _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: reportState.isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Enviar Denúncia',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonTile(String reason) {
    final isSelected = _selectedReason == reason;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _selectedReason = reason),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Radio visual
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
