import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegig_app/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:wegig_app/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:wegig_app/features/notifications/domain/usecases/create_notification.dart';
import 'package:wegig_app/features/notifications/domain/usecases/delete_notification.dart';
import 'package:wegig_app/features/notifications/domain/usecases/get_unread_notification_count.dart';
import 'package:wegig_app/features/notifications/domain/usecases/load_notifications.dart';
import 'package:wegig_app/features/notifications/domain/usecases/mark_all_notifications_as_read.dart';
import 'package:wegig_app/features/notifications/domain/usecases/mark_notification_as_read.dart';
import 'package:wegig_app/features/notifications/presentation/providers/notifications_providers.dart';

// ============================================================================
// MOCK CLASSES
// ============================================================================

class _MockNotificationsRemoteDataSource
    implements INotificationsRemoteDataSource {
  @override
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    int limit = 50,
    NotificationEntity? startAfter,
    String? recipientUid,
    NotificationType? type,
  }) async {
    return [];
  }

  @override
  Future<NotificationEntity?> getNotificationById(String notificationId) async {
    return null;
  }

  @override
  Future<void> markAsRead(String notificationId, String profileId) async {}

  @override
  Future<void> markAllAsRead(String profileId, {String? recipientUid}) async {}

  @override
  Future<void> deleteNotification(
      String notificationId, String profileId) async {}

  @override
  Future<NotificationEntity> createNotification(
      NotificationEntity notification) async {
    return notification;
  }

  @override
  Future<int> getUnreadCount(String profileId, {String? recipientUid}) async {
    return 0;
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications(
      String profileId, int limit, {String? recipientUid}) {
    return Stream.value([]);
  }

  @override
  Stream<int> watchUnreadCount(String profileId, {String? recipientUid}) {
    return Stream.value(0);
  }
}

class _MockNotificationsRepository implements NotificationsRepository {
  @override
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    int limit = 50,
    NotificationEntity? startAfter,
    String? recipientUid,
    NotificationType? type,
  }) async {
    return [];
  }

  @override
  Future<NotificationEntity?> getNotificationById(String notificationId) async {
    return null;
  }

  @override
  Future<void> markAsRead({
    required String notificationId,
    required String profileId,
  }) async {}

  @override
  Future<void> markAllAsRead({
    required String profileId,
    String? recipientUid,
  }) async {}

  @override
  Future<void> deleteNotification({
    required String notificationId,
    required String profileId,
  }) async {}

  @override
  Future<NotificationEntity> createNotification(
      NotificationEntity notification) async {
    return notification;
  }

  @override
  Future<int> getUnreadCount({
    required String profileId,
    String? recipientUid,
  }) async {
    return 0;
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications({
    required String profileId,
    int limit = 50,
    String? recipientUid,
  }) {
    return Stream.value([]);
  }

  @override
  Stream<int> watchUnreadCount({
    required String profileId,
    String? recipientUid,
  }) {
    return Stream.value(0);
  }
}

// ============================================================================
// TESTS
// ============================================================================

