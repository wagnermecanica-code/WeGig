// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_new_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationsNewRemoteDataSourceHash() =>
    r'640ffdba6eb58faab3d234545ea45163cc7c5ff2';

/// Provider para o DataSource de notificações
///
/// Singleton gerenciado pelo Riverpod, descartado automaticamente quando
/// não há mais listeners.
///
/// Copied from [notificationsNewRemoteDataSource].
@ProviderFor(notificationsNewRemoteDataSource)
final notificationsNewRemoteDataSourceProvider =
    AutoDisposeProvider<INotificationsNewRemoteDataSource>.internal(
  notificationsNewRemoteDataSource,
  name: r'notificationsNewRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationsNewRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationsNewRemoteDataSourceRef
    = AutoDisposeProviderRef<INotificationsNewRemoteDataSource>;
String _$notificationsNewRepositoryHash() =>
    r'a110bdabcea8951dfc6e149dc1c5291db7267ae4';

/// Provider para o Repository de notificações
///
/// Injeta o DataSource automaticamente via ref.watch.
///
/// Copied from [notificationsNewRepository].
@ProviderFor(notificationsNewRepository)
final notificationsNewRepositoryProvider =
    AutoDisposeProvider<NotificationsNewRepository>.internal(
  notificationsNewRepository,
  name: r'notificationsNewRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationsNewRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationsNewRepositoryRef
    = AutoDisposeProviderRef<NotificationsNewRepository>;
String _$loadNotificationsNewUseCaseHash() =>
    r'1527ffd61cdcabcfd90ef1d697ba8b34b09cf7c1';

/// Provider para LoadNotificationsNewUseCase
///
/// Copied from [loadNotificationsNewUseCase].
@ProviderFor(loadNotificationsNewUseCase)
final loadNotificationsNewUseCaseProvider =
    AutoDisposeProvider<LoadNotificationsNewUseCase>.internal(
  loadNotificationsNewUseCase,
  name: r'loadNotificationsNewUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$loadNotificationsNewUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LoadNotificationsNewUseCaseRef
    = AutoDisposeProviderRef<LoadNotificationsNewUseCase>;
String _$markNotificationAsReadNewUseCaseHash() =>
    r'07972f0c2bbc235eb66dc52029784dc915ce44b4';

/// Provider para MarkNotificationAsReadNewUseCase
///
/// Copied from [markNotificationAsReadNewUseCase].
@ProviderFor(markNotificationAsReadNewUseCase)
final markNotificationAsReadNewUseCaseProvider =
    AutoDisposeProvider<MarkNotificationAsReadNewUseCase>.internal(
  markNotificationAsReadNewUseCase,
  name: r'markNotificationAsReadNewUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$markNotificationAsReadNewUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MarkNotificationAsReadNewUseCaseRef
    = AutoDisposeProviderRef<MarkNotificationAsReadNewUseCase>;
String _$markAllNotificationsAsReadNewUseCaseHash() =>
    r'9dd4f1078de9810baddff679d41219e8cf93a1f7';

/// Provider para MarkAllNotificationsAsReadNewUseCase
///
/// Copied from [markAllNotificationsAsReadNewUseCase].
@ProviderFor(markAllNotificationsAsReadNewUseCase)
final markAllNotificationsAsReadNewUseCaseProvider =
    AutoDisposeProvider<MarkAllNotificationsAsReadNewUseCase>.internal(
  markAllNotificationsAsReadNewUseCase,
  name: r'markAllNotificationsAsReadNewUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$markAllNotificationsAsReadNewUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MarkAllNotificationsAsReadNewUseCaseRef
    = AutoDisposeProviderRef<MarkAllNotificationsAsReadNewUseCase>;
String _$deleteNotificationNewUseCaseHash() =>
    r'e07127d87471ef71597115790096f632961a39e5';

/// Provider para DeleteNotificationNewUseCase
///
/// Copied from [deleteNotificationNewUseCase].
@ProviderFor(deleteNotificationNewUseCase)
final deleteNotificationNewUseCaseProvider =
    AutoDisposeProvider<DeleteNotificationNewUseCase>.internal(
  deleteNotificationNewUseCase,
  name: r'deleteNotificationNewUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deleteNotificationNewUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeleteNotificationNewUseCaseRef
    = AutoDisposeProviderRef<DeleteNotificationNewUseCase>;
String _$getUnreadCountNewUseCaseHash() =>
    r'b40f3f6ceb64381686ec55c80552e8f16a89f58a';

/// Provider para GetUnreadCountNewUseCase
///
/// Copied from [getUnreadCountNewUseCase].
@ProviderFor(getUnreadCountNewUseCase)
final getUnreadCountNewUseCaseProvider =
    AutoDisposeProvider<GetUnreadCountNewUseCase>.internal(
  getUnreadCountNewUseCase,
  name: r'getUnreadCountNewUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$getUnreadCountNewUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetUnreadCountNewUseCaseRef
    = AutoDisposeProviderRef<GetUnreadCountNewUseCase>;
String _$notificationsNewStreamHash() =>
    r'724f3865bdb85f6ec959fd7427d531822dad4f0f';

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

/// Stream de notificações em tempo real para um perfil
///
/// Requer profileId E recipientUid para match com Security Rules.
/// Invalida automaticamente quando perfil muda.
///
/// Copied from [notificationsNewStream].
@ProviderFor(notificationsNewStream)
const notificationsNewStreamProvider = NotificationsNewStreamFamily();

/// Stream de notificações em tempo real para um perfil
///
/// Requer profileId E recipientUid para match com Security Rules.
/// Invalida automaticamente quando perfil muda.
///
/// Copied from [notificationsNewStream].
class NotificationsNewStreamFamily
    extends Family<AsyncValue<List<NotificationEntity>>> {
  /// Stream de notificações em tempo real para um perfil
  ///
  /// Requer profileId E recipientUid para match com Security Rules.
  /// Invalida automaticamente quando perfil muda.
  ///
  /// Copied from [notificationsNewStream].
  const NotificationsNewStreamFamily();

  /// Stream de notificações em tempo real para um perfil
  ///
  /// Requer profileId E recipientUid para match com Security Rules.
  /// Invalida automaticamente quando perfil muda.
  ///
  /// Copied from [notificationsNewStream].
  NotificationsNewStreamProvider call(
    String profileId,
    String recipientUid,
  ) {
    return NotificationsNewStreamProvider(
      profileId,
      recipientUid,
    );
  }

  @override
  NotificationsNewStreamProvider getProviderOverride(
    covariant NotificationsNewStreamProvider provider,
  ) {
    return call(
      provider.profileId,
      provider.recipientUid,
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
  String? get name => r'notificationsNewStreamProvider';
}

/// Stream de notificações em tempo real para um perfil
///
/// Requer profileId E recipientUid para match com Security Rules.
/// Invalida automaticamente quando perfil muda.
///
/// Copied from [notificationsNewStream].
class NotificationsNewStreamProvider
    extends AutoDisposeStreamProvider<List<NotificationEntity>> {
  /// Stream de notificações em tempo real para um perfil
  ///
  /// Requer profileId E recipientUid para match com Security Rules.
  /// Invalida automaticamente quando perfil muda.
  ///
  /// Copied from [notificationsNewStream].
  NotificationsNewStreamProvider(
    String profileId,
    String recipientUid,
  ) : this._internal(
          (ref) => notificationsNewStream(
            ref as NotificationsNewStreamRef,
            profileId,
            recipientUid,
          ),
          from: notificationsNewStreamProvider,
          name: r'notificationsNewStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$notificationsNewStreamHash,
          dependencies: NotificationsNewStreamFamily._dependencies,
          allTransitiveDependencies:
              NotificationsNewStreamFamily._allTransitiveDependencies,
          profileId: profileId,
          recipientUid: recipientUid,
        );

  NotificationsNewStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
    required this.recipientUid,
  }) : super.internal();

  final String profileId;
  final String recipientUid;

  @override
  Override overrideWith(
    Stream<List<NotificationEntity>> Function(
            NotificationsNewStreamRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NotificationsNewStreamProvider._internal(
        (ref) => create(ref as NotificationsNewStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
        recipientUid: recipientUid,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<NotificationEntity>> createElement() {
    return _NotificationsNewStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationsNewStreamProvider &&
        other.profileId == profileId &&
        other.recipientUid == recipientUid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);
    hash = _SystemHash.combine(hash, recipientUid.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NotificationsNewStreamRef
    on AutoDisposeStreamProviderRef<List<NotificationEntity>> {
  /// The parameter `profileId` of this provider.
  String get profileId;

  /// The parameter `recipientUid` of this provider.
  String get recipientUid;
}

class _NotificationsNewStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<NotificationEntity>>
    with NotificationsNewStreamRef {
  _NotificationsNewStreamProviderElement(super.provider);

  @override
  String get profileId => (origin as NotificationsNewStreamProvider).profileId;
  @override
  String get recipientUid =>
      (origin as NotificationsNewStreamProvider).recipientUid;
}

String _$unreadNotificationCountNewStreamHash() =>
    r'fe20d457a02373cfc392e70a99311adb6b773327';

/// Stream de contador de não lidas em tempo real
///
/// Usado para badge no BottomNavigation.
/// Emite apenas quando valor muda (distinct).
///
/// Copied from [unreadNotificationCountNewStream].
@ProviderFor(unreadNotificationCountNewStream)
const unreadNotificationCountNewStreamProvider =
    UnreadNotificationCountNewStreamFamily();

/// Stream de contador de não lidas em tempo real
///
/// Usado para badge no BottomNavigation.
/// Emite apenas quando valor muda (distinct).
///
/// Copied from [unreadNotificationCountNewStream].
class UnreadNotificationCountNewStreamFamily extends Family<AsyncValue<int>> {
  /// Stream de contador de não lidas em tempo real
  ///
  /// Usado para badge no BottomNavigation.
  /// Emite apenas quando valor muda (distinct).
  ///
  /// Copied from [unreadNotificationCountNewStream].
  const UnreadNotificationCountNewStreamFamily();

  /// Stream de contador de não lidas em tempo real
  ///
  /// Usado para badge no BottomNavigation.
  /// Emite apenas quando valor muda (distinct).
  ///
  /// Copied from [unreadNotificationCountNewStream].
  UnreadNotificationCountNewStreamProvider call(
    String profileId,
    String recipientUid,
  ) {
    return UnreadNotificationCountNewStreamProvider(
      profileId,
      recipientUid,
    );
  }

  @override
  UnreadNotificationCountNewStreamProvider getProviderOverride(
    covariant UnreadNotificationCountNewStreamProvider provider,
  ) {
    return call(
      provider.profileId,
      provider.recipientUid,
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
  String? get name => r'unreadNotificationCountNewStreamProvider';
}

/// Stream de contador de não lidas em tempo real
///
/// Usado para badge no BottomNavigation.
/// Emite apenas quando valor muda (distinct).
///
/// Copied from [unreadNotificationCountNewStream].
class UnreadNotificationCountNewStreamProvider
    extends AutoDisposeStreamProvider<int> {
  /// Stream de contador de não lidas em tempo real
  ///
  /// Usado para badge no BottomNavigation.
  /// Emite apenas quando valor muda (distinct).
  ///
  /// Copied from [unreadNotificationCountNewStream].
  UnreadNotificationCountNewStreamProvider(
    String profileId,
    String recipientUid,
  ) : this._internal(
          (ref) => unreadNotificationCountNewStream(
            ref as UnreadNotificationCountNewStreamRef,
            profileId,
            recipientUid,
          ),
          from: unreadNotificationCountNewStreamProvider,
          name: r'unreadNotificationCountNewStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$unreadNotificationCountNewStreamHash,
          dependencies: UnreadNotificationCountNewStreamFamily._dependencies,
          allTransitiveDependencies:
              UnreadNotificationCountNewStreamFamily._allTransitiveDependencies,
          profileId: profileId,
          recipientUid: recipientUid,
        );

  UnreadNotificationCountNewStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
    required this.recipientUid,
  }) : super.internal();

  final String profileId;
  final String recipientUid;

  @override
  Override overrideWith(
    Stream<int> Function(UnreadNotificationCountNewStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnreadNotificationCountNewStreamProvider._internal(
        (ref) => create(ref as UnreadNotificationCountNewStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
        recipientUid: recipientUid,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<int> createElement() {
    return _UnreadNotificationCountNewStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnreadNotificationCountNewStreamProvider &&
        other.profileId == profileId &&
        other.recipientUid == recipientUid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);
    hash = _SystemHash.combine(hash, recipientUid.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UnreadNotificationCountNewStreamRef on AutoDisposeStreamProviderRef<int> {
  /// The parameter `profileId` of this provider.
  String get profileId;

  /// The parameter `recipientUid` of this provider.
  String get recipientUid;
}

class _UnreadNotificationCountNewStreamProviderElement
    extends AutoDisposeStreamProviderElement<int>
    with UnreadNotificationCountNewStreamRef {
  _UnreadNotificationCountNewStreamProviderElement(super.provider);

  @override
  String get profileId =>
      (origin as UnreadNotificationCountNewStreamProvider).profileId;
  @override
  String get recipientUid =>
      (origin as UnreadNotificationCountNewStreamProvider).recipientUid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
