// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firestoreHash() => r'0e25e335c5657f593fc1baf3d9fd026e70bca7fa';

/// Provider para FirebaseFirestore instance
///
/// Copied from [firestore].
@ProviderFor(firestore)
final firestoreProvider = AutoDisposeProvider<FirebaseFirestore>.internal(
  firestore,
  name: r'firestoreProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$firestoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirestoreRef = AutoDisposeProviderRef<FirebaseFirestore>;
String _$notificationsRemoteDataSourceHash() =>
    r'17130b6d4c9511ce90419518fcd3098d489c49b0';

/// Provider para NotificationsRemoteDataSource
///
/// Copied from [notificationsRemoteDataSource].
@ProviderFor(notificationsRemoteDataSource)
final notificationsRemoteDataSourceProvider =
    AutoDisposeProvider<INotificationsRemoteDataSource>.internal(
  notificationsRemoteDataSource,
  name: r'notificationsRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationsRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationsRemoteDataSourceRef
    = AutoDisposeProviderRef<INotificationsRemoteDataSource>;
String _$notificationsRepositoryNewHash() =>
    r'b770976ca1711ccadcc80e72749f6474368e0135';

/// Provider para NotificationsRepository (nova implementação Clean Architecture)
///
/// Copied from [notificationsRepositoryNew].
@ProviderFor(notificationsRepositoryNew)
final notificationsRepositoryNewProvider =
    AutoDisposeProvider<NotificationsRepository>.internal(
  notificationsRepositoryNew,
  name: r'notificationsRepositoryNewProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationsRepositoryNewHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationsRepositoryNewRef
    = AutoDisposeProviderRef<NotificationsRepository>;
String _$loadNotificationsUseCaseHash() =>
    r'545df3e540d980926bc9d877710e29450a757488';

/// See also [loadNotificationsUseCase].
@ProviderFor(loadNotificationsUseCase)
final loadNotificationsUseCaseProvider =
    AutoDisposeProvider<LoadNotifications>.internal(
  loadNotificationsUseCase,
  name: r'loadNotificationsUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$loadNotificationsUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LoadNotificationsUseCaseRef = AutoDisposeProviderRef<LoadNotifications>;
String _$markNotificationAsReadUseCaseHash() =>
    r'b1f5e7b17d7da5a9fd89eb800944230e783f8d73';

/// See also [markNotificationAsReadUseCase].
@ProviderFor(markNotificationAsReadUseCase)
final markNotificationAsReadUseCaseProvider =
    AutoDisposeProvider<MarkNotificationAsRead>.internal(
  markNotificationAsReadUseCase,
  name: r'markNotificationAsReadUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$markNotificationAsReadUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MarkNotificationAsReadUseCaseRef
    = AutoDisposeProviderRef<MarkNotificationAsRead>;
String _$markAllNotificationsAsReadUseCaseHash() =>
    r'1dbe93806b12f40b2734618e8a9af98a2a74a32e';

/// See also [markAllNotificationsAsReadUseCase].
@ProviderFor(markAllNotificationsAsReadUseCase)
final markAllNotificationsAsReadUseCaseProvider =
    AutoDisposeProvider<MarkAllNotificationsAsRead>.internal(
  markAllNotificationsAsReadUseCase,
  name: r'markAllNotificationsAsReadUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$markAllNotificationsAsReadUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MarkAllNotificationsAsReadUseCaseRef
    = AutoDisposeProviderRef<MarkAllNotificationsAsRead>;
String _$deleteNotificationUseCaseHash() =>
    r'f11e8a3046e5c6caafffcac1c1958f70600a70bb';

/// See also [deleteNotificationUseCase].
@ProviderFor(deleteNotificationUseCase)
final deleteNotificationUseCaseProvider =
    AutoDisposeProvider<DeleteNotification>.internal(
  deleteNotificationUseCase,
  name: r'deleteNotificationUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deleteNotificationUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeleteNotificationUseCaseRef
    = AutoDisposeProviderRef<DeleteNotification>;
String _$createNotificationUseCaseHash() =>
    r'ecb5afd7a4b72f15c604a6406a8e363f70d1b4b0';

/// See also [createNotificationUseCase].
@ProviderFor(createNotificationUseCase)
final createNotificationUseCaseProvider =
    AutoDisposeProvider<CreateNotification>.internal(
  createNotificationUseCase,
  name: r'createNotificationUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$createNotificationUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CreateNotificationUseCaseRef
    = AutoDisposeProviderRef<CreateNotification>;
String _$getUnreadNotificationCountUseCaseHash() =>
    r'a3223594e4b75641df594d6f5aa9d1a022c20d4d';

/// See also [getUnreadNotificationCountUseCase].
@ProviderFor(getUnreadNotificationCountUseCase)
final getUnreadNotificationCountUseCaseProvider =
    AutoDisposeProvider<GetUnreadNotificationCount>.internal(
  getUnreadNotificationCountUseCase,
  name: r'getUnreadNotificationCountUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$getUnreadNotificationCountUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetUnreadNotificationCountUseCaseRef
    = AutoDisposeProviderRef<GetUnreadNotificationCount>;
String _$notificationsStreamHash() =>
    r'87928495b0794effe4fe13454d2ffb1ec76852be';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Stream de notificações em tempo real
///
/// Copied from [notificationsStream].
@ProviderFor(notificationsStream)
const notificationsStreamProvider = NotificationsStreamFamily();

/// Stream de notificações em tempo real
///
/// Copied from [notificationsStream].
class NotificationsStreamFamily
    extends Family<AsyncValue<List<NotificationEntity>>> {
  /// Stream de notificações em tempo real
  ///
  /// Copied from [notificationsStream].
  const NotificationsStreamFamily();

  /// Stream de notificações em tempo real
  ///
  /// Copied from [notificationsStream].
  NotificationsStreamProvider call(
    String profileId,
  ) {
    return NotificationsStreamProvider(
      profileId,
    );
  }

  @override
  NotificationsStreamProvider getProviderOverride(
    covariant NotificationsStreamProvider provider,
  ) {
    return call(
      provider.profileId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'notificationsStreamProvider';
}

/// Stream de notificações em tempo real
///
/// Copied from [notificationsStream].
class NotificationsStreamProvider
    extends AutoDisposeStreamProvider<List<NotificationEntity>> {
  /// Stream de notificações em tempo real
  ///
  /// Copied from [notificationsStream].
  NotificationsStreamProvider(
    String profileId,
  ) : this._internal(
          (ref) => notificationsStream(
            ref as NotificationsStreamRef,
            profileId,
          ),
          from: notificationsStreamProvider,
          name: r'notificationsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$notificationsStreamHash,
          dependencies: NotificationsStreamFamily._dependencies,
          allTransitiveDependencies:
              NotificationsStreamFamily._allTransitiveDependencies,
          profileId: profileId,
        );

  NotificationsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
  }) : super.internal();

  final String profileId;

  @override
  Override overrideWith(
    Stream<List<NotificationEntity>> Function(NotificationsStreamRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NotificationsStreamProvider._internal(
        (ref) => create(ref as NotificationsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<NotificationEntity>> createElement() {
    return _NotificationsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationsStreamProvider && other.profileId == profileId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NotificationsStreamRef
    on AutoDisposeStreamProviderRef<List<NotificationEntity>> {
  /// The parameter `profileId` of this provider.
  String get profileId;
}

class _NotificationsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<NotificationEntity>>
    with NotificationsStreamRef {
  _NotificationsStreamProviderElement(super.provider);

  @override
  String get profileId => (origin as NotificationsStreamProvider).profileId;
}

String _$unreadNotificationCountForProfileHash() =>
    r'2630f0abaf95b8616ea0327e1fe4c10bbe0433d3';

/// Stream de contador de não lidas para BottomNav badge
///
/// Copied from [unreadNotificationCountForProfile].
@ProviderFor(unreadNotificationCountForProfile)
const unreadNotificationCountForProfileProvider =
    UnreadNotificationCountForProfileFamily();

/// Stream de contador de não lidas para BottomNav badge
///
/// Copied from [unreadNotificationCountForProfile].
class UnreadNotificationCountForProfileFamily extends Family<AsyncValue<int>> {
  /// Stream de contador de não lidas para BottomNav badge
  ///
  /// Copied from [unreadNotificationCountForProfile].
  const UnreadNotificationCountForProfileFamily();

  /// Stream de contador de não lidas para BottomNav badge
  ///
  /// Copied from [unreadNotificationCountForProfile].
  UnreadNotificationCountForProfileProvider call(
    String profileId,
  ) {
    return UnreadNotificationCountForProfileProvider(
      profileId,
    );
  }

  @override
  UnreadNotificationCountForProfileProvider getProviderOverride(
    covariant UnreadNotificationCountForProfileProvider provider,
  ) {
    return call(
      provider.profileId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'unreadNotificationCountForProfileProvider';
}

/// Stream de contador de não lidas para BottomNav badge
///
/// Copied from [unreadNotificationCountForProfile].
class UnreadNotificationCountForProfileProvider
    extends AutoDisposeStreamProvider<int> {
  /// Stream de contador de não lidas para BottomNav badge
  ///
  /// Copied from [unreadNotificationCountForProfile].
  UnreadNotificationCountForProfileProvider(
    String profileId,
  ) : this._internal(
          (ref) => unreadNotificationCountForProfile(
            ref as UnreadNotificationCountForProfileRef,
            profileId,
          ),
          from: unreadNotificationCountForProfileProvider,
          name: r'unreadNotificationCountForProfileProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$unreadNotificationCountForProfileHash,
          dependencies: UnreadNotificationCountForProfileFamily._dependencies,
          allTransitiveDependencies: UnreadNotificationCountForProfileFamily
              ._allTransitiveDependencies,
          profileId: profileId,
        );

  UnreadNotificationCountForProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
  }) : super.internal();

  final String profileId;

  @override
  Override overrideWith(
    Stream<int> Function(UnreadNotificationCountForProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnreadNotificationCountForProfileProvider._internal(
        (ref) => create(ref as UnreadNotificationCountForProfileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<int> createElement() {
    return _UnreadNotificationCountForProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnreadNotificationCountForProfileProvider &&
        other.profileId == profileId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UnreadNotificationCountForProfileRef
    on AutoDisposeStreamProviderRef<int> {
  /// The parameter `profileId` of this provider.
  String get profileId;
}

class _UnreadNotificationCountForProfileProviderElement
    extends AutoDisposeStreamProviderElement<int>
    with UnreadNotificationCountForProfileRef {
  _UnreadNotificationCountForProfileProviderElement(super.provider);

  @override
  String get profileId =>
      (origin as UnreadNotificationCountForProfileProvider).profileId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
