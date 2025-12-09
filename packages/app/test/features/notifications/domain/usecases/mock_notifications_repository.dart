import 'dart:async';

import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:wegig_app/features/notifications/domain/repositories/notifications_repository.dart';

/// Mock implementation of NotificationsRepository for testing
class MockNotificationsRepository implements NotificationsRepository {
  // Test data storage
  final Map<String, NotificationEntity> _notifications = {};
  final Map<String, int> _unreadCounts = {};

  // Setup responses
  String? _createNotificationFailure;
  String? _markAsReadFailure;
  String? _markAllAsReadFailure;
  String? _deleteNotificationFailure;
  String? _getNotificationsFailure;

  // Call tracking
  bool createNotificationCalled = false;
  bool markAsReadCalled = false;
  bool markAllAsReadCalled = false;
  bool deleteNotificationCalled = false;
  bool getNotificationsCalled = false;

  String? lastCreatedNotificationId;
  String? lastMarkedAsReadNotificationId;
  String? lastDeletedNotificationId;
  String? lastMarkAllAsReadProfileId;

  // Setup methods
  void setupNotifications(
      String profileId, List<NotificationEntity> notifications) {
    for (final notification in notifications) {
      _notifications[notification.notificationId] = notification;
    }

    // Calculate unread count
    final unread = notifications.where((n) => !n.read).length;
    _unreadCounts[profileId] = unread;
  }

  void setupNotificationById(
      String notificationId, NotificationEntity? notification) {
    if (notification != null) {
      _notifications[notificationId] = notification;
    }
  }

  void setupUnreadCount(String profileId, int count) {
    _unreadCounts[profileId] = count;
  }

  void setupCreateNotificationFailure(String errorMessage) {
    _createNotificationFailure = errorMessage;
  }

  void setupMarkAsReadFailure(String errorMessage) {
    _markAsReadFailure = errorMessage;
  }

  void setupMarkAllAsReadFailure(String errorMessage) {
    _markAllAsReadFailure = errorMessage;
  }

  void setupDeleteNotificationFailure(String errorMessage) {
    _deleteNotificationFailure = errorMessage;
  }

  void setupGetNotificationsFailure(String errorMessage) {
    _getNotificationsFailure = errorMessage;
  }

  @override
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    int limit = 50,
    NotificationEntity? startAfter,
    String? recipientUid,
    NotificationType? type,
  }) async {
    getNotificationsCalled = true;

    if (_getNotificationsFailure != null) {
      throw Exception(_getNotificationsFailure);
    }

    return _notifications.values
        .where((n) => n.recipientProfileId == profileId)
        .where((n) => type == null || n.type == type)
        .toList();
  }

  @override
  Future<NotificationEntity?> getNotificationById(String notificationId) async {
    return _notifications[notificationId];
  }

  @override
  Future<void> markAsRead({
    required String notificationId,
    required String profileId,
  }) async {
    markAsReadCalled = true;
    lastMarkedAsReadNotificationId = notificationId;

    if (_markAsReadFailure != null) {
      throw Exception(_markAsReadFailure);
    }

    final notification = _notifications[notificationId];
    if (notification != null) {
      _notifications[notificationId] = NotificationEntity(
        notificationId: notification.notificationId,
        type: notification.type,
        recipientUid: notification.recipientUid,
        recipientProfileId: notification.recipientProfileId,
        title: notification.title,
        message: notification.message,
        read: true,
        createdAt: notification.createdAt,
        priority: notification.priority,
        actionType: notification.actionType,
        actionData: notification.actionData,
      );

      // Update unread count
      if (_unreadCounts[profileId] != null && _unreadCounts[profileId]! > 0) {
        _unreadCounts[profileId] = _unreadCounts[profileId]! - 1;
      }
    }
  }

  @override
  Future<void> markAllAsRead({
    required String profileId,
    String? recipientUid,
  }) async {
    markAllAsReadCalled = true;
    lastMarkAllAsReadProfileId = profileId;

    if (_markAllAsReadFailure != null) {
      throw Exception(_markAllAsReadFailure);
    }

    // Mark all notifications for this profile as read
    final profileNotifications = _notifications.values
        .where((n) => n.recipientProfileId == profileId)
        .toList();

    for (final notification in profileNotifications) {
      _notifications[notification.notificationId] = NotificationEntity(
        notificationId: notification.notificationId,
        type: notification.type,
        recipientUid: notification.recipientUid,
        recipientProfileId: notification.recipientProfileId,
        title: notification.title,
        message: notification.message,
        read: true,
        createdAt: notification.createdAt,
        priority: notification.priority,
        actionType: notification.actionType,
        actionData: notification.actionData,
      );
    }

    // Reset unread count
    _unreadCounts[profileId] = 0;
  }

  @override
  Future<void> deleteNotification({
    required String notificationId,
    required String profileId,
  }) async {
    deleteNotificationCalled = true;
    lastDeletedNotificationId = notificationId;

    if (_deleteNotificationFailure != null) {
      throw Exception(_deleteNotificationFailure);
    }

    _notifications.remove(notificationId);
  }

  @override
  Future<NotificationEntity> createNotification(
      NotificationEntity notification) async {
    createNotificationCalled = true;
    lastCreatedNotificationId = notification.notificationId;

    if (_createNotificationFailure != null) {
      throw Exception(_createNotificationFailure);
    }

    _notifications[notification.notificationId] = notification;

    // Update unread count if notification is unread
    if (!notification.read) {
      final currentCount = _unreadCounts[notification.recipientProfileId] ?? 0;
      _unreadCounts[notification.recipientProfileId] = currentCount + 1;
    }

    return notification;
  }

  @override
  Future<int> getUnreadCount({
    required String profileId,
    String? recipientUid,
  }) async {
    return _unreadCounts[profileId] ?? 0;
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications({
    required String profileId,
    int limit = 50,
    String? recipientUid,
  }) {
    return Stream.value(
      _notifications.values
          .where((n) => n.recipientProfileId == profileId)
          .toList(),
    );
  }

  @override
  Stream<int> watchUnreadCount({
    required String profileId,
    String? recipientUid,
  }) {
    return Stream.value(_unreadCounts[profileId] ?? 0);
  }
}
