// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider para FirebaseFirestore instance

@ProviderFor(firestore)
const firestoreProvider = FirestoreProvider._();

/// Provider para FirebaseFirestore instance

final class FirestoreProvider extends $FunctionalProvider<FirebaseFirestore,
    FirebaseFirestore, FirebaseFirestore> with $Provider<FirebaseFirestore> {
  /// Provider para FirebaseFirestore instance
  const FirestoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'firestoreProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$firestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return firestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$firestoreHash() => r'0e25e335c5657f593fc1baf3d9fd026e70bca7fa';

/// Provider para NotificationsRemoteDataSource

@ProviderFor(notificationsRemoteDataSource)
const notificationsRemoteDataSourceProvider =
    NotificationsRemoteDataSourceProvider._();

/// Provider para NotificationsRemoteDataSource

final class NotificationsRemoteDataSourceProvider extends $FunctionalProvider<
        INotificationsRemoteDataSource,
        INotificationsRemoteDataSource,
        INotificationsRemoteDataSource>
    with $Provider<INotificationsRemoteDataSource> {
  /// Provider para NotificationsRemoteDataSource
  const NotificationsRemoteDataSourceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'notificationsRemoteDataSourceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$notificationsRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<INotificationsRemoteDataSource> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  INotificationsRemoteDataSource create(Ref ref) {
    return notificationsRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(INotificationsRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<INotificationsRemoteDataSource>(value),
    );
  }
}

String _$notificationsRemoteDataSourceHash() =>
    r'17130b6d4c9511ce90419518fcd3098d489c49b0';

/// Provider para NotificationsRepository (nova implementação Clean Architecture)

@ProviderFor(notificationsRepositoryNew)
const notificationsRepositoryNewProvider =
    NotificationsRepositoryNewProvider._();

/// Provider para NotificationsRepository (nova implementação Clean Architecture)

final class NotificationsRepositoryNewProvider extends $FunctionalProvider<
    NotificationsRepository,
    NotificationsRepository,
    NotificationsRepository> with $Provider<NotificationsRepository> {
  /// Provider para NotificationsRepository (nova implementação Clean Architecture)
  const NotificationsRepositoryNewProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'notificationsRepositoryNewProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$notificationsRepositoryNewHash();

  @$internal
  @override
  $ProviderElement<NotificationsRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NotificationsRepository create(Ref ref) {
    return notificationsRepositoryNew(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationsRepository>(value),
    );
  }
}

String _$notificationsRepositoryNewHash() =>
    r'b770976ca1711ccadcc80e72749f6474368e0135';

@ProviderFor(loadNotificationsUseCase)
const loadNotificationsUseCaseProvider = LoadNotificationsUseCaseProvider._();

final class LoadNotificationsUseCaseProvider extends $FunctionalProvider<
    LoadNotifications,
    LoadNotifications,
    LoadNotifications> with $Provider<LoadNotifications> {
  const LoadNotificationsUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'loadNotificationsUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$loadNotificationsUseCaseHash();

  @$internal
  @override
  $ProviderElement<LoadNotifications> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoadNotifications create(Ref ref) {
    return loadNotificationsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoadNotifications value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoadNotifications>(value),
    );
  }
}

String _$loadNotificationsUseCaseHash() =>
    r'545df3e540d980926bc9d877710e29450a757488';

@ProviderFor(markNotificationAsReadUseCase)
const markNotificationAsReadUseCaseProvider =
    MarkNotificationAsReadUseCaseProvider._();

final class MarkNotificationAsReadUseCaseProvider extends $FunctionalProvider<
    MarkNotificationAsRead,
    MarkNotificationAsRead,
    MarkNotificationAsRead> with $Provider<MarkNotificationAsRead> {
  const MarkNotificationAsReadUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'markNotificationAsReadUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$markNotificationAsReadUseCaseHash();

  @$internal
  @override
  $ProviderElement<MarkNotificationAsRead> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MarkNotificationAsRead create(Ref ref) {
    return markNotificationAsReadUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarkNotificationAsRead value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarkNotificationAsRead>(value),
    );
  }
}

String _$markNotificationAsReadUseCaseHash() =>
    r'b1f5e7b17d7da5a9fd89eb800944230e783f8d73';

@ProviderFor(markAllNotificationsAsReadUseCase)
const markAllNotificationsAsReadUseCaseProvider =
    MarkAllNotificationsAsReadUseCaseProvider._();

final class MarkAllNotificationsAsReadUseCaseProvider
    extends $FunctionalProvider<
        MarkAllNotificationsAsRead,
        MarkAllNotificationsAsRead,
        MarkAllNotificationsAsRead> with $Provider<MarkAllNotificationsAsRead> {
  const MarkAllNotificationsAsReadUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'markAllNotificationsAsReadUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() =>
      _$markAllNotificationsAsReadUseCaseHash();

  @$internal
  @override
  $ProviderElement<MarkAllNotificationsAsRead> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MarkAllNotificationsAsRead create(Ref ref) {
    return markAllNotificationsAsReadUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarkAllNotificationsAsRead value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarkAllNotificationsAsRead>(value),
    );
  }
}

