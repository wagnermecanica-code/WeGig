import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

/// Serviço de notificações refatorado para Instagram-Style Architecture
///
/// CRÍTICO: Todas as notificações são isoladas por profileId
/// - Usa o profileProvider para determinar o perfil ativo
/// - Stream automático reage a mudanças de perfil
/// - Zero vazamento entre perfis
///
/// NOTA: Este serviço substitui completamente a feature `notifications` antiga.
/// Todas as notificações devem passar por aqui.
class NotificationService {
  NotificationService(this._ref);
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Badge counter cache (1 minute TTL)
  int? _cachedUnreadCount;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 1);

  ProfileState get _profileState => _ref.read(profileProvider).value!;

  /// Cria uma notificação para um profileId específico
  ///
  /// [recipientProfileId] - ID do perfil que receberá a notificação (CRÍTICO)
  /// [type] - Tipo da notificação (interest, newMessage, etc.)
  /// [title] - Título da notificação
  /// [body] - Corpo/mensagem da notificação
  /// [data] - Dados adicionais (ex: postId, conversationId)
  /// [senderProfileId] - ID do perfil que enviou (opcional)
  /// [senderUsername] - Username público do remetente para menções (sem @)
  Future<void> create({
    required String recipientProfileId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? senderProfileId,
    String? senderUsername,
  }) async {
    try {
      final now = DateTime.now();
      final normalizedUsername = _sanitizeUsername(senderUsername);

      // Calcular expiração baseada no tipo
      final expiresAt = _getExpirationDate(type, now);

      final notificationData = {
        'type': type,
        'recipientProfileId': recipientProfileId,
        'profileUid': recipientProfileId, // CRITICAL: Isolamento de perfil
        'senderProfileId': senderProfileId,
        'senderUsername': normalizedUsername,
        'title': title,
        'message': body,
        'body': body,
        'data': data,
        'read': false,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      };

      await _firestore.collection('notifications').add(notificationData);

      debugPrint(
          'NotificationService: Notificação criada - type: $type, recipient: $recipientProfileId');
    } catch (e) {
      debugPrint('NotificationService: Erro ao criar notificação: $e');
      rethrow;
    }
  }

  /// Marca uma notificação como lida
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      // Invalidar cache do badge counter
      invalidateUnreadCountCache();

      debugPrint(
          'NotificationService: Notificação marcada como lida: $notificationId');
    } catch (e) {
      debugPrint('NotificationService: Erro ao marcar como lida: $e');
      rethrow;
    }
  }

  /// Marca todas as notificações do perfil ativo como lidas
  Future<void> markAllAsRead() async {
    try {
      final activeProfile = _profileState.activeProfile;
      if (activeProfile == null) {
        debugPrint(
            'NotificationService: Nenhum perfil ativo para marcar como lidas');
        return;
      }

      // ✅ FIX: Query por recipientUid (UID) para match com Security Rules
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('recipientUid', isEqualTo: activeProfile.uid)
          .where('read', isEqualTo: false)
          .get();

      // Filtro client-side por profileId
      final docsToUpdate = notifications.docs
          .where((doc) => doc.data()['recipientProfileId'] == activeProfile.profileId)
          .toList();

      for (final doc in docsToUpdate) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Invalidar cache do badge counter
      invalidateUnreadCountCache();

      debugPrint(
          'NotificationService: ${notifications.docs.length} notificações marcadas como lidas');
    } catch (e) {
      debugPrint('NotificationService: Erro ao marcar todas como lidas: $e');
      rethrow;
    }
  }

  /// Deleta uma notificação
  Future<void> delete(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      debugPrint('NotificationService: Notificação deletada: $notificationId');
    } catch (e) {
      debugPrint('NotificationService: Erro ao deletar notificação: $e');
      rethrow;
    }
  }

  /// Força refresh manual (útil para pull-to-refresh)
  Future<void> refreshNotifications({
    required String recipientProfileId,
    NotificationType? type,
  }) async {
    // ✅ FIX: Query por recipientUid para match com Security Rules
    final activeProfile = _profileState.activeProfile;
    if (activeProfile == null) return;

    Query query = _firestore
        .collection('notifications')
        .where('recipientUid', isEqualTo: activeProfile.uid)
        .orderBy('createdAt', descending: true)
        .limit(1);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    await query.get();
  }

  /// Obtém notificações com paginação cursor-based
  Stream<List<NotificationEntity>> getNotifications(
    String currentProfileId, {
    NotificationType? type,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) {
    final activeProfile = _profileState.activeProfile;
    if (activeProfile == null || activeProfile.uid.isEmpty) {
      debugPrint('NotificationService: Nenhum perfil ativo, retornando stream vazio');
      return Stream.value([]);
    }

    debugPrint('NotificationService: Stream - Carregando notificações para ${activeProfile.name} ($currentProfileId)');

    Query query = _firestore
        .collection('notifications')
        .where('recipientUid', isEqualTo: activeProfile.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit * 2);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots()
        .handleError((error) {
          debugPrint('NotificationService: Erro na query (retornando vazio): $error');
          return <NotificationEntity>[];
        })
        .debounceTime(const Duration(milliseconds: 50))
        .map((snapshot) {
      final results = snapshot.docs
          .map((doc) {
            try {
              return NotificationEntity.fromFirestore(doc);
            } catch (e) {
              debugPrint('NotificationService: Erro ao parsear notificação ${doc.id}: $e');
              return null;
            }
          })
          .whereType<NotificationEntity>()
          .where((notif) {
            if (notif.recipientProfileId != currentProfileId) return false;
            if (notif.expiresAt != null && notif.expiresAt!.isBefore(DateTime.now())) return false;
            return true;
          })
          .take(limit)
          .toList();
      
      debugPrint('NotificationService: ${results.length} notificações carregadas');
      return results;
    });
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  /// Stream de notificações do perfil ativo
  Stream<List<NotificationEntity>> streamActiveProfileNotifications() {
    final activeProfile = _profileState.activeProfile;
    if (activeProfile == null) {
      debugPrint('NotificationService: Stream - Nenhum perfil ativo');
      return Stream.value(<NotificationEntity>[]);
    }

    debugPrint('NotificationService: Stream - Carregando notificações para ${activeProfile.name} (${activeProfile.profileId})');

    return _firestore
        .collection('notifications')
        .where('recipientUid', isEqualTo: activeProfile.uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .handleError((error) {
          debugPrint('NotificationService: Erro no stream (retornando vazio): $error');
          return <NotificationEntity>[];
        })
        .debounceTime(const Duration(milliseconds: 50))
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) {
            try {
              return NotificationEntity.fromFirestore(doc);
            } catch (e) {
              debugPrint('NotificationService: Erro ao parsear notificação ${doc.id}: $e');
              return null;
            }
          })
          .whereType<NotificationEntity>()
          .where((notif) {
            if (notif.recipientProfileId != activeProfile.profileId) return false;
            if (notif.expiresAt != null && notif.expiresAt!.isBefore(DateTime.now())) return false;
            return true;
          })
          .toList();

      debugPrint('NotificationService: ${notifications.length} notificações carregadas');
      return notifications;
    });
  }

  /// Stream de contador de notificações não lidas do perfil ativo
  Stream<int> streamUnreadCount() {
    final activeProfile = _profileState.activeProfile;
    if (activeProfile == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('recipientUid', isEqualTo: activeProfile.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .handleError((error) {
          debugPrint('📊 Badge Counter: Erro na query (retornando 0): $error');
          return 0;
        })
        .debounceTime(const Duration(milliseconds: 50))
        .map((snapshot) {
      final unreadCount = snapshot.docs.where((doc) {
        final recipientProfileId = doc.data()['recipientProfileId'] as String?;
        if (recipientProfileId != activeProfile.profileId) return false;
        final expiresAt = doc.data()['expiresAt'] as Timestamp?;
        if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) return false;
        return true;
      }).length;

      _cachedUnreadCount = unreadCount;
      _cacheTimestamp = DateTime.now();

      debugPrint('📊 Badge Counter: $unreadCount não lidas (cached para 1min)');
      return unreadCount;
    });
  }

  int? getCachedUnreadCount() {
    if (_cachedUnreadCount == null || _cacheTimestamp == null) return null;
    final elapsed = DateTime.now().difference(_cacheTimestamp!);
    if (elapsed > _cacheDuration) {
      debugPrint('📊 Badge Counter: Cache expirado (${elapsed.inSeconds}s)');
      return null;
    }
    debugPrint('📊 Badge Counter: Usando cache ($_cachedUnreadCount, ${elapsed.inSeconds}s atrás)');
    return _cachedUnreadCount;
  }

  void invalidateUnreadCountCache() {
    _cachedUnreadCount = null;
    _cacheTimestamp = null;
    debugPrint('📊 Badge Counter: Cache invalidado');
  }

  Future<void> cleanExpiredNotifications() async {
    try {
      final now = Timestamp.now();
      final expired = await _firestore
          .collection('notifications')
          .where('expiresAt', isLessThan: now)
          .get();

      if (expired.docs.isEmpty) {
        debugPrint('NotificationService: Nenhuma notificação expirada encontrada');
        return;
      }

      final batch = _firestore.batch();
      for (final doc in expired.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('NotificationService: ${expired.docs.length} notificações expiradas removidas');
    } catch (e) {
      debugPrint('NotificationService: Erro ao limpar notificações expiradas: $e');
      rethrow;
    }
  }

  /// Cria notificação de nova mensagem
  Future<void> createNewMessageNotification({
    required String conversationId,
    required String recipientProfileId,
    required String messagePreview,
  }) async {
    final activeProfile = _profileState.activeProfile;
    if (activeProfile == null) {
      debugPrint('NotificationService: Nenhum perfil ativo para enviar mensagem');
      return;
    }

    final existing = await _firestore
        .collection('notifications')
        .where('recipientProfileId', isEqualTo: recipientProfileId)
        .where('type', isEqualTo: 'newMessage')
        .where('data.conversationId', isEqualTo: conversationId)
        .where('read', isEqualTo: false)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({
        'body': '${activeProfile.name} enviou uma mensagem: $messagePreview',
        'data.messagePreview': messagePreview,
        'data.messageCount': FieldValue.increment(1),
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('NotificationService: Notificação de mensagem atualizada (agregação)');
      return;
    }

    await create(
      recipientProfileId: recipientProfileId,
      type: 'newMessage',
      title: 'Nova mensagem',
      body: '${activeProfile.name} enviou: $messagePreview',
      data: {
        'conversationId': conversationId,
        'messagePreview': messagePreview,
        'messageCount': 1,
        'senderName': activeProfile.name,
        'senderPhoto': activeProfile.photoUrl ?? '',
      },
      senderProfileId: activeProfile.profileId,
      senderUsername: activeProfile.username,
    );
  }

  String? _sanitizeUsername(String? username) {
    if (username == null) return null;
    final sanitized = username.replaceAll('@', '').trim();
    if (sanitized.isEmpty) return null;
    return sanitized;
  }

  DateTime? _getExpirationDate(String type, DateTime createdAt) {
    switch (type) {
      case 'interest':
      case 'interestResponse':
        return createdAt.add(const Duration(days: 30));
      case 'newMessage':
      case 'nearbyPost':
      case 'postExpiring':
      case 'postUpdated':
      case 'profileView':
        return createdAt.add(const Duration(days: 7));
      case 'profileMatch':
        return createdAt.add(const Duration(days: 14));
      case 'system':
        return createdAt.add(const Duration(days: 90));
      default:
        return createdAt.add(const Duration(days: 30));
    }
  }

  Future<void> testNotification() async {
    final activeProfile = _profileState.activeProfile;
    if (activeProfile == null) {
      debugPrint('NotificationService: Nenhum perfil ativo para teste');
      return;
    }

    await create(
      recipientProfileId: activeProfile.profileId,
      type: 'system',
      title: '🧪 Notificação de Teste',
      body: 'Sistema de notificações funcionando perfeitamente!',
      data: {
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    debugPrint('NotificationService: Notificação de teste enviada para ${activeProfile.name}');
  }
}
