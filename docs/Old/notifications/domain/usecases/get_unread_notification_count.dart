import 'package:wegig_app/features/notifications/domain/repositories/notifications_repository.dart';

class GetUnreadNotificationCount {
  GetUnreadNotificationCount(this._repository);
  final NotificationsRepository _repository;

  Future<int> call({
    required String profileId,
  }) async {
    return _repository.getUnreadCount(
      profileId: profileId,
    );
  }
}
