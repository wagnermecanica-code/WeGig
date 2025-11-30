// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ============================================
/// DATA LAYER - Dependency Injection
/// ============================================
/// Provider para PostRemoteDataSource (singleton)

@ProviderFor(postRemoteDataSource)
const postRemoteDataSourceProvider = PostRemoteDataSourceProvider._();

/// ============================================
/// DATA LAYER - Dependency Injection
/// ============================================
/// Provider para PostRemoteDataSource (singleton)

final class PostRemoteDataSourceProvider extends $FunctionalProvider<
    IPostRemoteDataSource,
    IPostRemoteDataSource,
    IPostRemoteDataSource> with $Provider<IPostRemoteDataSource> {
  /// ============================================
  /// DATA LAYER - Dependency Injection
  /// ============================================
  /// Provider para PostRemoteDataSource (singleton)
  const PostRemoteDataSourceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'postRemoteDataSourceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$postRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<IPostRemoteDataSource> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IPostRemoteDataSource create(Ref ref) {
    return postRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IPostRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IPostRemoteDataSource>(value),
    );
  }
}

String _$postRemoteDataSourceHash() =>
    r'0379e0b4988fdbc3bb4c87c0d22ad7910a027204';

/// Provider para PostRepository (singleton)

@ProviderFor(postRepositoryNew)
const postRepositoryNewProvider = PostRepositoryNewProvider._();

/// Provider para PostRepository (singleton)

final class PostRepositoryNewProvider
    extends $FunctionalProvider<PostRepository, PostRepository, PostRepository>
    with $Provider<PostRepository> {
  /// Provider para PostRepository (singleton)
  const PostRepositoryNewProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'postRepositoryNewProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$postRepositoryNewHash();

  @$internal
  @override
  $ProviderElement<PostRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PostRepository create(Ref ref) {
    return postRepositoryNew(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostRepository>(value),
    );
  }
}

String _$postRepositoryNewHash() => r'194a50534da1a3b49dbbf8d418b6831cfb983d81';

/// ============================================
/// USE CASE LAYER - Dependency Injection
/// ============================================

@ProviderFor(createPostUseCase)
const createPostUseCaseProvider = CreatePostUseCaseProvider._();

/// ============================================
/// USE CASE LAYER - Dependency Injection
/// ============================================

final class CreatePostUseCaseProvider
    extends $FunctionalProvider<CreatePost, CreatePost, CreatePost>
    with $Provider<CreatePost> {
  /// ============================================
  /// USE CASE LAYER - Dependency Injection
  /// ============================================
  const CreatePostUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'createPostUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$createPostUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreatePost> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CreatePost create(Ref ref) {
    return createPostUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreatePost value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreatePost>(value),
    );
  }
}

String _$createPostUseCaseHash() => r'e9b8dfdb44eea8e5cce9ec559a3edfe5d9babb52';

@ProviderFor(updatePostUseCase)
const updatePostUseCaseProvider = UpdatePostUseCaseProvider._();

final class UpdatePostUseCaseProvider
    extends $FunctionalProvider<UpdatePost, UpdatePost, UpdatePost>
    with $Provider<UpdatePost> {
  const UpdatePostUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'updatePostUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$updatePostUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdatePost> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdatePost create(Ref ref) {
    return updatePostUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdatePost value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdatePost>(value),
    );
  }
}

String _$updatePostUseCaseHash() => r'98f7a2b38ad24c5d0955b01e02168a976d9d2c37';

@ProviderFor(deletePostUseCase)
const deletePostUseCaseProvider = DeletePostUseCaseProvider._();

final class DeletePostUseCaseProvider
    extends $FunctionalProvider<DeletePost, DeletePost, DeletePost>
    with $Provider<DeletePost> {
  const DeletePostUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'deletePostUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$deletePostUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeletePost> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeletePost create(Ref ref) {
    return deletePostUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeletePost value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeletePost>(value),
    );
  }
}

String _$deletePostUseCaseHash() => r'b633ae3a3feb730c3177be8ab32620daf0fdbd1f';

@ProviderFor(toggleInterestUseCase)
const toggleInterestUseCaseProvider = ToggleInterestUseCaseProvider._();

final class ToggleInterestUseCaseProvider
    extends $FunctionalProvider<ToggleInterest, ToggleInterest, ToggleInterest>
    with $Provider<ToggleInterest> {
  const ToggleInterestUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'toggleInterestUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$toggleInterestUseCaseHash();

  @$internal
  @override
  $ProviderElement<ToggleInterest> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ToggleInterest create(Ref ref) {
    return toggleInterestUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToggleInterest value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ToggleInterest>(value),
    );
  }
}

String _$toggleInterestUseCaseHash() =>
    r'71cfdea3688a5a03ba5f7a0fd72e2d88873d6af5';

@ProviderFor(loadInterestedUsersUseCase)
const loadInterestedUsersUseCaseProvider =
    LoadInterestedUsersUseCaseProvider._();

final class LoadInterestedUsersUseCaseProvider extends $FunctionalProvider<
    LoadInterestedUsers,
    LoadInterestedUsers,
    LoadInterestedUsers> with $Provider<LoadInterestedUsers> {
  const LoadInterestedUsersUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'loadInterestedUsersUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$loadInterestedUsersUseCaseHash();

  @$internal
  @override
  $ProviderElement<LoadInterestedUsers> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoadInterestedUsers create(Ref ref) {
    return loadInterestedUsersUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoadInterestedUsers value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoadInterestedUsers>(value),
    );
  }
}

String _$loadInterestedUsersUseCaseHash() =>
    r'c0e86387876da18d9df64b02bab5c729c7482eab';

/// Helper provider to get just the posts list

@ProviderFor(postList)
const postListProvider = PostListProvider._();

/// Helper provider to get just the posts list

final class PostListProvider extends $FunctionalProvider<List<PostEntity>,
    List<PostEntity>, List<PostEntity>> with $Provider<List<PostEntity>> {
  /// Helper provider to get just the posts list
  const PostListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'postListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$postListHash();

  @$internal
  @override
  $ProviderElement<List<PostEntity>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<PostEntity> create(Ref ref) {
    return postList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PostEntity> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PostEntity>>(value),
    );
  }
}

String _$postListHash() => r'07fde0e630ffd8fd76b93dd4ac48f6761f50f29f';
