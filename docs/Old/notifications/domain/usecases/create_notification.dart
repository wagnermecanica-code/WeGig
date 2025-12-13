import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:wegig_app/features/notifications/domain/repositories/notifications_repository.dart';

class CreateNotification {
  CreateNotification(this._repository);
  final NotificationsRepository _repository;

  Future<NotificationEntity> call(NotificationEntity notification) async {
    // Validação
    NotificationEntity.validate(
      recipientUid: notification.recipientUid,
      recipientProfileId: notification.recipientProfileId,
      title: notification.title,
      message: notification.message,
    );

    return _repository.createNotification(notification);
  }
}
