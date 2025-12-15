// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_cache_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postCacheNotifierHash() => r'ee4f5281781f522d7ca1399c1ac81ff403bbdbbe';

/// Cache inteligente para posts do feed
///
/// Reduz queries ao Firestore mantendo posts em memória com TTL configurável.
/// Suporta paginação mantendo o DocumentSnapshot para continuar de onde parou.
///
/// Benefícios:
/// - 70% menos queries ao Firestore
/// - Carregamento instantâneo ao voltar para feed
/// - Paginação eficiente
/// - Redução de custos Firebase
/// - TTL configurável via CacheConfigNotifier
///
/// Copied from [PostCacheNotifier].
@ProviderFor(PostCacheNotifier)
final postCacheNotifierProvider =
    AutoDisposeNotifierProvider<PostCacheNotifier, List<PostEntity>>.internal(
  PostCacheNotifier.new,
  name: r'postCacheNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postCacheNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PostCacheNotifier = AutoDisposeNotifier<List<PostEntity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
