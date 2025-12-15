// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gps_cache_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentPositionHash() => r'de8017a0182317e8ca55c79e17d40d2b3204053b';

/// Provider de conveniência para posição atual
///
/// Copied from [currentPosition].
@ProviderFor(currentPosition)
final currentPositionProvider = AutoDisposeProvider<LatLng>.internal(
  currentPosition,
  name: r'currentPositionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentPositionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentPositionRef = AutoDisposeProviderRef<LatLng>;
String _$hasRealPositionHash() => r'0333d8fc22d1de01607ee9c4f784ef3ad1479679';

/// Provider de conveniência para verificar se tem posição real
///
/// Copied from [hasRealPosition].
@ProviderFor(hasRealPosition)
final hasRealPositionProvider = AutoDisposeProvider<bool>.internal(
  hasRealPosition,
  name: r'hasRealPositionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasRealPositionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasRealPositionRef = AutoDisposeProviderRef<bool>;
String _$gpsCacheNotifierHash() => r'b0223ffd87bdb7479e1e25f77030e41215f2154a';

/// Provider de localização GPS com cache inteligente
///
/// Funcionalidades:
/// - Cache persistente com TTL de 24h
/// - Fallback para posição padrão (São Paulo)
/// - Refresh automático quando cache expira
/// - Integração com CacheConfigNotifier
///
/// Uso:
/// ```dart
/// final gps = ref.watch(gpsCacheNotifierProvider);
/// final position = gps.position;
/// ```
///
/// Copied from [GpsCacheNotifier].
@ProviderFor(GpsCacheNotifier)
final gpsCacheNotifierProvider =
    NotifierProvider<GpsCacheNotifier, GpsState>.internal(
  GpsCacheNotifier.new,
  name: r'gpsCacheNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$gpsCacheNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GpsCacheNotifier = Notifier<GpsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
