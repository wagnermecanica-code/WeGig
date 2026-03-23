import 'dart:math' show min;

import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:wegig_app/core/firebase/blocked_profiles.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';
import 'package:wegig_app/features/post/data/datasources/post_remote_datasource.dart';
import 'package:wegig_app/features/post/domain/repositories/post_repository.dart';

/// Implementação do PostRepository
/// Conecta o domain layer com o data layer (datasource)
class PostRepositoryImpl implements PostRepository {
  /// Cria uma instância de PostRepositoryImpl
  PostRepositoryImpl({
    required IPostRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;
  final IPostRemoteDataSource _remoteDataSource;

  @override
  Future<List<PostEntity>> getAllPosts(String uid) async {
    try {
      debugPrint('📝 PostRepository: getAllPosts - uid=$uid');
      return await _remoteDataSource.getAllPosts(uid);
    } catch (e) {
      debugPrint('❌ PostRepository: Erro em getAllPosts - $e');
      rethrow;
    }
  }

  @override
  Future<List<PostEntity>> getPostsByProfile(String profileId) async {
    try {
      debugPrint('📝 PostRepository: getPostsByProfile - profileId=$profileId');
      return await _remoteDataSource.getPostsByProfile(profileId);
    } catch (e) {
      debugPrint('❌ PostRepository: Erro em getPostsByProfile - $e');
      rethrow;
    }
  }

  @override
  Future<PostEntity?> getPostById(String postId) async {
    try {
      debugPrint('📝 PostRepository: getPostById - postId=$postId');
      return await _remoteDataSource.getPostById(postId);
    } catch (e) {
      debugPrint('❌ PostRepository: Erro em getPostById - $e');
      rethrow;
    }
  }

  @override
  Future<PostEntity> createPost(PostEntity post) async {
    try {
      // Usa min() para evitar RangeError quando content < 30 caracteres
      final preview = post.content.substring(0, min(30, post.content.length));
      debugPrint(
          '📝 PostRepository: createPost - content=$preview...');

      await _remoteDataSource.createPost(post);

      debugPrint('✅ PostRepository: Post criado com sucesso');
      return post;
    } catch (e) {
      debugPrint('❌ PostRepository: Erro em createPost - $e');
      rethrow;
    }
  }

  @override
  Future<PostEntity> updatePost(PostEntity post) async {
    try {
      debugPrint('📝 PostRepository: updatePost - id=${post.id}');

      await _remoteDataSource.updatePost(post);

      debugPrint('✅ PostRepository: Post atualizado com sucesso');
      return post;
    } catch (e) {
      debugPrint('❌ PostRepository: Erro em updatePost - $e');
      rethrow;
    }
  }

  @override
  Future<void> deletePost(String postId, String profileId) async {
    try {
      debugPrint(
          '📝 PostRepository: deletePost - postId=$postId, profileId=$profileId');

      // Verify ownership
      final post = await _remoteDataSource.getPostById(postId);
      if (post == null) {
        throw Exception('Post não encontrado');
      }

      if (post.authorProfileId != profileId) {
        throw Exception('Você não tem permissão para deletar este post');
      }

      await _remoteDataSource.deletePost(postId);

      debugPrint('✅ PostRepository: Post deletado com sucesso');
    } catch (e) {
      debugPrint('❌ PostRepository: Erro em deletePost - $e');
      rethrow;
    }
  }

  @override
  Future<bool> isPostOwner(String postId, String profileId) async {
    try {
      final post = await _remoteDataSource.getPostById(postId);
      if (post == null) {
        return false;
      }
      return post.authorProfileId == profileId;
    } catch (e) {
      debugPrint('❌ PostRepository: Erro em isPostOwner - $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasInterest(String postId, String profileId) async {
    try {
      debugPrint(
          '📝 PostRepository: hasInterest - postId=$postId, profileId=$profileId');
      return await _remoteDataSource.hasInterest(postId, profileId);
    } catch (e) {
      debugPrint('❌ PostRepository: Erro em hasInterest - $e');
      rethrow;
    }
  }

  @override
  Future<void> addInterest(String postId, String profileId) async {
    try {
      debugPrint(
          '📝 PostRepository: addInterest - postId=$postId, profileId=$profileId');

      // Get post to get authorProfileId
      final post = await _remoteDataSource.getPostById(postId);
      if (post == null) {
        throw Exception('Post não encontrado');
      }

      // 🔒 Bloqueios: não envia interesse para autor bloqueado
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      final excluded = await BlockedRelations.getExcludedProfileIds(
        firestore: FirebaseFirestore.instance,
        profileId: profileId,
        uid: currentUser.uid,
      );
      if (excluded.contains(post.authorProfileId)) {
        throw StateError('Você não pode interagir com este post');
      }

      await _remoteDataSource.addInterest(
        postId,
        profileId,
        post.authorProfileId,
      );

      debugPrint('✅ PostRepository: Interest adicionado com sucesso');
    } catch (e) {
      debugPrint('❌ PostRepository: Erro em addInterest - $e');
      rethrow;
    }
  }

  @override
  Future<void> removeInterest(String postId, String profileId) async {
    try {
      debugPrint(
          '📝 PostRepository: removeInterest - postId=$postId, profileId=$profileId');

      await _remoteDataSource.removeInterest(postId, profileId);

      debugPrint('✅ PostRepository: Interest removido com sucesso');
    } catch (e) {
      debugPrint('❌ PostRepository: Erro em removeInterest - $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getInterestedProfiles(String postId) async {
    try {
      debugPrint('📝 PostRepository: getInterestedProfiles - postId=$postId');
      return await _remoteDataSource.getInterestedProfiles(postId);
    } catch (e) {
      debugPrint('❌ PostRepository: Erro em getInterestedProfiles - $e');
      rethrow;
    }
  }

  @override
  Future<List<PostEntity>> getNearbyPosts({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 50,
  }) async {
    try {
      debugPrint(
          '📝 PostRepository: getNearbyPosts - lat=$latitude, lng=$longitude');

      return await _remoteDataSource.getNearbyPosts(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
      );
    } catch (e) {
      debugPrint('❌ PostRepository: Erro em getNearbyPosts - $e');
      rethrow;
    }
  }

  @override
  Stream<List<PostEntity>> watchPosts(String uid) {
    try {
      debugPrint('📝 PostRepository: watchPosts - uid=$uid');
      return _remoteDataSource.watchPosts(uid);
    } catch (e) {
      debugPrint('❌ PostRepository: Erro em watchPosts - $e');
      rethrow;
    }
  }

  @override
  Stream<List<PostEntity>> watchPostsByProfile(String profileId) {
    try {
      debugPrint(
          '📝 PostRepository: watchPostsByProfile - profileId=$profileId');
      return _remoteDataSource.watchPostsByProfile(profileId);
    } catch (e) {
      debugPrint('❌ PostRepository: Erro em watchPostsByProfile - $e');
      rethrow;
    }
  }
}
