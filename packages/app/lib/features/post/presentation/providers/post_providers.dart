import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/post_result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/features/post/data/datasources/post_remote_datasource.dart';
import 'package:wegig_app/features/post/data/repositories/post_repository_impl.dart';
import 'package:wegig_app/features/post/domain/repositories/post_repository.dart';
import 'package:wegig_app/features/post/domain/usecases/create_post.dart';
import 'package:wegig_app/features/post/domain/usecases/delete_post.dart';
import 'package:wegig_app/features/post/domain/usecases/load_interested_users.dart';
import 'package:wegig_app/features/post/domain/usecases/toggle_interest.dart';
import 'package:wegig_app/features/post/domain/usecases/update_post.dart';

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

/// Provider para PostRepository (singleton)
@riverpod
PostRepository postRepositoryNew(Ref ref) {
  final dataSource = ref.read(postRemoteDataSourceProvider);
  return PostRepositoryImpl(remoteDataSource: dataSource);
}

/// ============================================
/// USE CASE LAYER - Dependency Injection
/// ============================================

@riverpod
CreatePost createPostUseCase(Ref ref) {
  final repository = ref.read(postRepositoryNewProvider);
  return CreatePost(repository);
}

@riverpod
UpdatePost updatePostUseCase(Ref ref) {
  final repository = ref.read(postRepositoryNewProvider);
  return UpdatePost(repository);
}

@riverpod
DeletePost deletePostUseCase(Ref ref) {
  final repository = ref.read(postRepositoryNewProvider);
  return DeletePost(repository);
}

@riverpod
ToggleInterest toggleInterestUseCase(Ref ref) {
  final repository = ref.read(postRepositoryNewProvider);
  return ToggleInterest(repository);
}

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

/// PostNotifier - Manages post state with Clean Architecture
@riverpod
class PostNotifier extends _$PostNotifier {
  @override
  FutureOr<PostState> build() async {
    return PostState(posts: await _loadPosts());
  }

  Future<List<PostEntity>> _loadPosts() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return [];

      final repository = ref.read(postRepositoryNewProvider);
      return await repository.getAllPosts(uid);
    } catch (e) {
      debugPrint('❌ PostNotifier: Erro ao carregar posts - $e');
      return [];
    }
  }

  Future<PostResult> createPost(PostEntity post) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return const PostFailure(message: 'Usuário não autenticado');
      }

      final createUseCase = ref.read(createPostUseCaseProvider);
      await createUseCase(post);

      // Refresh state
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

  Future<PostResult> updatePost(PostEntity post) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return const PostFailure(message: 'Usuário não autenticado');
      }

      final updateUseCase = ref.read(updatePostUseCaseProvider);
      await updateUseCase(post, post.authorProfileId);

      // Refresh state
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

  Future<PostResult> deletePost(String postId, String profileId) async {
    try {
      final deleteUseCase = ref.read(deletePostUseCaseProvider);
      await deleteUseCase(postId, profileId);

      // Refresh state
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

  Future<PostResult> toggleInterest(String postId, String profileId) async {
    try {
      final toggleUseCase = ref.read(toggleInterestUseCaseProvider);
      final hasInterest = await toggleUseCase(postId, profileId);

      return InterestToggleSuccess(hasInterest);
    } catch (e) {
      debugPrint('❌ PostNotifier: Erro ao toggle interest - $e');
      return PostFailure(
        message: 'Erro ao demonstrar interesse: $e',
        exception: e is Exception ? e : null,
      );
    }
  }

  Future<List<String>> getInterestedUsers(String postId) async {
    try {
      final loadUseCase = ref.read(loadInterestedUsersUseCaseProvider);
      return await loadUseCase(postId);
    } catch (e) {
      debugPrint('❌ PostNotifier: Erro ao carregar interested users - $e');
      return [];
    }
  }

  Future<void> refresh() async {
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
