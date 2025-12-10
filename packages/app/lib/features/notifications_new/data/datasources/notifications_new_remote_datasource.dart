/// WeGig - NotificationsNew Remote DataSource
///
/// DataSource para operações Firestore de notificações seguindo Clean Architecture.
/// Implementa queries otimizadas com paginação cursor-based e filtros multi-perfil.
///
/// CRÍTICO: Todas as queries usam recipientUid para match com Security Rules Firestore.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:wegig_app/features/notifications_new/domain/entities/notification_new_entity.dart';

/// Interface do DataSource de notificações
///
/// Define contrato para operações Firestore isolando a implementação.
abstract class INotificationsNewRemoteDataSource {
  /// Busca notificações paginadas
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    required String recipientUid,
    NotificationType? type,
    int limit = 20,
    NotificationEntity? startAfter,
  });

  /// Busca notificação por ID
  Future<NotificationEntity?> getNotificationById(String notificationId);

  /// Marca como lida
  Future<void> markAsRead(String notificationId);

  /// Marca todas como lidas
  Future<void> markAllAsRead(String profileId, String recipientUid);

  /// Deleta notificação
  Future<void> deleteNotification(String notificationId);

  /// Conta não lidas
  Future<int> getUnreadCount(String profileId, String recipientUid);

  /// Stream de notificações
  Stream<List<NotificationEntity>> watchNotifications({
    required String profileId,
    required String recipientUid,
    int limit = 50,
  });

  /// Stream de contador de não lidas
  Stream<int> watchUnreadCount({
    required String profileId,
    required String recipientUid,
  });
}