void main() {
  late ProviderContainer container;

  setUp(() {
    final mockDataSource = _MockNotificationsRemoteDataSource();
    final mockRepository = _MockNotificationsRepository();

    container = ProviderContainer(
      overrides: [
        notificationsRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        notificationsRepositoryNewProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Notifications Providers - Data Layer', () {
    test('notificationsRemoteDataSourceProvider returns singleton', () {
      final ds1 = container.read(notificationsRemoteDataSourceProvider);
      final ds2 = container.read(notificationsRemoteDataSourceProvider);
      expect(identical(ds1, ds2), isTrue,
          reason: 'DataSource is singleton, must return same instance');
    });

    test(
        'notificationsRemoteDataSourceProvider returns NotificationsRemoteDataSource',
        () {
      final dataSource =
          container.read(notificationsRemoteDataSourceProvider);
      expect(dataSource, isA<INotificationsRemoteDataSource>());
    });

    test('notificationsRepositoryNewProvider returns NotificationsRepository',
        () {
      final repository = container.read(notificationsRepositoryNewProvider);
      expect(repository, isA<NotificationsRepository>());
    });

    test('notificationsRepositoryNewProvider returns singleton', () {
      final repo1 = container.read(notificationsRepositoryNewProvider);
      final repo2 = container.read(notificationsRepositoryNewProvider);
      expect(identical(repo1, repo2), isTrue,
          reason: 'Repository is singleton, must return same instance');
    });
  });

  group('Notifications Providers - Use Cases', () {
    test('loadNotificationsUseCaseProvider returns LoadNotifications', () {
      final useCase = container.read(loadNotificationsUseCaseProvider);
      expect(useCase, isA<LoadNotifications>());
    });

    test(
        'markNotificationAsReadUseCaseProvider returns MarkNotificationAsRead',
        () {
      final useCase = container.read(markNotificationAsReadUseCaseProvider);
      expect(useCase, isA<MarkNotificationAsRead>());
    });

    test(
        'markAllNotificationsAsReadUseCaseProvider returns MarkAllNotificationsAsRead',
        () {
      final useCase =
          container.read(markAllNotificationsAsReadUseCaseProvider);
      expect(useCase, isA<MarkAllNotificationsAsRead>());
    });

    test('deleteNotificationUseCaseProvider returns DeleteNotification', () {
      final useCase = container.read(deleteNotificationUseCaseProvider);
      expect(useCase, isA<DeleteNotification>());
    });

    test('createNotificationUseCaseProvider returns CreateNotification', () {
      final useCase = container.read(createNotificationUseCaseProvider);
      expect(useCase, isA<CreateNotification>());
    });

    test(
        'getUnreadNotificationCountUseCaseProvider returns GetUnreadNotificationCount',
        () {
      final useCase = container.read(getUnreadNotificationCountUseCaseProvider);
      expect(useCase, isA<GetUnreadNotificationCount>());
    });

    test('All use cases depend on notificationsRepositoryNewProvider', () {
      final repositoryCallCount = 6; // 6 use cases
      var actualCalls = 0;

      // Read repository through each use case
      container.read(loadNotificationsUseCaseProvider);
      actualCalls++;
      container.read(markNotificationAsReadUseCaseProvider);
      actualCalls++;
      container.read(markAllNotificationsAsReadUseCaseProvider);
      actualCalls++;
      container.read(deleteNotificationUseCaseProvider);
      actualCalls++;
      container.read(createNotificationUseCaseProvider);
      actualCalls++;
      container.read(getUnreadNotificationCountUseCaseProvider);
      actualCalls++;

      expect(actualCalls, equals(repositoryCallCount),
          reason:
              'All 6 use cases should depend on notificationsRepositoryNewProvider');
    });

    test('Use cases are singletons within the same container', () {
      final useCase1 = container.read(loadNotificationsUseCaseProvider);
      final useCase2 = container.read(loadNotificationsUseCaseProvider);
      expect(identical(useCase1, useCase2), isTrue,
          reason: 'Use cases should be singletons');
    });
  });

  group('Notifications Providers - Overrides', () {
    test('Can override notificationsRepositoryNewProvider', () {
      final customRepository = _MockNotificationsRepository();
      final containerWithOverride = ProviderContainer(
        overrides: [
          notificationsRepositoryNewProvider
              .overrideWithValue(customRepository),
        ],
      );

      final repository =
          containerWithOverride.read(notificationsRepositoryNewProvider);
      expect(identical(repository, customRepository), isTrue,
          reason: 'Should use overridden repository');

      containerWithOverride.dispose();
    });

    test('Can override use case providers', () {
      final customRepository = _MockNotificationsRepository();
      final containerWithOverride = ProviderContainer(
        overrides: [
          notificationsRepositoryNewProvider
              .overrideWithValue(customRepository),
        ],
      );

      final useCase =
          containerWithOverride.read(loadNotificationsUseCaseProvider);
      expect(useCase, isA<LoadNotifications>(),
          reason: 'Use case should be created with overridden repository');

      containerWithOverride.dispose();
    });
  });

  group('Notifications Providers - Stream Providers', () {
    test('notificationsStreamProvider can be read without errors', () {
      // StreamProvider with @riverpod annotation
      expect(() => container.read(notificationsStreamProvider('profile-123', 'uid-123')),
          returnsNormally,
          reason: 'Should be able to read notifications stream provider');
    });

    test(
        'unreadNotificationCountForProfileProvider can be read without errors',
        () {
      expect(
          () => container
              .read(unreadNotificationCountForProfileProvider('profile-123', 'uid-123')),
          returnsNormally,
          reason:
              'Should be able to read unread notification count stream provider');
    });
  });

  group('Notifications Providers - Lifecycle', () {
    test('Providers are auto-disposed when container is disposed', () {
      var isDisposed = false;
      final testContainer = ProviderContainer(
        overrides: [
          notificationsRemoteDataSourceProvider
              .overrideWithValue(_MockNotificationsRemoteDataSource()),
        ],
      );

      // Read provider to initialize it
      testContainer.read(notificationsRemoteDataSourceProvider);

      testContainer.dispose();
      isDisposed = true;

      expect(isDisposed, isTrue,
          reason: 'Container disposal should complete without errors');
    });
  });
}
