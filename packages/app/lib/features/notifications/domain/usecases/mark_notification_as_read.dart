import 'package:wegig_app/features/notifications/domain/repositories/notifications_repository.dart';

class MarkNotificationAsRead {
  MarkNotificationAsRead(this._repository);
  final NotificationsRepository _repository;

  Future<void> call({
    required String notificationId,
    required String profileId,
  }) async {
    if (notificationId.isEmpty) {
      throw ArgumentError('ID da notificação é obrigatório');
    }
    if (profileId.isEmpty) {
      throw ArgumentError('ID do perfil é obrigatório');
    }

    await _repository.markAsRead(
      notificationId: notificationId,
      profileId: profileId,
    );
  }
}
