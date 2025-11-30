// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ============================================
/// DATA LAYER - Dependency Injection
/// ============================================
/// Provider para ProfileRemoteDataSource (singleton)

@ProviderFor(profileRemoteDataSource)
const profileRemoteDataSourceProvider = ProfileRemoteDataSourceProvider._();

/// ============================================
/// DATA LAYER - Dependency Injection
/// ============================================
/// Provider para ProfileRemoteDataSource (singleton)

final class ProfileRemoteDataSourceProvider extends $FunctionalProvider<
    ProfileRemoteDataSource,
    ProfileRemoteDataSource,
    ProfileRemoteDataSource> with $Provider<ProfileRemoteDataSource> {
  /// ============================================
  /// DATA LAYER - Dependency Injection
  /// ============================================
  /// Provider para ProfileRemoteDataSource (singleton)
  const ProfileRemoteDataSourceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'profileRemoteDataSourceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$profileRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ProfileRemoteDataSource> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProfileRemoteDataSource create(Ref ref) {
    return profileRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRemoteDataSource>(value),
    );
  }
}

String _$profileRemoteDataSourceHash() =>
    r'e4c1c1887a1b6a88fcdd478fced427961e477780';

/// Provider para ProfileRepository (singleton)

@ProviderFor(profileRepositoryNew)
const profileRepositoryNewProvider = ProfileRepositoryNewProvider._();

/// Provider para ProfileRepository (singleton)

final class ProfileRepositoryNewProvider extends $FunctionalProvider<
    ProfileRepository,
    ProfileRepository,
    ProfileRepository> with $Provider<ProfileRepository> {
  /// Provider para ProfileRepository (singleton)
  const ProfileRepositoryNewProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'profileRepositoryNewProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryNewHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepositoryNew(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$profileRepositoryNewHash() =>
    r'9e5a7c4bbb321038e343fddc9e9857dfba1d7047';

/// ============================================
/// DOMAIN LAYER - UseCases
/// ============================================

@ProviderFor(createProfileUseCase)
const createProfileUseCaseProvider = CreateProfileUseCaseProvider._();

/// ============================================
/// DOMAIN LAYER - UseCases
/// ============================================

final class CreateProfileUseCaseProvider extends $FunctionalProvider<
    CreateProfileUseCase,
    CreateProfileUseCase,
    CreateProfileUseCase> with $Provider<CreateProfileUseCase> {
  /// ============================================
  /// DOMAIN LAYER - UseCases
  /// ============================================
  const CreateProfileUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'createProfileUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$createProfileUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreateProfileUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CreateProfileUseCase create(Ref ref) {
    return createProfileUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateProfileUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateProfileUseCase>(value),
    );
  }
}

String _$createProfileUseCaseHash() =>
    r'ce015ce02f586d93ebaf6992cb6d2e2aad6067df';

@ProviderFor(updateProfileUseCase)
const updateProfileUseCaseProvider = UpdateProfileUseCaseProvider._();

final class UpdateProfileUseCaseProvider extends $FunctionalProvider<
    UpdateProfileUseCase,
    UpdateProfileUseCase,
    UpdateProfileUseCase> with $Provider<UpdateProfileUseCase> {
  const UpdateProfileUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'updateProfileUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$updateProfileUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdateProfileUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdateProfileUseCase create(Ref ref) {
    return updateProfileUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateProfileUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateProfileUseCase>(value),
    );
  }
}

String _$updateProfileUseCaseHash() =>
    r'e61021ff937f5c15ad514ff253d1e289324d068b';

@ProviderFor(switchActiveProfileUseCase)
const switchActiveProfileUseCaseProvider =
    SwitchActiveProfileUseCaseProvider._();

final class SwitchActiveProfileUseCaseProvider extends $FunctionalProvider<
    SwitchActiveProfileUseCase,
    SwitchActiveProfileUseCase,
    SwitchActiveProfileUseCase> with $Provider<SwitchActiveProfileUseCase> {
  const SwitchActiveProfileUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'switchActiveProfileUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$switchActiveProfileUseCaseHash();

  @$internal
  @override
  $ProviderElement<SwitchActiveProfileUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SwitchActiveProfileUseCase create(Ref ref) {
    return switchActiveProfileUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SwitchActiveProfileUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SwitchActiveProfileUseCase>(value),
    );
  }
}

String _$switchActiveProfileUseCaseHash() =>
    r'990e2a78c015a48f4f99ada5a123e81fbc60ab5a';

@ProviderFor(deleteProfileUseCase)
const deleteProfileUseCaseProvider = DeleteProfileUseCaseProvider._();

final class DeleteProfileUseCaseProvider extends $FunctionalProvider<
    DeleteProfileUseCase,
    DeleteProfileUseCase,
    DeleteProfileUseCase> with $Provider<DeleteProfileUseCase> {
  const DeleteProfileUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'deleteProfileUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$deleteProfileUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteProfileUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeleteProfileUseCase create(Ref ref) {
    return deleteProfileUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteProfileUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteProfileUseCase>(value),
    );
  }
}

