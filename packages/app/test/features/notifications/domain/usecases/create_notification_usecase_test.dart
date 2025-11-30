import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/features/notifications/domain/usecases/create_notification.dart';

import 'mock_notifications_repository.dart';

void main() {
  late CreateNotification useCase;
  late MockNotificationsRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationsRepository();
    useCase = CreateNotification(mockRepository);
  });

  group('CreateNotification - Success Cases', () {
    test('should create notification when all data is valid', () async {
      // given
      final notification = NotificationEntity(
        notificationId: 'notif-1',
        type: NotificationType.nearbyPost,
        recipientUid: 'user-123',
        recipientProfileId: 'profile-456',
        title: 'Novo post próximo',
        message: 'João criou um post a 5km de você',
        createdAt: DateTime.now(),
        actionType: NotificationActionType.viewPost,
        actionData: {'postId': 'post-789'},
      );

      // when
      final result = await useCase(notification);

      // then
      expect(result.notificationId, notification.notificationId);
      expect(result.title, notification.title);
      expect(result.message, notification.message);
      expect(mockRepository.createNotificationCalled, true);
    });

    test('should create notification with high priority', () async {
      // given
      final notification = NotificationEntity(
        notificationId: 'notif-2',
        type: NotificationType.interest,
        recipientUid: 'user-123',
        recipientProfileId: 'profile-456',
        title: 'Alguém se interessou pelo seu post!',
        message: 'Maria demonstrou interesse',
        createdAt: DateTime.now(),
        priority: NotificationPriority.high,
        actionType: NotificationActionType.navigate,
        actionData: {'postId': 'post-789'},
      );

      // when
      final result = await useCase(notification);

      // then
      expect(result.priority, NotificationPriority.high);
    });
  });

  group('CreateNotification - recipientUid Validation', () {
    test('should throw when recipientUid is empty', () async {
      // given
      final notification = NotificationEntity(
        notificationId: 'notif-1',
        type: NotificationType.nearbyPost,
        recipientUid: '',
        recipientProfileId: 'profile-456',
        title: 'Notificação',
        message: 'Mensagem',
        createdAt: DateTime.now(),
        actionType: NotificationActionType.viewPost,
      );

      // when & then
      expect(
        () => useCase(notification),
        throwsA(
          predicate((e) => e.toString().contains('recipientUid é obrigatório')),
        ),
      );
    });
  });

  group('CreateNotification - recipientProfileId Validation', () {
    test('should throw when recipientProfileId is empty', () async {
      // given
      final notification = NotificationEntity(
        notificationId: 'notif-1',
        type: NotificationType.nearbyPost,
        recipientUid: 'user-123',
        recipientProfileId: '',
        title: 'Notificação',
        message: 'Mensagem',
        createdAt: DateTime.now(),
        actionType: NotificationActionType.viewPost,
      );

      // when & then
      expect(
        () => useCase(notification),
        throwsA(
          predicate(
              (e) => e.toString().contains('recipientProfileId é obrigatório')),
        ),
      );
    });
  });

  group('CreateNotification - Title Validation', () {
    test('should throw when title is empty', () async {
      // given
      final notification = NotificationEntity(
        notificationId: 'notif-1',
        type: NotificationType.nearbyPost,
        recipientUid: 'user-123',
        recipientProfileId: 'profile-456',
        title: '',
        message: 'Mensagem',
        createdAt: DateTime.now(),
        actionType: NotificationActionType.viewPost,
      );

      // when & then
      expect(
        () => useCase(notification),
        throwsA(
          predicate((e) => e.toString().contains('title é obrigatório')),
        ),
      );
    });
  });

  group('CreateNotification - Message Validation', () {
    test('should throw when message is empty', () async {
      // given
      final notification = NotificationEntity(
        notificationId: 'notif-1',
        type: NotificationType.nearbyPost,
        recipientUid: 'user-123',
        recipientProfileId: 'profile-456',
        title: 'Título',
        message: '',
        createdAt: DateTime.now(),
        actionType: NotificationActionType.viewPost,
      );

      // when & then
      expect(
        () => useCase(notification),
        throwsA(
          predicate((e) => e.toString().contains('message é obrigatório')),
        ),
      );
    });
  });

  group('CreateNotification - Notification Types', () {
    test('should create proximity notification', () async {
      // given
      final notification = NotificationEntity(
        notificationId: 'notif-1',
        type: NotificationType.nearbyPost,
        recipientUid: 'user-123',
        recipientProfileId: 'profile-456',
        title: 'Post próximo',
        message: 'Novo post',
        createdAt: DateTime.now(),
        actionType: NotificationActionType.viewPost,
      );

      // when
      final result = await useCase(notification);

      // then
      expect(result.type, NotificationType.nearbyPost);
    });

    test('should create interest notification', () async {
      // given
      final notification = NotificationEntity(
        notificationId: 'notif-2',
        type: NotificationType.interest,
        recipientUid: 'user-123',
        recipientProfileId: 'profile-456',
        title: 'Interesse',
        message: 'Alguém se interessou',
        createdAt: DateTime.now(),
        priority: NotificationPriority.high,
        actionType: NotificationActionType.navigate,
      );

      // when
      final result = await useCase(notification);

      // then
      expect(result.type, NotificationType.interest);
    });

    test('should create message notification', () async {
      // given
      final notification = NotificationEntity(
        notificationId: 'notif-3',
        type: NotificationType.newMessage,
        recipientUid: 'user-123',
        recipientProfileId: 'profile-456',
        title: 'Nova mensagem',
        message: 'João enviou uma mensagem',
        createdAt: DateTime.now(),
        priority: NotificationPriority.high,
        actionType: NotificationActionType.openChat,
      );

      // when
      final result = await useCase(notification);

      // then
      expect(result.type, NotificationType.newMessage);
    });
  });

  group('CreateNotification - Repository Failures', () {
    test('should propagate exception when repository fails', () async {
      // given
      final notification = NotificationEntity(
        notificationId: 'notif-1',
        type: NotificationType.nearbyPost,
        recipientUid: 'user-123',
        recipientProfileId: 'profile-456',
        title: 'Título',
        message: 'Mensagem',
        createdAt: DateTime.now(),
        actionType: NotificationActionType.viewPost,
      );
      mockRepository.setupCreateNotificationFailure(
          'Erro ao salvar notificação no Firestore');

      // when & then
      expect(
        () => useCase(notification),
        throwsA(
          predicate((e) =>
              e.toString().contains('Erro ao salvar notificação no Firestore')),
        ),
      );
    });
  });
}
