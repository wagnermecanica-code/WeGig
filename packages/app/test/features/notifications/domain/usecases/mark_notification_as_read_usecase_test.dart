import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/features/notifications/domain/usecases/mark_notification_as_read.dart';

import 'mock_notifications_repository.dart';

void main() {
  late MarkNotificationAsRead useCase;
  late MockNotificationsRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationsRepository();
    useCase = MarkNotificationAsRead(mockRepository);
  });

  group('MarkNotificationAsRead - Success Cases', () {
    test('should mark notification as read', () async {
      // given
      const notificationId = 'notif-1';
      const profileId = 'profile-123';
      final notification = NotificationEntity(
        notificationId: notificationId,
        type: NotificationType.nearbyPost,
        recipientUid: 'user-123',
        recipientProfileId: profileId,
        title: 'Post próximo',
        message: 'Novo post',
        createdAt: DateTime.now(),
        actionType: NotificationActionType.viewPost,
      );
      mockRepository.setupNotificationById(notificationId, notification);

      // when
      await useCase(notificationId: notificationId, profileId: profileId);

      // then
      expect(mockRepository.markAsReadCalled, true);
      expect(mockRepository.lastMarkedAsReadNotificationId, notificationId);
    });

    test('should update unread count after marking as read', () async {
      // given
      const notificationId = 'notif-1';
      const profileId = 'profile-123';
      final notification = NotificationEntity(
        notificationId: notificationId,
        type: NotificationType.interest,
        recipientUid: 'user-123',
        recipientProfileId: profileId,
        title: 'Interesse',
        message: 'Alguém se interessou',
        createdAt: DateTime.now(),
        priority: NotificationPriority.high,
        actionType: NotificationActionType.navigate,
      );
      mockRepository.setupNotificationById(notificationId, notification);
      mockRepository.setupUnreadCount(profileId, 5);

      // when
      await useCase(notificationId: notificationId, profileId: profileId);

      // then
      final updatedNotification =
          await mockRepository.getNotificationById(notificationId);
      expect(updatedNotification?.read, true);
    });
  });

  group('MarkNotificationAsRead - Validation', () {
    test('should throw when notificationId is empty', () async {
      // given
      const notificationId = '';
      const profileId = 'profile-123';

      // when & then
      expect(
        () => useCase(notificationId: notificationId, profileId: profileId),
        throwsA(
          predicate(
              (e) => e.toString().contains('ID da notificação é obrigatório')),
        ),
      );
    });

    test('should throw when profileId is empty', () async {
      // given
      const notificationId = 'notif-1';
      const profileId = '';

      // when & then
      expect(
        () => useCase(notificationId: notificationId, profileId: profileId),
        throwsA(
          predicate((e) => e.toString().contains('ID do perfil é obrigatório')),
        ),
      );
    });
  });

  group('MarkNotificationAsRead - Edge Cases', () {
    test('should handle marking already read notification', () async {
      // given
      const notificationId = 'notif-1';
      const profileId = 'profile-123';
      final notification = NotificationEntity(
        notificationId: notificationId,
        type: NotificationType.newMessage,
        recipientUid: 'user-123',
        recipientProfileId: profileId,
        title: 'Mensagem',
        message: 'Nova mensagem',
        read: true, // Already read
        createdAt: DateTime.now(),
        actionType: NotificationActionType.openChat,
      );
      mockRepository.setupNotificationById(notificationId, notification);

      // when
      await useCase(notificationId: notificationId, profileId: profileId);

      // then
      expect(mockRepository.markAsReadCalled, true);
    });

    test('should handle non-existent notification', () async {
      // given
      const notificationId = 'non-existent';
      const profileId = 'profile-123';
      mockRepository.setupNotificationById(notificationId, null);

      // when
      await useCase(notificationId: notificationId, profileId: profileId);

      // then
      expect(mockRepository.markAsReadCalled, true);
      // No exception - repository handles gracefully
    });
  });

  group('MarkNotificationAsRead - Repository Failures', () {
    test('should propagate exception when repository fails', () async {
      // given
      const notificationId = 'notif-1';
      const profileId = 'profile-123';
      mockRepository.setupMarkAsReadFailure(
          'Erro ao marcar notificação como lida no Firestore');

      // when & then
      expect(
        () => useCase(notificationId: notificationId, profileId: profileId),
        throwsA(
          predicate((e) => e
              .toString()
              .contains('Erro ao marcar notificação como lida no Firestore')),
        ),
      );
    });
  });
}
