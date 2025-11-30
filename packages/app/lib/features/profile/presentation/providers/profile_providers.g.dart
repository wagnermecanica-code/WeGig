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
    r'f1abd6607c606939e3a5f9dafd53e7ae8de41419';

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
    r'b585f2c7f37ca445c0255d375ae375342f9dbd93';

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
    r'3104bd8a055cbbe28496ee89afa9cfc64f28f7e4';

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
    r'935e2841094c237656457ed8670949c9cb2865ee';

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
    r'ccf8bbfe30125f5abd8077ad20a11198684dfabe';

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
    r'634dbfb14133227240a68ae934c1c159a11fd802';

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
    r'16a0a839b22827dec43db4fcdbe0e4e38ccde9b7';

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
    r'ff0cd8cefe580986652728d9eb1fdbd1023ab032';

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

String _$activeProfileHash() => r'fc32903c544b43733e9d3f4461b6cd74ff589c64';

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

String _$profileListHash() => r'a196080eb12c5133c03a19ecf282af1b946898b8';

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
    r'd83b0a867e19223d0a76f70fe166d35267b279b6';

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

String _$profileStreamHash() => r'a18f147c861dcdd53086b017b50481321c301581';
