// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postRemoteDataSourceHash() =>
    r'0379e0b4988fdbc3bb4c87c0d22ad7910a027204';

/// ============================================
/// DATA LAYER - Dependency Injection
/// ============================================
/// Provider para PostRemoteDataSource (singleton)
///
/// Copied from [postRemoteDataSource].
@ProviderFor(postRemoteDataSource)
final postRemoteDataSourceProvider =
    AutoDisposeProvider<IPostRemoteDataSource>.internal(
  postRemoteDataSource,
  name: r'postRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PostRemoteDataSourceRef = AutoDisposeProviderRef<IPostRemoteDataSource>;
String _$postRepositoryNewHash() => r'194a50534da1a3b49dbbf8d418b6831cfb983d81';

/// Provider para PostRepository (singleton)
///
/// Copied from [postRepositoryNew].
@ProviderFor(postRepositoryNew)
final postRepositoryNewProvider = AutoDisposeProvider<PostRepository>.internal(
  postRepositoryNew,
  name: r'postRepositoryNewProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postRepositoryNewHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PostRepositoryNewRef = AutoDisposeProviderRef<PostRepository>;
String _$createPostUseCaseHash() => r'e9b8dfdb44eea8e5cce9ec559a3edfe5d9babb52';

/// ============================================
/// USE CASE LAYER - Dependency Injection
/// ============================================
/// Provider para CreatePost use case
///
/// Copied from [createPostUseCase].
@ProviderFor(createPostUseCase)
final createPostUseCaseProvider = AutoDisposeProvider<CreatePost>.internal(
  createPostUseCase,
  name: r'createPostUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$createPostUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CreatePostUseCaseRef = AutoDisposeProviderRef<CreatePost>;
String _$updatePostUseCaseHash() => r'98f7a2b38ad24c5d0955b01e02168a976d9d2c37';

/// Provider para UpdatePost use case
///
/// Copied from [updatePostUseCase].
@ProviderFor(updatePostUseCase)
final updatePostUseCaseProvider = AutoDisposeProvider<UpdatePost>.internal(
  updatePostUseCase,
  name: r'updatePostUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$updatePostUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UpdatePostUseCaseRef = AutoDisposeProviderRef<UpdatePost>;
String _$deletePostUseCaseHash() => r'b633ae3a3feb730c3177be8ab32620daf0fdbd1f';

/// Provider para DeletePost use case
///
/// Copied from [deletePostUseCase].
@ProviderFor(deletePostUseCase)
final deletePostUseCaseProvider = AutoDisposeProvider<DeletePost>.internal(
  deletePostUseCase,
  name: r'deletePostUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deletePostUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeletePostUseCaseRef = AutoDisposeProviderRef<DeletePost>;
String _$toggleInterestUseCaseHash() =>
    r'71cfdea3688a5a03ba5f7a0fd72e2d88873d6af5';

/// Provider para ToggleInterest use case
///
/// Copied from [toggleInterestUseCase].
@ProviderFor(toggleInterestUseCase)
final toggleInterestUseCaseProvider =
    AutoDisposeProvider<ToggleInterest>.internal(
  toggleInterestUseCase,
  name: r'toggleInterestUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$toggleInterestUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ToggleInterestUseCaseRef = AutoDisposeProviderRef<ToggleInterest>;
String _$loadInterestedUsersUseCaseHash() =>
    r'c0e86387876da18d9df64b02bab5c729c7482eab';

/// Provider para LoadInterestedUsers use case
///
/// Copied from [loadInterestedUsersUseCase].
@ProviderFor(loadInterestedUsersUseCase)
final loadInterestedUsersUseCaseProvider =
    AutoDisposeProvider<LoadInterestedUsers>.internal(
  loadInterestedUsersUseCase,
  name: r'loadInterestedUsersUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$loadInterestedUsersUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LoadInterestedUsersUseCaseRef
    = AutoDisposeProviderRef<LoadInterestedUsers>;
String _$postListHash() => r'eda1aa9402b468e1925dc99af5ebf923035e5e33';

/// ============================================
/// GLOBAL PROVIDERS
/// ============================================
/// Helper provider to get just the posts list
///
/// Copied from [postList].
@ProviderFor(postList)
final postListProvider = AutoDisposeProvider<List<PostEntity>>.internal(
  postList,
  name: r'postListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$postListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PostListRef = AutoDisposeProviderRef<List<PostEntity>>;
String _$postNotifierHash() => r'beb8cd88ffbc7a14df22baba583e96c7427b5b49';

/// PostNotifier - Gerencia estado de posts com Clean Architecture
///
/// Responsável por:
/// - Carregar posts do usuário/perfil
/// - Criar, atualizar e deletar posts
/// - Toggle de interesse (like)
/// - Carregar lista de perfis interessados
/// - Refresh manual (pull-to-refresh)
///
/// Copied from [PostNotifier].
@ProviderFor(PostNotifier)
final postNotifierProvider =
    AutoDisposeAsyncNotifierProvider<PostNotifier, PostState>.internal(
  PostNotifier.new,
  name: r'postNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$postNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PostNotifier = AutoDisposeAsyncNotifier<PostState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
