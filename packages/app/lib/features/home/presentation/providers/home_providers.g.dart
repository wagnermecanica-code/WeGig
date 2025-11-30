// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider para Firestore instance

@ProviderFor(firestore)
const firestoreProvider = FirestoreProvider._();

/// Provider para Firestore instance

final class FirestoreProvider extends $FunctionalProvider<FirebaseFirestore,
    FirebaseFirestore, FirebaseFirestore> with $Provider<FirebaseFirestore> {
  /// Provider para Firestore instance
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

/// Provider para HomeRepository

@ProviderFor(homeRepository)
const homeRepositoryProvider = HomeRepositoryProvider._();

/// Provider para HomeRepository

final class HomeRepositoryProvider
    extends $FunctionalProvider<HomeRepository, HomeRepository, HomeRepository>
    with $Provider<HomeRepository> {
  /// Provider para HomeRepository
  const HomeRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'homeRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$homeRepositoryHash();

  @$internal
  @override
  $ProviderElement<HomeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeRepository create(Ref ref) {
    return homeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeRepository>(value),
    );
  }
}

String _$homeRepositoryHash() => r'e2b1d9425cd593208e613be25196279851582810';

/// Provider para LoadNearbyPostsUseCase

@ProviderFor(loadNearbyPostsUseCase)
const loadNearbyPostsUseCaseProvider = LoadNearbyPostsUseCaseProvider._();

/// Provider para LoadNearbyPostsUseCase

final class LoadNearbyPostsUseCaseProvider extends $FunctionalProvider<
    LoadNearbyPostsUseCase,
    LoadNearbyPostsUseCase,
    LoadNearbyPostsUseCase> with $Provider<LoadNearbyPostsUseCase> {
  /// Provider para LoadNearbyPostsUseCase
  const LoadNearbyPostsUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'loadNearbyPostsUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$loadNearbyPostsUseCaseHash();

  @$internal
  @override
  $ProviderElement<LoadNearbyPostsUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoadNearbyPostsUseCase create(Ref ref) {
    return loadNearbyPostsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoadNearbyPostsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoadNearbyPostsUseCase>(value),
    );
  }
}

String _$loadNearbyPostsUseCaseHash() =>
    r'73a90db092687e9d3c51a5830aa72abbf8aeaca6';

/// Provider para LoadPostsByGenresUseCase

@ProviderFor(loadPostsByGenresUseCase)
const loadPostsByGenresUseCaseProvider = LoadPostsByGenresUseCaseProvider._();

/// Provider para LoadPostsByGenresUseCase

final class LoadPostsByGenresUseCaseProvider extends $FunctionalProvider<
    LoadPostsByGenresUseCase,
    LoadPostsByGenresUseCase,
    LoadPostsByGenresUseCase> with $Provider<LoadPostsByGenresUseCase> {
  /// Provider para LoadPostsByGenresUseCase
  const LoadPostsByGenresUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'loadPostsByGenresUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$loadPostsByGenresUseCaseHash();

  @$internal
  @override
  $ProviderElement<LoadPostsByGenresUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoadPostsByGenresUseCase create(Ref ref) {
    return loadPostsByGenresUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoadPostsByGenresUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoadPostsByGenresUseCase>(value),
    );
  }
}

String _$loadPostsByGenresUseCaseHash() =>
    r'0f0304ffd559db61cf9792360350a0bc55e6b009';

/// Provider para SearchProfilesUseCase

@ProviderFor(searchProfilesUseCase)
const searchProfilesUseCaseProvider = SearchProfilesUseCaseProvider._();

/// Provider para SearchProfilesUseCase

final class SearchProfilesUseCaseProvider extends $FunctionalProvider<
    SearchProfilesUseCase,
    SearchProfilesUseCase,
    SearchProfilesUseCase> with $Provider<SearchProfilesUseCase> {
  /// Provider para SearchProfilesUseCase
  const SearchProfilesUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'searchProfilesUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$searchProfilesUseCaseHash();

  @$internal
  @override
  $ProviderElement<SearchProfilesUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SearchProfilesUseCase create(Ref ref) {
    return searchProfilesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchProfilesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchProfilesUseCase>(value),
    );
  }
}

String _$searchProfilesUseCaseHash() =>
    r'cf7ff4dfd9ec87b443e220ef33cf2154470ea246';

/// Provider para stream de posts próximos (tempo real)

@ProviderFor(nearbyPostsStream)
const nearbyPostsStreamProvider = NearbyPostsStreamFamily._();

/// Provider para stream de posts próximos (tempo real)

final class NearbyPostsStreamProvider extends $FunctionalProvider<
        AsyncValue<List<PostEntity>>,
        List<PostEntity>,
        Stream<List<PostEntity>>>
    with $FutureModifier<List<PostEntity>>, $StreamProvider<List<PostEntity>> {
  /// Provider para stream de posts próximos (tempo real)
  const NearbyPostsStreamProvider._(
      {required NearbyPostsStreamFamily super.from,
      required Map<String, double> super.argument})
      : super(
          retry: null,
          name: r'nearbyPostsStreamProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$nearbyPostsStreamHash();

  @override
  String toString() {
    return r'nearbyPostsStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<PostEntity>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<PostEntity>> create(Ref ref) {
    final argument = this.argument as Map<String, double>;
    return nearbyPostsStream(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NearbyPostsStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nearbyPostsStreamHash() => r'692aea45931febb23eb8bb0cc2fcf73f3ac9a654';

/// Provider para stream de posts próximos (tempo real)

final class NearbyPostsStreamFamily extends $Family
    with
        $FunctionalFamilyOverride<Stream<List<PostEntity>>,
            Map<String, double>> {
  const NearbyPostsStreamFamily._()
      : super(
          retry: null,
          name: r'nearbyPostsStreamProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Provider para stream de posts próximos (tempo real)

  NearbyPostsStreamProvider call(
    Map<String, double> params,
  ) =>
      NearbyPostsStreamProvider._(argument: params, from: this);

  @override
  String toString() => r'nearbyPostsStreamProvider';
}
