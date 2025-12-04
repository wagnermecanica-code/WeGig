import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/post_result.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wegig_app/features/post/data/datasources/post_remote_datasource.dart';
import 'package:wegig_app/features/post/data/repositories/post_repository_impl.dart';
import 'package:wegig_app/features/post/domain/repositories/post_repository.dart';
import 'package:wegig_app/features/post/domain/models/post_form_input.dart';
import 'package:wegig_app/features/post/domain/usecases/create_post.dart';
import 'package:wegig_app/features/post/domain/usecases/delete_post.dart';
import 'package:wegig_app/features/post/domain/usecases/load_interested_users.dart';
import 'package:wegig_app/features/post/domain/usecases/toggle_interest.dart';
import 'package:wegig_app/features/post/domain/usecases/update_post.dart';
import 'package:wegig_app/features/post/domain/services/post_service.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:uuid/uuid.dart';

part 'post_providers.freezed.dart';
part 'post_providers.g.dart';

/// ============================================
/// DATA LAYER - Dependency Injection
/// ============================================

/// Provider para PostRemoteDataSource (singleton)
@riverpod
IPostRemoteDataSource postRemoteDataSource(Ref ref) {
  return PostRemoteDataSource();
}

/// Provider para FirebaseAuth (facilita override em testes)
final postFirebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

/// Provider para serviço utilitário de posts
final postServiceProvider = Provider<PostService>(
  (ref) => PostService(),
);

/// Provider para PostRepository (singleton)
@riverpod
PostRepository postRepositoryNew(Ref ref) {
  final dataSource = ref.read(postRemoteDataSourceProvider);
  return PostRepositoryImpl(remoteDataSource: dataSource);
}

/// ============================================
/// USE CASE LAYER - Dependency Injection
/// ============================================

/// Provider para CreatePost use case
@riverpod
CreatePost createPostUseCase(Ref ref) {
  final repository = ref.read(postRepositoryNewProvider);
  return CreatePost(repository);
}

/// Provider para UpdatePost use case
@riverpod
UpdatePost updatePostUseCase(Ref ref) {
  final repository = ref.read(postRepositoryNewProvider);
  return UpdatePost(repository);
}

/// Provider para DeletePost use case
@riverpod
DeletePost deletePostUseCase(Ref ref) {
  final repository = ref.read(postRepositoryNewProvider);
  return DeletePost(repository);
}

/// Provider para ToggleInterest use case
@riverpod
ToggleInterest toggleInterestUseCase(Ref ref) {
  final repository = ref.read(postRepositoryNewProvider);
  return ToggleInterest(repository);
}

/// Provider para LoadInterestedUsers use case
@riverpod
LoadInterestedUsers loadInterestedUsersUseCase(Ref ref) {
  final repository = ref.read(postRepositoryNewProvider);
  return LoadInterestedUsers(repository);
}

/// ============================================
/// STATE MANAGEMENT - PostNotifier
/// ============================================

/// State para PostNotifier
@freezed
class PostState with _$PostState {
  const factory PostState({
    @Default([]) List<PostEntity> posts,
    @Default(false) bool isLoading,
    String? error,
  }) = _PostState;
}

