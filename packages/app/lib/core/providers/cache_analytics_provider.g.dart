// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_analytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cacheHitRateHash() => r'8f8ecab289bde6c8c016603f3cb77a72d8785fa6';

/// Provider de conveniência para taxa de acerto
///
/// Copied from [cacheHitRate].
@ProviderFor(cacheHitRate)
final cacheHitRateProvider = AutoDisposeProvider<double>.internal(
  cacheHitRate,
  name: r'cacheHitRateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cacheHitRateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CacheHitRateRef = AutoDisposeProviderRef<double>;
String _$cacheHitRateFormattedHash() =>
    r'ac9ef82c63cb645feebfc960b32ae515fbe887fa';

/// Provider de conveniência para taxa de acerto formatada
///
/// Copied from [cacheHitRateFormatted].
@ProviderFor(cacheHitRateFormatted)
final cacheHitRateFormattedProvider = AutoDisposeProvider<String>.internal(
  cacheHitRateFormatted,
  name: r'cacheHitRateFormattedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cacheHitRateFormattedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CacheHitRateFormattedRef = AutoDisposeProviderRef<String>;
String _$cacheAnalyticsNotifierHash() =>
    r'a2ee69b4501c1b4e1b7ab87e1741d57ebdd19fa6';

/// Provider de métricas de cache para Analytics
///
/// Funcionalidades:
/// - Contagem de cache hits/misses
/// - Cálculo de taxa de acerto
/// - Envio periódico para Firebase Analytics
/// - Métricas por tipo de cache
///
/// Uso:
/// ```dart
/// // Registrar hit
/// ref.read(cacheAnalyticsNotifierProvider.notifier).recordHit(CacheType.post);
///
/// // Registrar miss
/// ref.read(cacheAnalyticsNotifierProvider.notifier).recordMiss(CacheType.post);
/// ```
///
/// Copied from [CacheAnalyticsNotifier].
@ProviderFor(CacheAnalyticsNotifier)
final cacheAnalyticsNotifierProvider =
    NotifierProvider<CacheAnalyticsNotifier, CacheMetrics>.internal(
  CacheAnalyticsNotifier.new,
  name: r'cacheAnalyticsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cacheAnalyticsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CacheAnalyticsNotifier = Notifier<CacheMetrics>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
