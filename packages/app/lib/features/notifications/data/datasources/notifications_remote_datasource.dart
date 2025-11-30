import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:flutter/foundation.dart';

/// Interface para NotificationsRemoteDataSource
abstract class INotificationsRemoteDataSource {
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    int limit = 50,
    NotificationEntity? startAfter,
  });
  Future<NotificationEntity?> getNotificationById(String notificationId);
  Future<void> markAsRead(String notificationId, String profileId);
  Future<void> markAllAsRead(String profileId);
  Future<void> deleteNotification(String notificationId, String profileId);
  Future<NotificationEntity> createNotification(
      NotificationEntity notification);
  Future<int> getUnreadCount(String profileId);
  Stream<List<NotificationEntity>> watchNotifications(
      String profileId, int limit);
  Stream<int> watchUnreadCount(String profileId);
}

/// DataSource para Notifications - Firebase Firestore operations
class NotificationsRemoteDataSource implements INotificationsRemoteDataSource {
  NotificationsRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    int limit = 50,
    NotificationEntity? startAfter,
  }) async {
    try {
      debugPrint(
          '📝 NotificationsDataSource: getNotifications for profile $profileId');

      var query = _firestore
          .collection('notifications')
          .where('recipientProfileId', isEqualTo: profileId)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        final doc = await _firestore
            .collection('notifications')
            .doc(startAfter.notificationId)
            .get();
        if (doc.exists) {
          query = query.startAfterDocument(doc);
        }
      }

      final snapshot = await query.get();
      debugPrint(
          '📝 NotificationsDataSource: Encontradas ${snapshot.docs.length} notificações');

      return snapshot.docs.map(NotificationEntity.fromFirestore).toList();
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
  Future<void> markAllAsRead(String profileId) async {
    try {
      debugPrint(
          '📝 NotificationsDataSource: markAllAsRead for profile $profileId');

      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientProfileId', isEqualTo: profileId)
          .where('read', isEqualTo: false)
          .get();

      debugPrint(
          '📝 NotificationsDataSource: Marcando ${snapshot.docs.length} notificações como lidas');

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
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
  Future<int> getUnreadCount(String profileId) async {
    try {
      debugPrint(
          '📝 NotificationsDataSource: getUnreadCount for profile $profileId');

      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientProfileId', isEqualTo: profileId)
          .where('read', isEqualTo: false)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .get();

      final count = snapshot.docs.length;
      debugPrint('📝 NotificationsDataSource: $count notificações não lidas');

      return count;
    } catch (e) {
      debugPrint('❌ NotificationsDataSource: Erro em getUnreadCount - $e');
      return 0;
    }
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications(
      String profileId, int limit) {
    debugPrint(
        '📝 NotificationsDataSource: watchNotifications (stream) para profile $profileId');

    return _firestore
        .collection('notifications')
        .where('recipientProfileId', isEqualTo: profileId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      debugPrint(
          '📝 NotificationsDataSource: Stream emitiu ${snapshot.docs.length} notificações');
      return snapshot.docs.map(NotificationEntity.fromFirestore).toList();
    });
  }

  @override
  Stream<int> watchUnreadCount(String profileId) {
    debugPrint(
        '📝 NotificationsDataSource: watchUnreadCount (stream) para profile $profileId');

    return _firestore
        .collection('notifications')
        .where('recipientProfileId', isEqualTo: profileId)
        .where('read', isEqualTo: false)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) {
      final count = snapshot.docs.length;
      debugPrint(
          '📝 NotificationsDataSource: Stream emitiu $count notificações não lidas');
      return count;
    });
  }
}
