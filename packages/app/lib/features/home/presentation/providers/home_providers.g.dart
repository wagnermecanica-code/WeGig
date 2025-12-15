// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firestoreHash() => r'0e25e335c5657f593fc1baf3d9fd026e70bca7fa';

/// Provider para Firestore instance
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
String _$homeRepositoryHash() => r'acfd1b6a39851f5dbf8a8776cc45abb2a32c8b64';

/// Provider para HomeRepository
///
/// Copied from [homeRepository].
@ProviderFor(homeRepository)
final homeRepositoryProvider = AutoDisposeProvider<HomeRepository>.internal(
  homeRepository,
  name: r'homeRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeRepositoryRef = AutoDisposeProviderRef<HomeRepository>;
String _$loadNearbyPostsUseCaseHash() =>
    r'9fa666579f1733c299742ef279970afb6cd0fee1';

/// Provider para LoadNearbyPostsUseCase
///
/// Copied from [loadNearbyPostsUseCase].
@ProviderFor(loadNearbyPostsUseCase)
final loadNearbyPostsUseCaseProvider =
    AutoDisposeProvider<LoadNearbyPostsUseCase>.internal(
  loadNearbyPostsUseCase,
  name: r'loadNearbyPostsUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$loadNearbyPostsUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LoadNearbyPostsUseCaseRef
    = AutoDisposeProviderRef<LoadNearbyPostsUseCase>;
String _$loadPostsByGenresUseCaseHash() =>
    r'e8b6dd465a6e3e1603268068e62d3e1f1f5da71b';

/// Provider para LoadPostsByGenresUseCase
///
/// Copied from [loadPostsByGenresUseCase].
@ProviderFor(loadPostsByGenresUseCase)
final loadPostsByGenresUseCaseProvider =
    AutoDisposeProvider<LoadPostsByGenresUseCase>.internal(
  loadPostsByGenresUseCase,
  name: r'loadPostsByGenresUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$loadPostsByGenresUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LoadPostsByGenresUseCaseRef
    = AutoDisposeProviderRef<LoadPostsByGenresUseCase>;
String _$searchProfilesUseCaseHash() =>
    r'a8911d5395c1dc73af420d36cf214388745e67be';

/// Provider para SearchProfilesUseCase
///
/// Copied from [searchProfilesUseCase].
@ProviderFor(searchProfilesUseCase)
final searchProfilesUseCaseProvider =
    AutoDisposeProvider<SearchProfilesUseCase>.internal(
  searchProfilesUseCase,
  name: r'searchProfilesUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchProfilesUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchProfilesUseCaseRef
    = AutoDisposeProviderRef<SearchProfilesUseCase>;
String _$nearbyPostsStreamHash() => r'b52293b7e355bc4623ed4c9323a77ce4e577d40b';

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

/// Provider para stream de posts próximos (tempo real)
///
/// Copied from [nearbyPostsStream].
@ProviderFor(nearbyPostsStream)
const nearbyPostsStreamProvider = NearbyPostsStreamFamily();

/// Provider para stream de posts próximos (tempo real)
///
/// Copied from [nearbyPostsStream].
class NearbyPostsStreamFamily extends Family<AsyncValue<List<PostEntity>>> {
  /// Provider para stream de posts próximos (tempo real)
  ///
  /// Copied from [nearbyPostsStream].
  const NearbyPostsStreamFamily();

  /// Provider para stream de posts próximos (tempo real)
  ///
  /// Copied from [nearbyPostsStream].
  NearbyPostsStreamProvider call(
    Map<String, double> params,
  ) {
    return NearbyPostsStreamProvider(
      params,
    );
  }

  @override
  NearbyPostsStreamProvider getProviderOverride(
    covariant NearbyPostsStreamProvider provider,
  ) {
    return call(
      provider.params,
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
  String? get name => r'nearbyPostsStreamProvider';
}

/// Provider para stream de posts próximos (tempo real)
///
/// Copied from [nearbyPostsStream].
class NearbyPostsStreamProvider
    extends AutoDisposeStreamProvider<List<PostEntity>> {
  /// Provider para stream de posts próximos (tempo real)
  ///
  /// Copied from [nearbyPostsStream].
  NearbyPostsStreamProvider(
    Map<String, double> params,
  ) : this._internal(
          (ref) => nearbyPostsStream(
            ref as NearbyPostsStreamRef,
            params,
          ),
          from: nearbyPostsStreamProvider,
          name: r'nearbyPostsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$nearbyPostsStreamHash,
          dependencies: NearbyPostsStreamFamily._dependencies,
          allTransitiveDependencies:
              NearbyPostsStreamFamily._allTransitiveDependencies,
          params: params,
        );

  NearbyPostsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final Map<String, double> params;

  @override
  Override overrideWith(
    Stream<List<PostEntity>> Function(NearbyPostsStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NearbyPostsStreamProvider._internal(
        (ref) => create(ref as NearbyPostsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<PostEntity>> createElement() {
    return _NearbyPostsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NearbyPostsStreamProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NearbyPostsStreamRef on AutoDisposeStreamProviderRef<List<PostEntity>> {
  /// The parameter `params` of this provider.
  Map<String, double> get params;
}

class _NearbyPostsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<PostEntity>>
    with NearbyPostsStreamRef {
  _NearbyPostsStreamProviderElement(super.provider);

  @override
  Map<String, double> get params =>
      (origin as NearbyPostsStreamProvider).params;
}

String _$feedNotifierHash() => r'22815cc7b7bf72f9888a0df4655222fcde6ab7ff';

/// Notifier para gerenciar feed de posts
///
/// Copied from [FeedNotifier].
@ProviderFor(FeedNotifier)
final feedNotifierProvider =
    AutoDisposeNotifierProvider<FeedNotifier, FeedState>.internal(
  FeedNotifier.new,
  name: r'feedNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$feedNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FeedNotifier = AutoDisposeNotifier<FeedState>;
String _$profileSearchNotifierHash() =>
    r'4f2b8672b4088fc9ea47fee6a150b9db886e5e06';

/// Notifier para busca de perfis
///
/// Copied from [ProfileSearchNotifier].
@ProviderFor(ProfileSearchNotifier)
final profileSearchNotifierProvider = AutoDisposeNotifierProvider<
    ProfileSearchNotifier, ProfileSearchState>.internal(
  ProfileSearchNotifier.new,
  name: r'profileSearchNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileSearchNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProfileSearchNotifier = AutoDisposeNotifier<ProfileSearchState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
