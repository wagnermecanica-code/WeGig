import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:wegig_app/features/notifications/domain/repositories/notifications_repository.dart';

class LoadNotifications {
  LoadNotifications(this._repository);
  final NotificationsRepository _repository;

  Future<List<NotificationEntity>> call({
    required String profileId,
    int limit = 50,
    NotificationEntity? startAfter,
  }) async {
    return _repository.getNotifications(
      profileId: profileId,
      limit: limit,
      startAfter: startAfter,
    );
  }
}
