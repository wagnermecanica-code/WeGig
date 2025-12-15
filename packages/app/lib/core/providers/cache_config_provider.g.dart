// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postCacheTTLHash() => r'9e7e3ddf18e76fa585b2e740bc6d5a878c5e86bc';

/// Provider de conveniência para acessar TTLs específicos
///
/// Copied from [postCacheTTL].
@ProviderFor(postCacheTTL)
final postCacheTTLProvider = AutoDisposeProvider<Duration>.internal(
  postCacheTTL,
  name: r'postCacheTTLProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$postCacheTTLHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PostCacheTTLRef = AutoDisposeProviderRef<Duration>;
String _$profileCacheTTLHash() => r'9954cfdd3beb61182b9fbb1edf44d5ecda12cf92';

/// See also [profileCacheTTL].
@ProviderFor(profileCacheTTL)
final profileCacheTTLProvider = AutoDisposeProvider<Duration>.internal(
  profileCacheTTL,
  name: r'profileCacheTTLProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileCacheTTLHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileCacheTTLRef = AutoDisposeProviderRef<Duration>;
String _$notificationCacheTTLHash() =>
    r'45905e7b798d8f913de569fa819fe6c4f72af8ff';

/// See also [notificationCacheTTL].
@ProviderFor(notificationCacheTTL)
final notificationCacheTTLProvider = AutoDisposeProvider<Duration>.internal(
  notificationCacheTTL,
  name: r'notificationCacheTTLProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationCacheTTLHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationCacheTTLRef = AutoDisposeProviderRef<Duration>;
String _$messageCacheTTLHash() => r'b13d05552b4562a5d1384479bc3ffa27fba2393f';

/// See also [messageCacheTTL].
@ProviderFor(messageCacheTTL)
final messageCacheTTLProvider = AutoDisposeProvider<Duration>.internal(
  messageCacheTTL,
  name: r'messageCacheTTLProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messageCacheTTLHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MessageCacheTTLRef = AutoDisposeProviderRef<Duration>;
String _$cacheConfigNotifierHash() =>
    r'927848aed28a221e885bc470f98cb0867bd98bee';

/// Provider de configuração de cache
///
/// Carrega configurações do SharedPreferences e permite
/// modificações em runtime.
///
/// Copied from [CacheConfigNotifier].
@ProviderFor(CacheConfigNotifier)
final cacheConfigNotifierProvider =
    NotifierProvider<CacheConfigNotifier, CacheConfig>.internal(
  CacheConfigNotifier.new,
  name: r'cacheConfigNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cacheConfigNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CacheConfigNotifier = Notifier<CacheConfig>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
