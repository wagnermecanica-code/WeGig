import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:flutter/foundation.dart';

/// Interface para NotificationsRemoteDataSource
abstract class INotificationsRemoteDataSource {
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    String? recipientUid,
    NotificationType? type,
    int limit = 50,
    NotificationEntity? startAfter,
  });
  Future<NotificationEntity?> getNotificationById(String notificationId);
  Future<void> markAsRead(String notificationId, String profileId);
  Future<void> markAllAsRead(String profileId, {String? recipientUid});
  Future<void> deleteNotification(String notificationId, String profileId);
  Future<NotificationEntity> createNotification(
      NotificationEntity notification);
  Future<int> getUnreadCount(String profileId, {String? recipientUid});
  Stream<List<NotificationEntity>> watchNotifications(
      String profileId, int limit, {String? recipientUid});
  Stream<int> watchUnreadCount(String profileId, {String? recipientUid});
}

/// DataSource para Notifications - Firebase Firestore operations
class NotificationsRemoteDataSource implements INotificationsRemoteDataSource {
  NotificationsRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    String? recipientUid,
    NotificationType? type,
    int limit = 50,
    NotificationEntity? startAfter,
  }) async {
    try {
      debugPrint(
          '📝 NotificationsDataSource: getNotifications for profile $profileId (uid: $recipientUid, type: $type)');

      // ✅ FIX: Query por recipientUid (UID) para match com Security Rules
      // Depois filtramos por recipientProfileId no client-side
      if (recipientUid == null || recipientUid.isEmpty) {
        debugPrint('⚠️ NotificationsDataSource: recipientUid vazio');
        return [];
      }

      var query = _firestore
          .collection('notifications')
          .where('recipientUid', isEqualTo: recipientUid)
          .where('expiresAt', isGreaterThan: Timestamp.now());

      // Adicionar filtro de tipo se fornecido
      if (type != null) {
        // Nota: Isso requer índice composto (recipientUid + expiresAt + type)
        // Se der erro de índice, remover e filtrar no client-side
        query = query.where('type', isEqualTo: type.name);
      }

      query = query
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .limit(limit * 2); // Aumentar limite para filtro client-side

      if (startAfter != null) {
        // Optimization: Use startAfter values instead of fetching the document
        // Order is: expiresAt (asc), createdAt (desc)
        if (startAfter.expiresAt != null) {
          query = query.startAfter([startAfter.expiresAt, startAfter.createdAt]);
        } else {
          // Fallback: Fetch document if expiresAt is missing (should not happen given the query)
          final doc = await _firestore
              .collection('notifications')
              .doc(startAfter.notificationId)
              .get();
          if (doc.exists) {
            query = query.startAfterDocument(doc);
          }
        }
      }

      final snapshot = await query.get();
      debugPrint(
          '📝 NotificationsDataSource: Encontradas ${snapshot.docs.length} notificações (pré-filtro)');

      // Filtro client-side por profileId para isolamento multi-perfil
      var notifications = snapshot.docs
          .map(NotificationEntity.fromFirestore)
          .where((n) => n.recipientProfileId == profileId);
      
      // Fallback: Filtro client-side por tipo se não filtrado na query (opcional)
      // Mas como adicionamos na query, deve vir filtrado.
      
      final result = notifications.take(limit).toList();
      
      debugPrint(
          '📝 NotificationsDataSource: Após filtro: ${result.length} notificações');

      return result;
    } catch (e) {
      debugPrint('❌ NotificationsDataSource: Erro em getNotifications - $e');
      rethrow;
    }
  }

  @override
  Future<NotificationEntity?> getNotificationById(String notificationId) async {
    try {
      debugPrint(
          '📝 NotificationsDataSource: getNotificationById $notificationId');

      final doc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (!doc.exists) {
        debugPrint(
            '⚠️ NotificationsDataSource: Notificação $notificationId não encontrada');
        return null;
      }

      return NotificationEntity.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ NotificationsDataSource: Erro em getNotificationById - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId, String profileId) async {
    try {
      debugPrint('📝 NotificationsDataSource: markAsRead $notificationId');

      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ NotificationsDataSource: Notificação marcada como lida');
    } catch (e) {
      debugPrint('❌ NotificationsDataSource: Erro em markAsRead - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead(String profileId, {String? recipientUid}) async {
    try {
      debugPrint(
          '📝 NotificationsDataSource: markAllAsRead for profile $profileId (uid: $recipientUid)');

      // ✅ FIX: Query por recipientUid para match com Security Rules
      if (recipientUid == null || recipientUid.isEmpty) {
        debugPrint('⚠️ NotificationsDataSource: recipientUid vazio');
        return;
      }

      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientUid', isEqualTo: recipientUid)
          .where('read', isEqualTo: false)
          .get();

      // Filtro client-side por profileId
      final docsToUpdate = snapshot.docs
          .where((doc) => doc.data()['recipientProfileId'] == profileId)
          .toList();

      debugPrint(
          '📝 NotificationsDataSource: Marcando ${docsToUpdate.length} notificações como lidas');

      if (docsToUpdate.isEmpty) return;

      // Chunking logic to avoid batch limit (500 ops)
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
            '✅ NotificationsDataSource: Batch ${i ~/ batchSize + 1} commitado (${chunk.length} docs)');
      }

      debugPrint(
          '✅ NotificationsDataSource: Todas notificações marcadas como lidas');
    } catch (e) {
      debugPrint('❌ NotificationsDataSource: Erro em markAllAsRead - $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(
      String notificationId, String profileId) async {
    try {
      debugPrint(
          '📝 NotificationsDataSource: deleteNotification $notificationId');

      await _firestore.collection('notifications').doc(notificationId).delete();

      debugPrint('✅ NotificationsDataSource: Notificação deletada');
    } catch (e) {
      debugPrint('❌ NotificationsDataSource: Erro em deleteNotification - $e');
      rethrow;
    }
  }

  @override
  Future<NotificationEntity> createNotification(
      NotificationEntity notification) async {
    try {
      debugPrint(
          '📝 NotificationsDataSource: createNotification type=${notification.type.name}');

      NotificationEntity.validate(
        recipientUid: notification.recipientUid,
        recipientProfileId: notification.recipientProfileId,
        title: notification.title,
        message: notification.message,
      );

      final docRef = await _firestore
          .collection('notifications')
          .add(notification.toFirestore());

      debugPrint(
          '✅ NotificationsDataSource: Notificação criada com ID ${docRef.id}');

      return notification.copyWith(notificationId: docRef.id);
    } catch (e) {
      debugPrint('❌ NotificationsDataSource: Erro em createNotification - $e');
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount(String profileId, {String? recipientUid}) async {
    try {
      debugPrint(
          '📝 NotificationsDataSource: getUnreadCount for profile $profileId (uid: $recipientUid)');

      // ✅ FIX: Query por recipientUid para match com Security Rules
      if (recipientUid == null || recipientUid.isEmpty) {
        return 0;
      }

      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientUid', isEqualTo: recipientUid)
          .where('read', isEqualTo: false)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .get();

      // Filtro client-side por profileId
      final count = snapshot.docs
          .where((doc) => doc.data()['recipientProfileId'] == profileId)
          .length;
      debugPrint('📝 NotificationsDataSource: $count notificações não lidas');

      return count;
    } catch (e) {
      debugPrint('❌ NotificationsDataSource: Erro em getUnreadCount - $e');
      return 0;
    }
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications(
      String profileId, int limit, {String? recipientUid}) {
    debugPrint(
        '📝 NotificationsDataSource: watchNotifications (stream) para profile $profileId (uid: $recipientUid)');

    // ✅ FIX: Query por recipientUid (UID) para match com Security Rules
    if (recipientUid == null || recipientUid.isEmpty) {
      debugPrint('⚠️ NotificationsDataSource: recipientUid vazio, retornando stream vazio');
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('recipientUid', isEqualTo: recipientUid)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .limit(limit * 2)
        .snapshots()
        .map((snapshot) {
      debugPrint(
          '📝 NotificationsDataSource: Stream emitiu ${snapshot.docs.length} notificações (pré-filtro)');
      // Filtro client-side por profileId
      final notifications = snapshot.docs
          .map(NotificationEntity.fromFirestore)
          .where((n) => n.recipientProfileId == profileId)
          .take(limit)
          .toList();
      debugPrint(
          '📝 NotificationsDataSource: Após filtro: ${notifications.length} notificações');
      return notifications;
    });
  }

  @override
  Stream<int> watchUnreadCount(String profileId, {String? recipientUid}) {
    debugPrint(
        '📝 NotificationsDataSource: watchUnreadCount (stream) para profile $profileId (uid: $recipientUid)');

    // ✅ FIX: Query por recipientUid (UID) para match com Security Rules
    if (recipientUid == null || recipientUid.isEmpty) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('recipientUid', isEqualTo: recipientUid)
        .where('read', isEqualTo: false)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) {
      // Filtro client-side por profileId
      final count = snapshot.docs
          .map((doc) => doc.data())
          .where((data) => data['recipientProfileId'] == profileId)
          .length;
      debugPrint(
          '📝 NotificationsDataSource: Stream emitiu $count notificações não lidas');
      return count;
    });
  }
}