String _$markAllNotificationsAsReadUseCaseHash() =>
    r'1dbe93806b12f40b2734618e8a9af98a2a74a32e';

@ProviderFor(deleteNotificationUseCase)
const deleteNotificationUseCaseProvider = DeleteNotificationUseCaseProvider._();

final class DeleteNotificationUseCaseProvider extends $FunctionalProvider<
    DeleteNotification,
    DeleteNotification,
    DeleteNotification> with $Provider<DeleteNotification> {
  const DeleteNotificationUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'deleteNotificationUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$deleteNotificationUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteNotification> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeleteNotification create(Ref ref) {
    return deleteNotificationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteNotification value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteNotification>(value),
    );
  }
}

String _$deleteNotificationUseCaseHash() =>
    r'f11e8a3046e5c6caafffcac1c1958f70600a70bb';

@ProviderFor(createNotificationUseCase)
const createNotificationUseCaseProvider = CreateNotificationUseCaseProvider._();

final class CreateNotificationUseCaseProvider extends $FunctionalProvider<
    CreateNotification,
    CreateNotification,
    CreateNotification> with $Provider<CreateNotification> {
  const CreateNotificationUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'createNotificationUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$createNotificationUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreateNotification> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CreateNotification create(Ref ref) {
    return createNotificationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateNotification value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateNotification>(value),
    );
  }
}

String _$createNotificationUseCaseHash() =>
    r'ecb5afd7a4b72f15c604a6406a8e363f70d1b4b0';

@ProviderFor(getUnreadNotificationCountUseCase)
const getUnreadNotificationCountUseCaseProvider =
    GetUnreadNotificationCountUseCaseProvider._();

final class GetUnreadNotificationCountUseCaseProvider
    extends $FunctionalProvider<
        GetUnreadNotificationCount,
        GetUnreadNotificationCount,
        GetUnreadNotificationCount> with $Provider<GetUnreadNotificationCount> {
  const GetUnreadNotificationCountUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getUnreadNotificationCountUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() =>
      _$getUnreadNotificationCountUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetUnreadNotificationCount> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetUnreadNotificationCount create(Ref ref) {
    return getUnreadNotificationCountUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetUnreadNotificationCount value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetUnreadNotificationCount>(value),
    );
  }
}

String _$getUnreadNotificationCountUseCaseHash() =>
    r'a3223594e4b75641df594d6f5aa9d1a022c20d4d';

/// Stream de notificações em tempo real

@ProviderFor(notificationsStream)
const notificationsStreamProvider = NotificationsStreamFamily._();

/// Stream de notificações em tempo real

final class NotificationsStreamProvider extends $FunctionalProvider<
        AsyncValue<List<NotificationEntity>>,
        List<NotificationEntity>,
        Stream<List<NotificationEntity>>>
    with
        $FutureModifier<List<NotificationEntity>>,
        $StreamProvider<List<NotificationEntity>> {
  /// Stream de notificações em tempo real
  const NotificationsStreamProvider._(
      {required NotificationsStreamFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'notificationsStreamProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$notificationsStreamHash();

  @override
  String toString() {
    return r'notificationsStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<NotificationEntity>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<NotificationEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return notificationsStream(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationsStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$notificationsStreamHash() =>
    r'efc7769af9b718f353218f62457cd3f354c04b4c';

/// Stream de notificações em tempo real

final class NotificationsStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<NotificationEntity>>, String> {
  const NotificationsStreamFamily._()
      : super(
          retry: null,
          name: r'notificationsStreamProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Stream de notificações em tempo real

  NotificationsStreamProvider call(
    String profileId,
  ) =>
      NotificationsStreamProvider._(argument: profileId, from: this);

  @override
  String toString() => r'notificationsStreamProvider';
}

/// Stream de contador de não lidas para BottomNav badge

@ProviderFor(unreadNotificationCountForProfile)
const unreadNotificationCountForProfileProvider =
    UnreadNotificationCountForProfileFamily._();

/// Stream de contador de não lidas para BottomNav badge

final class UnreadNotificationCountForProfileProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Stream de contador de não lidas para BottomNav badge
  const UnreadNotificationCountForProfileProvider._(
      {required UnreadNotificationCountForProfileFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'unreadNotificationCountForProfileProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() =>
      _$unreadNotificationCountForProfileHash();

  @override
  String toString() {
    return r'unreadNotificationCountForProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as String;
    return unreadNotificationCountForProfile(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UnreadNotificationCountForProfileProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$unreadNotificationCountForProfileHash() =>
    r'c274a4ee3272789d20ad2e3835751c221ca4f066';

/// Stream de contador de não lidas para BottomNav badge

final class UnreadNotificationCountForProfileFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, String> {
  const UnreadNotificationCountForProfileFamily._()
      : super(
          retry: null,
          name: r'unreadNotificationCountForProfileProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Stream de contador de não lidas para BottomNav badge

  UnreadNotificationCountForProfileProvider call(
    String profileId,
  ) =>
      UnreadNotificationCountForProfileProvider._(
          argument: profileId, from: this);

  @override
  String toString() => r'unreadNotificationCountForProfileProvider';
}
