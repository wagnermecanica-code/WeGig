import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:wegig_app/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:wegig_app/features/notifications/domain/repositories/notifications_repository.dart';

/// Implementação do NotificationsRepository
class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(
      {required INotificationsRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;
  final INotificationsRemoteDataSource _remoteDataSource;

  @override
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    String? recipientUid,
    NotificationType? type,
    int limit = 50,
    NotificationEntity? startAfter,
  }) async {
    try {
      debugPrint('📝 NotificationsRepository: getNotifications');
      return await _remoteDataSource.getNotifications(
        profileId: profileId,
        recipientUid: recipientUid,
        type: type,
        limit: limit,
        startAfter: startAfter,
      );
    } catch (e) {
      debugPrint('❌ NotificationsRepository: Erro em getNotifications - $e');
      rethrow;
    }
  }

  @override
  Future<NotificationEntity?> getNotificationById(String notificationId) async {
    try {
      debugPrint('📝 NotificationsRepository: getNotificationById');
      return await _remoteDataSource.getNotificationById(notificationId);
    } catch (e) {
      debugPrint('❌ NotificationsRepository: Erro em getNotificationById - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead({
    required String notificationId,
    required String profileId,
  }) async {
    try {
      debugPrint('📝 NotificationsRepository: markAsRead');
      await _remoteDataSource.markAsRead(notificationId, profileId);
    } catch (e) {
      debugPrint('❌ NotificationsRepository: Erro em markAsRead - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead({
    required String profileId,
    String? recipientUid,
  }) async {
    try {
      debugPrint('📝 NotificationsRepository: markAllAsRead');
      await _remoteDataSource.markAllAsRead(profileId, recipientUid: recipientUid);
    } catch (e) {
      debugPrint('❌ NotificationsRepository: Erro em markAllAsRead - $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification({
    required String notificationId,
    required String profileId,
  }) async {
    try {
      debugPrint('📝 NotificationsRepository: deleteNotification');
      await _remoteDataSource.deleteNotification(notificationId, profileId);
    } catch (e) {
      debugPrint('❌ NotificationsRepository: Erro em deleteNotification - $e');
      rethrow;
    }
  }

  @override
  Future<NotificationEntity> createNotification(
      NotificationEntity notification) async {
    try {
      debugPrint('📝 NotificationsRepository: createNotification');

      // Validação antes de criar
      NotificationEntity.validate(
        recipientUid: notification.recipientUid,
        recipientProfileId: notification.recipientProfileId,
        title: notification.title,
        message: notification.message,
      );

      return await _remoteDataSource.createNotification(notification);
    } catch (e) {
      debugPrint('❌ NotificationsRepository: Erro em createNotification - $e');
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount({
    required String profileId,
    String? recipientUid,
  }) async {
    try {
      debugPrint('📝 NotificationsRepository: getUnreadCount');
      return await _remoteDataSource.getUnreadCount(profileId, recipientUid: recipientUid);
    } catch (e) {
      debugPrint('❌ NotificationsRepository: Erro em getUnreadCount - $e');
      return 0;
    }
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications({
    required String profileId,
    String? recipientUid,
    int limit = 50,
  }) {
    debugPrint('📝 NotificationsRepository: watchNotifications (stream)');
    return _remoteDataSource.watchNotifications(profileId, limit, recipientUid: recipientUid);
  }

  @override
  Stream<int> watchUnreadCount({
    required String profileId,
    String? recipientUid,
  }) {
    debugPrint('📝 NotificationsRepository: watchUnreadCount (stream)');
    return _remoteDataSource.watchUnreadCount(profileId, recipientUid: recipientUid);
  }
}
