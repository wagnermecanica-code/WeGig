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

String _$firestoreHash() => r'ef4a6b0737caace50a6d79dd3e4e2aa1bc3031d5';

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
    r'bf0064341200d91ac78b59027e198e253c65135c';

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
    r'061406f4ba7610bc16ac5523b97841d1e93422b9';

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
    r'9eb7c2ebf097cd58cbc4a76336055ece39f2a21c';

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
    r'24397a987924813c5f55edb8674b1f164b005001';

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
    r'7ac1173115543ddd50a7f16a8f9a0547a80666e0';

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
    r'ea9276fc08f91ffc948f2771dd5d45e4e95f3d98';

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
    r'b46ecc959fbb5d572a77a54d8b8e276f28af16de';

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
    r'66a65f0d6eeb9fcfe00ec80b56d91d2a2bc08ad3';

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
