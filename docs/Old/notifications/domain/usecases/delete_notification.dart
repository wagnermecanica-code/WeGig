import 'package:wegig_app/features/notifications/domain/repositories/notifications_repository.dart';

class DeleteNotification {
  DeleteNotification(this._repository);
  final NotificationsRepository _repository;

  Future<void> call({
    required String notificationId,
    required String profileId,
  }) async {
    await _repository.deleteNotification(
      notificationId: notificationId,
      profileId: profileId,
    );
  }
}