/// PostNotifier - Gerencia estado de posts com Clean Architecture
///
/// Responsável por:
/// - Carregar posts do usuário/perfil
/// - Criar, atualizar e deletar posts
/// - Toggle de interesse (like)
/// - Carregar lista de perfis interessados
/// - Refresh manual (pull-to-refresh)
@riverpod
class PostNotifier extends _$PostNotifier {
  // ⚡ PERFORMANCE: Cache de posts com TTL de 5 minutos
  List<PostEntity>? _cachedPosts;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 5);
  ProfileEntity? _activeProfile() {
    final profileState = ref.read(profileProvider);
    return profileState.value?.activeProfile;
  }

  @override
  FutureOr<PostState> build() async {
    // ✅ Register cleanup for cache when provider is disposed
    ref.onDispose(() {
      _invalidateCache();
      debugPrint('📦 PostNotifier: Cache limpo no dispose');
    });
    
    return PostState(posts: await _loadPosts());
  }

  Future<List<PostEntity>> _loadPosts() async {
    try {
      final uid = ref.read(postFirebaseAuthProvider).currentUser?.uid;
      if (uid == null) return [];

      // ⚡ Check cache first
      if (_cachedPosts != null && _cacheTimestamp != null) {
        final elapsed = DateTime.now().difference(_cacheTimestamp!);
        if (elapsed < _cacheDuration) {
          debugPrint('📦 PostNotifier: Usando cache (${elapsed.inSeconds}s atrás, ${_cachedPosts!.length} posts)');
          return _cachedPosts!;
        } else {
          debugPrint('📦 PostNotifier: Cache expirado (${elapsed.inMinutes}min atrás)');
        }
      }

      // Cache miss - fetch from repository
      final repository = ref.read(postRepositoryNewProvider);
      final posts = await repository.getAllPosts(uid);
      
      // ⚡ Store in cache
      _cachedPosts = posts;
      _cacheTimestamp = DateTime.now();
      debugPrint('📦 PostNotifier: Cache atualizado (${posts.length} posts)');
      
      return posts;
    } catch (e) {
      debugPrint('❌ PostNotifier: Erro ao carregar posts - $e');
      return [];
    }
  }

  /// Invalida cache do contador
  /// 
  /// Chame após criar, atualizar ou deletar posts
  void _invalidateCache() {
    _cachedPosts = null;
    _cacheTimestamp = null;
    debugPrint('📦 PostNotifier: Cache invalidado');
  }

  /// Cria um novo post
  Future<PostResult> createPost(PostEntity post) async {
    try {
      final uid = ref.read(postFirebaseAuthProvider).currentUser?.uid;
      if (uid == null) {
        return const PostFailure(message: 'Usuário não autenticado');
      }

      final createUseCase = ref.read(createPostUseCaseProvider);
      await createUseCase(post);

      // Invalidate cache and refresh state
      _invalidateCache();
      state = AsyncValue.data(PostState(posts: await _loadPosts()));
      return PostSuccess(post: post);
    } catch (e) {
      debugPrint('❌ PostNotifier: Erro ao criar post - $e');
      return PostFailure(
        message: 'Erro ao criar post: $e',
        exception: e is Exception ? e : null,
      );
    }
  }

  /// Atualiza um post existente
  Future<PostResult> updatePost(PostEntity post) async {
    try {
      final uid = ref.read(postFirebaseAuthProvider).currentUser?.uid;
      if (uid == null) {
        return const PostFailure(message: 'Usuário não autenticado');
      }

      final updateUseCase = ref.read(updatePostUseCaseProvider);
      await updateUseCase(post, post.authorProfileId);

      // Invalidate cache and refresh state
      _invalidateCache();
      state = AsyncValue.data(PostState(posts: await _loadPosts()));
      return PostSuccess(post: post);
    } catch (e) {
      debugPrint('❌ PostNotifier: Erro ao atualizar post - $e');
      return PostFailure(
        message: 'Erro ao atualizar post: $e',
        exception: e is Exception ? e : null,
      );
    }
  }

  /// Novo fluxo único de criação/edição usado pelo PostPage.
  Future<PostResult> savePost(PostFormInput input) async {
    try {
      final profile = _activeProfile();
      if (profile == null) {
        return const PostFailure(
          message: 'Perfil ativo não encontrado. Tente novamente.',
        );
      }

      final postService = ref.read(postServiceProvider);
      final postId = input.postId ?? const Uuid().v4();
      String? photoUrl = input.existingPhotoUrl;

      if (input.localPhotoPath != null && input.localPhotoPath!.isNotEmpty) {
        final file = File(input.localPhotoPath!);
        if (file.existsSync()) {
          photoUrl = await postService.uploadPostImage(file, postId);
        }
      }

      final now = DateTime.now();
      final post = PostEntity(
        id: postId,
        authorProfileId: profile.profileId,
        authorUid: profile.uid,
        content: input.content,
        location: input.location,
        city: input.city,
        neighborhood: input.neighborhood,
        state: input.state,
        photoUrl: photoUrl,
        youtubeLink: input.youtubeLink?.isEmpty == true ? null : input.youtubeLink,
        type: input.type,
        level: input.level,
        instruments: input.type == 'musician'
            ? input.selectedInstruments
            : <String>[],
        genres: input.genres,
        seekingMusicians: input.type == 'band'
            ? input.selectedInstruments
            : <String>[],
        availableFor: input.availableFor,
        createdAt: input.createdAt ?? now,
        expiresAt: input.expiresAt ?? now.add(const Duration(days: 30)),
        authorName: profile.name,
        authorPhotoUrl: profile.photoUrl,
        activeProfileName: profile.name,
        activeProfilePhotoUrl: profile.photoUrl,
      );

      postService.validatePostEntity(post);

      if (input.isEditing) {
        final updateUseCase = ref.read(updatePostUseCaseProvider);
        await updateUseCase(post, profile.profileId);
      } else {
        final createUseCase = ref.read(createPostUseCaseProvider);
        await createUseCase(post);
      }

      _invalidateCache();
      state = AsyncValue.data(PostState(posts: await _loadPosts()));

      return PostSuccess(
        post: post,
        message:
            input.isEditing ? 'Post atualizado com sucesso' : 'Post criado com sucesso',
      );
    } catch (e) {
      debugPrint('❌ PostNotifier: Erro ao salvar post - $e');
      return PostFailure(
        message: 'Erro ao salvar post: $e',
        exception: e is Exception ? e : null,
      );
    }
  }

  /// Deleta um post por ID
  Future<PostResult> deletePost(String postId, String profileId) async {
    try {
      final deleteUseCase = ref.read(deletePostUseCaseProvider);
      await deleteUseCase(postId, profileId);

      // Invalidate cache and refresh state
      _invalidateCache();
      state = AsyncValue.data(PostState(posts: await _loadPosts()));

      // Return success with dummy post (just need the id)
      return PostSuccess(
        post: PostEntity(
          id: postId,
          authorProfileId: profileId,
          authorUid: '',
          content: '',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 30)),
          type: 'musician',
          location: const GeoPoint(0, 0),
          city: '',
          level: '',
          instruments: const [],
          genres: const [],
          seekingMusicians: const [],
        ),
        message: 'Post deletado com sucesso',
      );
    } catch (e) {
      debugPrint('❌ PostNotifier: Erro ao deletar post - $e');
      return PostFailure(
        message: 'Erro ao deletar post: $e',
        exception: e is Exception ? e : null,
      );
    }
  }

  /// Adiciona ou remove interesse em um post
  Future<bool> toggleInterest(String postId, String profileId) async {
    try {
      final toggleUseCase = ref.read(toggleInterestUseCaseProvider);
      final hasInterest = await toggleUseCase(postId, profileId);
      return hasInterest;
    } catch (e) {
      debugPrint('❌ PostNotifier: Erro ao toggle interest - $e');
      return false;
    }
  }

  /// Carrega a lista de perfis interessados em um post
  Future<List<String>> loadInterestedUsers(String postId) async {
    try {
      final loadUseCase = ref.read(loadInterestedUsersUseCaseProvider);
      return await loadUseCase(postId);
    } catch (e) {
      debugPrint('❌ PostNotifier: Erro ao carregar interested users - $e');
      return [];
    }
  }

  /// Força o refresh da lista de posts (pull-to-refresh)
  Future<void> refresh() async {
    _invalidateCache();
    state = AsyncValue.data(PostState(posts: await _loadPosts()));
  }
}

/// ============================================
/// GLOBAL PROVIDERS
/// ============================================

/// Helper provider to get just the posts list
@riverpod
List<PostEntity> postList(Ref ref) {
  final postState = ref.watch(postNotifierProvider);
  return postState.when(
    data: (state) => state.posts,
    loading: () => [],
    error: (_, __) => [],
  );
}