/// Implementação do DataSource de notificações usando Firestore
///
/// Otimizações:
/// - Paginação cursor-based com startAfter (mais eficiente que offset)
/// - Filtro client-side por profileId (isolamento multi-perfil)
/// - Batch writes para operações em massa (markAllAsRead)
/// - Streams com distinct para evitar rebuilds desnecessários
class NotificationsNewRemoteDataSource
    implements INotificationsNewRemoteDataSource {
  /// Cria o datasource, opcionalmente com instância Firestore customizada (testes)
  NotificationsNewRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Referência à collection de notificações
  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('notifications');

  @override
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    required String recipientUid,
    NotificationType? type,
    int limit = 20,
    NotificationEntity? startAfter,
  }) async {
    try {
      debugPrint(
          '📝 NotificationsNewDataSource: getNotifications for profile=$profileId, uid=$recipientUid, type=${type?.name ?? 'all'}');

      // Validação de parâmetros obrigatórios
      if (recipientUid.isEmpty) {
        debugPrint('⚠️ NotificationsNewDataSource: recipientUid vazio');
        return [];
      }

      // Query base: recipientUid (CRÍTICO para Security Rules)
      // IMPORTANTE: Ordem dos filtros deve seguir índices em firestore.indexes.json
      var query = _notificationsRef
          .where('recipientUid', isEqualTo: recipientUid);

      // Filtro opcional por tipo de notificação
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      // Ordenação: createdAt DESC (mais recentes primeiro)
      // Usa índice: recipientUid + type + createdAt OU recipientUid + createdAt
      query = query
          .orderBy('createdAt', descending: true)
          .limit(limit * 3); // Margem maior para filtros client-side

      // Paginação cursor-based
      if (startAfter != null) {
        query = query.startAfter([
          Timestamp.fromDate(startAfter.createdAt),
        ]);
      }

      final snapshot = await query.get();
      debugPrint(
          '📝 NotificationsNewDataSource: ${snapshot.docs.length} docs retornados do Firestore');

      // Log dos documentos para debug
      for (final doc in snapshot.docs) {
        final data = doc.data();
        debugPrint(
            '📋 Doc ${doc.id}: recipientProfileId=${data['recipientProfileId']}, type=${data['type']}, title=${data['title']}');
      }

      final now = DateTime.now();
      
      // Filtros client-side:
      // 1. Por profileId (isolamento multi-perfil)
      // 2. Por expiração (remove notificações expiradas)
      final notifications = snapshot.docs
          .map(NotificationEntity.fromFirestore)
          .where((n) {
            // Filtro por profileId
            if (n.recipientProfileId != profileId) {
              debugPrint(
                  '🚫 Filtrado por profileId: doc.recipientProfileId=${n.recipientProfileId} != profileId=$profileId');
              return false;
            }
            
            // Filtro por expiração
            if (n.expiresAt != null && n.expiresAt!.isBefore(now)) {
              debugPrint(
                  '🚫 Filtrado por expiração: expiresAt=${n.expiresAt} < now=$now');
              return false;
            }
            
            return true;
          })
          .take(limit)
          .toList();

      debugPrint(
          '✅ NotificationsNewDataSource: ${notifications.length} notificações após filtro');

      return notifications;
    } catch (e, stack) {
      debugPrint('❌ NotificationsNewDataSource: Erro em getNotifications - $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<NotificationEntity?> getNotificationById(
      String notificationId) async {
    try {
      debugPrint(
          '📝 NotificationsNewDataSource: getNotificationById $notificationId');

      final doc = await _notificationsRef.doc(notificationId).get();

      if (!doc.exists) {
        debugPrint('⚠️ NotificationsNewDataSource: Notificação não encontrada');
        return null;
      }

      return NotificationEntity.fromFirestore(doc);
    } catch (e) {
      debugPrint(
          '❌ NotificationsNewDataSource: Erro em getNotificationById - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      debugPrint('📝 NotificationsNewDataSource: markAsRead $notificationId');

      await _notificationsRef.doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ NotificationsNewDataSource: Marcada como lida');
    } catch (e) {
      debugPrint('❌ NotificationsNewDataSource: Erro em markAsRead - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead(String profileId, String recipientUid) async {
    try {
      debugPrint(
          '📝 NotificationsNewDataSource: markAllAsRead for profile $profileId');

      if (recipientUid.isEmpty) {
        debugPrint('⚠️ NotificationsNewDataSource: recipientUid vazio');
        return;
      }

      // Busca todas não lidas do usuário
      final snapshot = await _notificationsRef
          .where('recipientUid', isEqualTo: recipientUid)
          .where('read', isEqualTo: false)
          .get();

      // Filtro client-side por profileId
      final docsToUpdate = snapshot.docs
          .where((doc) => doc.data()['recipientProfileId'] == profileId)
          .toList();

      debugPrint(
          '📝 NotificationsNewDataSource: ${docsToUpdate.length} para marcar');

      if (docsToUpdate.isEmpty) return;

      // Batch write (limite 500 por batch)
      const int batchSize = 500;
      for (var i = 0; i < docsToUpdate.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < docsToUpdate.length)
            ? i + batchSize
            : docsToUpdate.length;
        final chunk = docsToUpdate.sublist(i, end);

        for (final doc in chunk) {
          batch.update(doc.reference, {
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
        debugPrint(
            '✅ NotificationsNewDataSource: Batch ${i ~/ batchSize + 1} commitado');
      }

      debugPrint('✅ NotificationsNewDataSource: Todas marcadas como lidas');
    } catch (e) {
      debugPrint('❌ NotificationsNewDataSource: Erro em markAllAsRead - $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      debugPrint(
          '📝 NotificationsNewDataSource: deleteNotification $notificationId');

      await _notificationsRef.doc(notificationId).delete();

      debugPrint('✅ NotificationsNewDataSource: Notificação deletada');
    } catch (e) {
      debugPrint(
          '❌ NotificationsNewDataSource: Erro em deleteNotification - $e');
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount(String profileId, String recipientUid) async {
    try {
      debugPrint(
          '📝 NotificationsNewDataSource: getUnreadCount for profile $profileId');

      if (recipientUid.isEmpty) return 0;

      final snapshot = await _notificationsRef
          .where('recipientUid', isEqualTo: recipientUid)
          .where('read', isEqualTo: false)
          .get();

      // Filtro client-side por profileId
      final count = snapshot.docs
          .where((doc) => doc.data()['recipientProfileId'] == profileId)
          .length;

      debugPrint('✅ NotificationsNewDataSource: $count não lidas');
      return count;
    } catch (e) {
      debugPrint('❌ NotificationsNewDataSource: Erro em getUnreadCount - $e');
      return 0;
    }
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications({
    required String profileId,
    required String recipientUid,
    int limit = 50,
  }) {
    debugPrint(
        '📝 NotificationsNewDataSource: watchNotifications for profile=$profileId, uid=$recipientUid');

    if (recipientUid.isEmpty) {
      debugPrint('⚠️ NotificationsNewDataSource: recipientUid vazio no stream');
      return Stream.value([]);
    }

    return _notificationsRef
        .where('recipientUid', isEqualTo: recipientUid)
        .orderBy('createdAt', descending: true)
        .limit(limit * 2)
        .snapshots()
        .map((snapshot) {
      debugPrint(
          '📡 Stream: ${snapshot.docs.length} docs do Firestore');
      
      final now = DateTime.now();
      
      // Filtros client-side: profileId + expiração
      final notifications = snapshot.docs
          .map(NotificationEntity.fromFirestore)
          .where((n) {
            // Filtro por profileId
            if (n.recipientProfileId != profileId) {
              debugPrint(
                  '🚫 Stream filtrado: doc.recipientProfileId=${n.recipientProfileId} != profileId=$profileId');
              return false;
            }
            
            // Filtro por expiração
            if (n.expiresAt != null && n.expiresAt!.isBefore(now)) {
              return false;
            }
            
            return true;
          })
          .take(limit)
          .toList();

      debugPrint(
          '📡 Stream emitiu ${notifications.length} notificações após filtro');
      return notifications;
    });
  }

  @override
  Stream<int> watchUnreadCount({
    required String profileId,
    required String recipientUid,
  }) {
    debugPrint(
        '📝 NotificationsNewDataSource: watchUnreadCount for profile $profileId');

    if (recipientUid.isEmpty) {
      return Stream.value(0);
    }

    return _notificationsRef
        .where('recipientUid', isEqualTo: recipientUid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final count = snapshot.docs
          .where((doc) => doc.data()['recipientProfileId'] == profileId)
          .length;

      debugPrint('📝 NotificationsNewDataSource: Stream unread count = $count');
      return count;
    }).distinct(); // Evita emissões duplicadas
  }
}
