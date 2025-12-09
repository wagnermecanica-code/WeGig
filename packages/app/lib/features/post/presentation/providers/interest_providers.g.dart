// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interest_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$interestNotifierHash() => r'1833a919ef2561e9e0ba8c66fd397bd9709fd2f3';

/// Provider global que gerencia o estado de interesses (posts salvos/curtidos)
/// Sincroniza entre HomePage, PostDetailPage e ViewProfilePage
///
/// Copied from [InterestNotifier].
@ProviderFor(InterestNotifier)
final interestNotifierProvider =
    AutoDisposeNotifierProvider<InterestNotifier, Set<String>>.internal(
  InterestNotifier.new,
  name: r'interestNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$interestNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$InterestNotifier = AutoDisposeNotifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
