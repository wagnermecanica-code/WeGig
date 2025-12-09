// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isOnlineHash() => r'872cae55426cbdc5527472c4b4a8706a9dbc81c9';

/// Provider de conveniência para verificar se está online
///
/// Copied from [isOnline].
@ProviderFor(isOnline)
final isOnlineProvider = AutoDisposeProvider<bool>.internal(
  isOnline,
  name: r'isOnlineProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isOnlineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsOnlineRef = AutoDisposeProviderRef<bool>;
String _$isOfflineHash() => r'8a50a29444535493b1b9986391e1d5aa8f9142bd';

/// Provider de conveniência para verificar se está offline
///
/// Copied from [isOffline].
@ProviderFor(isOffline)
final isOfflineProvider = AutoDisposeProvider<bool>.internal(
  isOffline,
  name: r'isOfflineProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isOfflineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsOfflineRef = AutoDisposeProviderRef<bool>;
String _$shouldSaveDataHash() => r'b386863c51142b6bff0a1dc9a396a91947996487';

/// Provider que retorna true se deve economizar dados (mobile ou offline)
///
/// Copied from [shouldSaveData].
@ProviderFor(shouldSaveData)
final shouldSaveDataProvider = AutoDisposeProvider<bool>.internal(
  shouldSaveData,
  name: r'shouldSaveDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shouldSaveDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShouldSaveDataRef = AutoDisposeProviderRef<bool>;
String _$connectivityNotifierHash() =>
    r'f085c41143c8de72a5463ea2cf97b7ed183d930a';

/// Provider de conectividade para gerenciar estado de rede
///
/// Funcionalidades:
/// - Monitoramento em tempo real de conexão
/// - Diferenciação WiFi/Mobile/Offline
/// - Callbacks para mudanças de estado
/// - Integração com cache (modo offline)
///
/// Uso:
/// ```dart
/// final connectivity = ref.watch(connectivityNotifierProvider);
/// if (connectivity == ConnectivityStatus.offline) {
///   // Mostrar banner offline
/// }
/// ```
///
/// Copied from [ConnectivityNotifier].
@ProviderFor(ConnectivityNotifier)
final connectivityNotifierProvider =
    NotifierProvider<ConnectivityNotifier, ConnectivityStatus>.internal(
  ConnectivityNotifier.new,
  name: r'connectivityNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectivityNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConnectivityNotifier = Notifier<ConnectivityStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
