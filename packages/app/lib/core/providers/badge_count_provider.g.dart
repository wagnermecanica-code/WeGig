// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge_count_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$totalBadgeCountHash() => r'2de9d404529e6424597b2b6c2ded384b7b141529';

/// Provider de conveniência para total de badges
///
/// Copied from [totalBadgeCount].
@ProviderFor(totalBadgeCount)
final totalBadgeCountProvider = AutoDisposeProvider<int>.internal(
  totalBadgeCount,
  name: r'totalBadgeCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalBadgeCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalBadgeCountRef = AutoDisposeProviderRef<int>;
String _$unreadNotificationsCountHash() =>
    r'1841c22b0d2ee716dacf40c18b3f91e4449b7b4d';

/// Provider de conveniência para notificações não lidas
///
/// Copied from [unreadNotificationsCount].
@ProviderFor(unreadNotificationsCount)
final unreadNotificationsCountProvider = AutoDisposeProvider<int>.internal(
  unreadNotificationsCount,
  name: r'unreadNotificationsCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadNotificationsCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadNotificationsCountRef = AutoDisposeProviderRef<int>;
String _$unreadMessagesCountHash() =>
    r'3fa4da6aa2899c4644c175d19dbcf68f1c9d2df0';

/// Provider de conveniência para mensagens não lidas
///
/// Copied from [unreadMessagesCount].
@ProviderFor(unreadMessagesCount)
final unreadMessagesCountProvider = AutoDisposeProvider<int>.internal(
  unreadMessagesCount,
  name: r'unreadMessagesCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadMessagesCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadMessagesCountRef = AutoDisposeProviderRef<int>;
String _$hasBadgesHash() => r'6bb6d79e7a3d3ff33e43f09815343c796e7eac66';

/// Provider que indica se há badges para mostrar
///
/// Copied from [hasBadges].
@ProviderFor(hasBadges)
final hasBadgesProvider = AutoDisposeProvider<bool>.internal(
  hasBadges,
  name: r'hasBadgesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$hasBadgesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasBadgesRef = AutoDisposeProviderRef<bool>;
String _$badgeCountNotifierHash() =>
    r'c8e326d64503366677fbff4f6e5f2d071c310cbf';

/// Provider de contagem de badges com invalidação automática
///
/// Funcionalidades:
/// - Contagem de notificações não lidas
/// - Contagem de mensagens não lidas
/// - Invalidação automática ao trocar perfil
/// - Cache com TTL de 30 segundos
/// - Streams do Firestore para atualizações em tempo real
///
/// Uso:
/// ```dart
/// final badges = ref.watch(badgeCountNotifierProvider);
/// if (badges.hasAny) {
///   // Mostrar badge no ícone
/// }
/// ```
///
/// Copied from [BadgeCountNotifier].
@ProviderFor(BadgeCountNotifier)
final badgeCountNotifierProvider =
    NotifierProvider<BadgeCountNotifier, BadgeCounts>.internal(
  BadgeCountNotifier.new,
  name: r'badgeCountNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$badgeCountNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BadgeCountNotifier = Notifier<BadgeCounts>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
