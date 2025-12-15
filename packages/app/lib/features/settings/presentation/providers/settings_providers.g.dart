// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

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
String _$settingsRemoteDataSourceHash() =>
    r'4adee5d42ad8fe62f8485df7be72a6099fe8168c';

/// Provider para SettingsRemoteDataSource
///
/// Copied from [settingsRemoteDataSource].
@ProviderFor(settingsRemoteDataSource)
final settingsRemoteDataSourceProvider =
    AutoDisposeProvider<ISettingsRemoteDataSource>.internal(
  settingsRemoteDataSource,
  name: r'settingsRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SettingsRemoteDataSourceRef
    = AutoDisposeProviderRef<ISettingsRemoteDataSource>;
String _$settingsRepositoryHash() =>
    r'a43a4a275e525f4ba58780271146c9b427ed0237';

/// Provider para SettingsRepository
///
/// Copied from [settingsRepository].
@ProviderFor(settingsRepository)
final settingsRepositoryProvider =
    AutoDisposeProvider<SettingsRepository>.internal(
  settingsRepository,
  name: r'settingsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SettingsRepositoryRef = AutoDisposeProviderRef<SettingsRepository>;
String _$userSettingsHash() => r'0bdfd043b83718fa73cbb1b5b544c0e43688b1cd';

/// Provider for user settings with AsyncNotifier
///
/// Copied from [UserSettings].
@ProviderFor(UserSettings)
final userSettingsProvider = AutoDisposeAsyncNotifierProvider<UserSettings,
    UserSettingsEntity?>.internal(
  UserSettings.new,
  name: r'userSettingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userSettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserSettings = AutoDisposeAsyncNotifier<UserSettingsEntity?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
