// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentRemoteDatasourceHash() =>
    r'e0d6d5e32b02145249420cb6d17eb38885a130b3';

/// Provider para o datasource de comentários
///
/// Copied from [commentRemoteDatasource].
@ProviderFor(commentRemoteDatasource)
final commentRemoteDatasourceProvider =
    AutoDisposeProvider<CommentRemoteDatasource>.internal(
  commentRemoteDatasource,
  name: r'commentRemoteDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$commentRemoteDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CommentRemoteDatasourceRef
    = AutoDisposeProviderRef<CommentRemoteDatasource>;
String _$commentRepositoryHash() => r'267d8937e47cc74eaaf2182ffcb6d3d5c7faef2a';

/// Provider para o repositório de comentários
///
/// Copied from [commentRepository].
@ProviderFor(commentRepository)
final commentRepositoryProvider =
    AutoDisposeProvider<CommentRepository>.internal(
  commentRepository,
  name: r'commentRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$commentRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CommentRepositoryRef = AutoDisposeProviderRef<CommentRepository>;
String _$commentsStreamHash() => r'7697420eb272a6a8f6560c16db9e60773b923146';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider de stream para assistir comentários em tempo real
///
/// Copied from [commentsStream].
@ProviderFor(commentsStream)
const commentsStreamProvider = CommentsStreamFamily();

/// Provider de stream para assistir comentários em tempo real
///
/// Copied from [commentsStream].
class CommentsStreamFamily extends Family<AsyncValue<List<CommentEntity>>> {
  /// Provider de stream para assistir comentários em tempo real
  ///
  /// Copied from [commentsStream].
  const CommentsStreamFamily();

  /// Provider de stream para assistir comentários em tempo real
  ///
  /// Copied from [commentsStream].
  CommentsStreamProvider call(
    String postId,
  ) {
    return CommentsStreamProvider(
      postId,
    );
  }

  @override
  CommentsStreamProvider getProviderOverride(
    covariant CommentsStreamProvider provider,
  ) {
    return call(
      provider.postId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'commentsStreamProvider';
}

/// Provider de stream para assistir comentários em tempo real
///
/// Copied from [commentsStream].
class CommentsStreamProvider
    extends AutoDisposeStreamProvider<List<CommentEntity>> {
  /// Provider de stream para assistir comentários em tempo real
  ///
  /// Copied from [commentsStream].
  CommentsStreamProvider(
    String postId,
  ) : this._internal(
          (ref) => commentsStream(
            ref as CommentsStreamRef,
            postId,
          ),
          from: commentsStreamProvider,
          name: r'commentsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$commentsStreamHash,
          dependencies: CommentsStreamFamily._dependencies,
          allTransitiveDependencies:
              CommentsStreamFamily._allTransitiveDependencies,
          postId: postId,
        );

  CommentsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    Stream<List<CommentEntity>> Function(CommentsStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CommentsStreamProvider._internal(
        (ref) => create(ref as CommentsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<CommentEntity>> createElement() {
    return _CommentsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentsStreamProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CommentsStreamRef on AutoDisposeStreamProviderRef<List<CommentEntity>> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _CommentsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<CommentEntity>>
    with CommentsStreamRef {
  _CommentsStreamProviderElement(super.provider);

  @override
  String get postId => (origin as CommentsStreamProvider).postId;
}

String _$commentCountStreamHash() =>
    r'9039f70d7b0133cbc6e5086cc618a325ea22b6ae';

/// Provider para buscar commentCount de um post (para exibir o contador)
///
/// Copied from [commentCountStream].
@ProviderFor(commentCountStream)
const commentCountStreamProvider = CommentCountStreamFamily();

/// Provider para buscar commentCount de um post (para exibir o contador)
///
/// Copied from [commentCountStream].
class CommentCountStreamFamily extends Family<AsyncValue<int>> {
  /// Provider para buscar commentCount de um post (para exibir o contador)
  ///
  /// Copied from [commentCountStream].
  const CommentCountStreamFamily();

  /// Provider para buscar commentCount de um post (para exibir o contador)
  ///
  /// Copied from [commentCountStream].
  CommentCountStreamProvider call(
    String postId,
  ) {
    return CommentCountStreamProvider(
      postId,
    );
  }

  @override
  CommentCountStreamProvider getProviderOverride(
    covariant CommentCountStreamProvider provider,
  ) {
    return call(
      provider.postId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'commentCountStreamProvider';
}

/// Provider para buscar commentCount de um post (para exibir o contador)
///
/// Copied from [commentCountStream].
class CommentCountStreamProvider extends AutoDisposeStreamProvider<int> {
  /// Provider para buscar commentCount de um post (para exibir o contador)
  ///
  /// Copied from [commentCountStream].
  CommentCountStreamProvider(
    String postId,
  ) : this._internal(
          (ref) => commentCountStream(
            ref as CommentCountStreamRef,
            postId,
          ),
          from: commentCountStreamProvider,
          name: r'commentCountStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$commentCountStreamHash,
          dependencies: CommentCountStreamFamily._dependencies,
          allTransitiveDependencies:
              CommentCountStreamFamily._allTransitiveDependencies,
          postId: postId,
        );

  CommentCountStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    Stream<int> Function(CommentCountStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CommentCountStreamProvider._internal(
        (ref) => create(ref as CommentCountStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<int> createElement() {
    return _CommentCountStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentCountStreamProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CommentCountStreamRef on AutoDisposeStreamProviderRef<int> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _CommentCountStreamProviderElement
    extends AutoDisposeStreamProviderElement<int> with CommentCountStreamRef {
  _CommentCountStreamProviderElement(super.provider);

  @override
  String get postId => (origin as CommentCountStreamProvider).postId;
}

String _$forwardCountStreamHash() =>
    r'8f0ae6344a3b4643f3555ff035ebdd6012b59995';

/// Provider para buscar forwardCount de um post (para exibir o contador)
///
/// Copied from [forwardCountStream].
@ProviderFor(forwardCountStream)
const forwardCountStreamProvider = ForwardCountStreamFamily();

/// Provider para buscar forwardCount de um post (para exibir o contador)
///
/// Copied from [forwardCountStream].
class ForwardCountStreamFamily extends Family<AsyncValue<int>> {
  /// Provider para buscar forwardCount de um post (para exibir o contador)
  ///
  /// Copied from [forwardCountStream].
  const ForwardCountStreamFamily();

  /// Provider para buscar forwardCount de um post (para exibir o contador)
  ///
  /// Copied from [forwardCountStream].
  ForwardCountStreamProvider call(
    String postId,
  ) {
    return ForwardCountStreamProvider(
      postId,
    );
  }

  @override
  ForwardCountStreamProvider getProviderOverride(
    covariant ForwardCountStreamProvider provider,
  ) {
    return call(
      provider.postId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'forwardCountStreamProvider';
}

/// Provider para buscar forwardCount de um post (para exibir o contador)
///
/// Copied from [forwardCountStream].
class ForwardCountStreamProvider extends AutoDisposeStreamProvider<int> {
  /// Provider para buscar forwardCount de um post (para exibir o contador)
  ///
  /// Copied from [forwardCountStream].
  ForwardCountStreamProvider(
    String postId,
  ) : this._internal(
          (ref) => forwardCountStream(
            ref as ForwardCountStreamRef,
            postId,
          ),
          from: forwardCountStreamProvider,
          name: r'forwardCountStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$forwardCountStreamHash,
          dependencies: ForwardCountStreamFamily._dependencies,
          allTransitiveDependencies:
              ForwardCountStreamFamily._allTransitiveDependencies,
          postId: postId,
        );

  ForwardCountStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    Stream<int> Function(ForwardCountStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ForwardCountStreamProvider._internal(
        (ref) => create(ref as ForwardCountStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<int> createElement() {
    return _ForwardCountStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ForwardCountStreamProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ForwardCountStreamRef on AutoDisposeStreamProviderRef<int> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _ForwardCountStreamProviderElement
    extends AutoDisposeStreamProviderElement<int> with ForwardCountStreamRef {
  _ForwardCountStreamProviderElement(super.provider);

  @override
  String get postId => (origin as ForwardCountStreamProvider).postId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
