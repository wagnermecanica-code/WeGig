import 'package:wegig_app/features/notifications/domain/repositories/notifications_repository.dart';

class MarkAllNotificationsAsRead {
  MarkAllNotificationsAsRead(this._repository);
  final NotificationsRepository _repository;

  Future<void> call({
    required String profileId,
  }) async {
    await _repository.markAllAsRead(
      profileId: profileId,
    );
  }
}
