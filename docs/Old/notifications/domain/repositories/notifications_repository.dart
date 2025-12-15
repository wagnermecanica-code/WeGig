import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';

/// Interface do repositório de notificações
abstract class NotificationsRepository {
  /// Busca todas as notificações de um perfil
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    String? recipientUid,
    NotificationType? type,
    int limit = 50,
    NotificationEntity? startAfter,
  });

  /// Busca uma notificação por ID
  Future<NotificationEntity?> getNotificationById(String notificationId);

  /// Marca uma notificação como lida
  Future<void> markAsRead({
    required String notificationId,
    required String profileId,
  });

  /// Marca todas as notificações como lidas
  Future<void> markAllAsRead({
    required String profileId,
    String? recipientUid,
  });

  /// Deleta uma notificação
  Future<void> deleteNotification({
    required String notificationId,
    required String profileId,
  });

  /// Cria uma notificação
  Future<NotificationEntity> createNotification(
      NotificationEntity notification);

  /// Conta notificações não lidas
  Future<int> getUnreadCount({
    required String profileId,
    String? recipientUid,
  });

  /// Stream de notificações em tempo real
  Stream<List<NotificationEntity>> watchNotifications({
    required String profileId,
    String? recipientUid,
    int limit = 50,
  });

  /// Stream de contador de não lidas em tempo real
  Stream<int> watchUnreadCount({
    required String profileId,
    String? recipientUid,
  });
}
