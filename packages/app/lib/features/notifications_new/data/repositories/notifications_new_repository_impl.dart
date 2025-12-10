/// WeGig - NotificationsNew Repository Implementation
///
/// Implementação do repositório de notificações seguindo Clean Architecture.
/// Faz a ponte entre a camada de domínio e a camada de dados (Firestore).
library;

import 'package:flutter/foundation.dart';
import 'package:wegig_app/features/notifications_new/data/datasources/notifications_new_remote_datasource.dart';
import 'package:wegig_app/features/notifications_new/domain/entities/notification_new_entity.dart';
import 'package:wegig_app/features/notifications_new/domain/repositories/notifications_new_repository.dart';

/// Implementação do repositório de notificações
///
/// Responsável por:
/// - Delegar operações para o DataSource
/// - Logging de operações para debug
/// - Tratamento de erros consistente
class NotificationsNewRepositoryImpl implements NotificationsNewRepository {
  /// Cria o repositório com o datasource injetado
  NotificationsNewRepositoryImpl({
    required INotificationsNewRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final INotificationsNewRemoteDataSource _remoteDataSource;

  @override
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    required String recipientUid,
    NotificationType? type,
    int limit = 20,
    NotificationEntity? startAfter,
  }) async {
    try {
      debugPrint('📋 NotificationsNewRepository: getNotifications');
      return await _remoteDataSource.getNotifications(
        profileId: profileId,
        recipientUid: recipientUid,
        type: type,
        limit: limit,
        startAfter: startAfter,
      );
    } catch (e) {
      debugPrint('❌ NotificationsNewRepository: Erro em getNotifications - $e');
      rethrow;
    }
  }

  @override
  Future<NotificationEntity?> getNotificationById({
    required String notificationId,
    required String profileId,
  }) async {
    try {
      debugPrint('📋 NotificationsNewRepository: getNotificationById');
      return await _remoteDataSource.getNotificationById(notificationId);
    } catch (e) {
      debugPrint(
          '❌ NotificationsNewRepository: Erro em getNotificationById - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead({
    required String notificationId,
    required String profileId,
  }) async {
    try {
      debugPrint('📋 NotificationsNewRepository: markAsRead');
      await _remoteDataSource.markAsRead(notificationId);
    } catch (e) {
      debugPrint('❌ NotificationsNewRepository: Erro em markAsRead - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead({
    required String profileId,
    required String recipientUid,
  }) async {
    try {
      debugPrint('📋 NotificationsNewRepository: markAllAsRead');
      await _remoteDataSource.markAllAsRead(profileId, recipientUid);
    } catch (e) {
      debugPrint('❌ NotificationsNewRepository: Erro em markAllAsRead - $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification({
    required String notificationId,
    required String profileId,
  }) async {
    try {
      debugPrint('📋 NotificationsNewRepository: deleteNotification');
      await _remoteDataSource.deleteNotification(notificationId);
    } catch (e) {
      debugPrint(
          '❌ NotificationsNewRepository: Erro em deleteNotification - $e');
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount({
    required String profileId,
    required String recipientUid,
  }) async {
    try {
      debugPrint('📋 NotificationsNewRepository: getUnreadCount');
      return await _remoteDataSource.getUnreadCount(profileId, recipientUid);
    } catch (e) {
      debugPrint('❌ NotificationsNewRepository: Erro em getUnreadCount - $e');
      return 0;
    }
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications({
    required String profileId,
    required String recipientUid,
    int limit = 50,
  }) {
    debugPrint('📋 NotificationsNewRepository: watchNotifications');
    return _remoteDataSource.watchNotifications(
      profileId: profileId,
      recipientUid: recipientUid,
      limit: limit,
    );
  }

  @override
  Stream<int> watchUnreadCount({
    required String profileId,
    required String recipientUid,
  }) {
    debugPrint('📋 NotificationsNewRepository: watchUnreadCount');
    return _remoteDataSource.watchUnreadCount(
      profileId: profileId,
      recipientUid: recipientUid,
    );
  }
}