String _$deleteProfileUseCaseHash() =>
    r'e9e5de22025ca5db4e2f2e0268e1d07940b42ed3';

@ProviderFor(loadAllProfilesUseCase)
const loadAllProfilesUseCaseProvider = LoadAllProfilesUseCaseProvider._();

final class LoadAllProfilesUseCaseProvider extends $FunctionalProvider<
    LoadAllProfilesUseCase,
    LoadAllProfilesUseCase,
    LoadAllProfilesUseCase> with $Provider<LoadAllProfilesUseCase> {
  const LoadAllProfilesUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'loadAllProfilesUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$loadAllProfilesUseCaseHash();

  @$internal
  @override
  $ProviderElement<LoadAllProfilesUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoadAllProfilesUseCase create(Ref ref) {
    return loadAllProfilesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoadAllProfilesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoadAllProfilesUseCase>(value),
    );
  }
}

String _$loadAllProfilesUseCaseHash() =>
    r'98b5059f11855957f2cf8496822fa920bbd61317';

@ProviderFor(getActiveProfileUseCase)
const getActiveProfileUseCaseProvider = GetActiveProfileUseCaseProvider._();

final class GetActiveProfileUseCaseProvider extends $FunctionalProvider<
    GetActiveProfileUseCase,
    GetActiveProfileUseCase,
    GetActiveProfileUseCase> with $Provider<GetActiveProfileUseCase> {
  const GetActiveProfileUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getActiveProfileUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getActiveProfileUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetActiveProfileUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetActiveProfileUseCase create(Ref ref) {
    return getActiveProfileUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetActiveProfileUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetActiveProfileUseCase>(value),
    );
  }
}

String _$getActiveProfileUseCaseHash() =>
    r'537a360364d14144adcaa3ebdb0adec79cc6f04f';

/// Provider para perfil ativo atual (null-safe)

@ProviderFor(activeProfile)
const activeProfileProvider = ActiveProfileProvider._();

/// Provider para perfil ativo atual (null-safe)

final class ActiveProfileProvider
    extends $FunctionalProvider<ProfileEntity?, ProfileEntity?, ProfileEntity?>
    with $Provider<ProfileEntity?> {
  /// Provider para perfil ativo atual (null-safe)
  const ActiveProfileProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'activeProfileProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$activeProfileHash();

  @$internal
  @override
  $ProviderElement<ProfileEntity?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProfileEntity? create(Ref ref) {
    return activeProfile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileEntity? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileEntity?>(value),
    );
  }
}

String _$activeProfileHash() => r'f3c8fdc00d234d8a3f1cbf15794870570509b04d';

/// Provider para lista de perfis

@ProviderFor(profileList)
const profileListProvider = ProfileListProvider._();

/// Provider para lista de perfis

final class ProfileListProvider extends $FunctionalProvider<
    List<ProfileEntity>,
    List<ProfileEntity>,
    List<ProfileEntity>> with $Provider<List<ProfileEntity>> {
  /// Provider para lista de perfis
  const ProfileListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'profileListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$profileListHash();

  @$internal
  @override
  $ProviderElement<List<ProfileEntity>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<ProfileEntity> create(Ref ref) {
    return profileList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ProfileEntity> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ProfileEntity>>(value),
    );
  }
}

String _$profileListHash() => r'a0fb8f617871092926b3e7455402dac1c67eed1c';

/// Provider para verificar se tem múltiplos perfis

@ProviderFor(hasMultipleProfiles)
const hasMultipleProfilesProvider = HasMultipleProfilesProvider._();

/// Provider para verificar se tem múltiplos perfis

final class HasMultipleProfilesProvider
    extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  /// Provider para verificar se tem múltiplos perfis
  const HasMultipleProfilesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'hasMultipleProfilesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$hasMultipleProfilesHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasMultipleProfiles(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasMultipleProfilesHash() =>
    r'781a311f71ab4b0335f3a02ac1fbac29cc0d9b37';

/// Provider para stream de mudanças de perfil

@ProviderFor(profileStream)
const profileStreamProvider = ProfileStreamProvider._();

/// Provider para stream de mudanças de perfil

final class ProfileStreamProvider extends $FunctionalProvider<
        AsyncValue<ProfileState>, ProfileState, Stream<ProfileState>>
    with $FutureModifier<ProfileState>, $StreamProvider<ProfileState> {
  /// Provider para stream de mudanças de perfil
  const ProfileStreamProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'profileStreamProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$profileStreamHash();

  @$internal
  @override
  $StreamProviderElement<ProfileState> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<ProfileState> create(Ref ref) {
    return profileStream(ref);
  }
}

String _$profileStreamHash() => r'bf7505b4b47cb7eb48efdad9fcce172fedd23ebc';
