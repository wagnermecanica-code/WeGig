import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:flutter/foundation.dart';

/// Interface para PostRemoteDataSource
abstract class IPostRemoteDataSource {
  Future<List<PostEntity>> getAllPosts(String uid);
  Future<List<PostEntity>> getPostsByProfile(String profileId);
  Future<PostEntity?> getPostById(String postId);
  Future<void> createPost(PostEntity post);
  Future<void> updatePost(PostEntity post);
  Future<void> deletePost(String postId);
  Future<bool> hasInterest(String postId, String profileId);
  Future<void> addInterest(
      String postId, String profileId, String authorProfileId);
  Future<void> removeInterest(String postId, String profileId);
  Future<List<String>> getInterestedProfiles(String postId);
  Future<List<PostEntity>> getNearbyPosts({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 50,
  });
  Stream<List<PostEntity>> watchPosts(String uid);
  Stream<List<PostEntity>> watchPostsByProfile(String profileId);
}

/// DataSource para Posts - Firebase Firestore operations
class PostRemoteDataSource implements IPostRemoteDataSource {
  PostRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Future<List<PostEntity>> getAllPosts(String uid) async {
    try {
      debugPrint('🔍 PostDataSource: getAllPosts - uid=$uid');

      final snapshot = await _firestore
          .collection('posts')
          .where('authorUid', isEqualTo: uid)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      final posts = snapshot.docs.map(PostEntity.fromFirestore).toList();

      debugPrint('✅ PostDataSource: ${posts.length} posts loaded');
      return posts;
    } catch (e) {
      debugPrint('❌ PostDataSource: Erro em getAllPosts - $e');
      rethrow;
    }
  }

  @override
  Future<List<PostEntity>> getPostsByProfile(String profileId) async {
    try {
      debugPrint('🔍 PostDataSource: getPostsByProfile - profileId=$profileId');

      final snapshot = await _firestore
          .collection('posts')
          .where('authorProfileId', isEqualTo: profileId)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      final posts = snapshot.docs.map(PostEntity.fromFirestore).toList();

      debugPrint('✅ PostDataSource: ${posts.length} posts loaded for profile');
      return posts;
    } catch (e) {
      debugPrint('❌ PostDataSource: Erro em getPostsByProfile - $e');
      rethrow;
    }
  }

  @override
  Future<PostEntity?> getPostById(String postId) async {
    try {
      debugPrint('🔍 PostDataSource: getPostById - postId=$postId');

      final doc = await _firestore.collection('posts').doc(postId).get();

      if (!doc.exists) {
        debugPrint('⚠️ PostDataSource: Post não encontrado');
        return null;
      }

      return PostEntity.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ PostDataSource: Erro em getPostById - $e');
      rethrow;
    }
  }

  @override
  Future<void> createPost(PostEntity post) async {
    try {
      debugPrint('📝 PostDataSource: createPost - id=${post.id}');

      await _firestore.collection('posts').doc(post.id).set(post.toFirestore());

      debugPrint('✅ PostDataSource: Post criado com sucesso');
    } catch (e) {
      debugPrint('❌ PostDataSource: Erro em createPost - $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePost(PostEntity post) async {
    try {
      debugPrint('📝 PostDataSource: updatePost - id=${post.id}');

      await _firestore
          .collection('posts')
          .doc(post.id)
          .update(post.toFirestore());

      debugPrint('✅ PostDataSource: Post atualizado com sucesso');
    } catch (e) {
      debugPrint('❌ PostDataSource: Erro em updatePost - $e');
      rethrow;
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      debugPrint('🗑️ PostDataSource: deletePost - id=$postId');

      await _firestore.collection('posts').doc(postId).delete();

      debugPrint('✅ PostDataSource: Post deletado com sucesso');
    } catch (e) {
      debugPrint('❌ PostDataSource: Erro em deletePost - $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasInterest(String postId, String profileId) async {
    try {
      debugPrint(
          '🔍 PostDataSource: hasInterest - post=$postId, profile=$profileId');

      final doc = await _firestore
          .collection('interests')
          .where('postId', isEqualTo: postId)
          .where('interestedProfileId', isEqualTo: profileId)
          .limit(1)
          .get();

      final hasInterest = doc.docs.isNotEmpty;
      debugPrint('✅ PostDataSource: hasInterest=$hasInterest');
      return hasInterest;
    } catch (e) {
      debugPrint('❌ PostDataSource: Erro em hasInterest - $e');
      rethrow;
    }
  }

  @override
  Future<void> addInterest(
    String postId,
    String profileId,
    String authorProfileId,
  ) async {
    try {
      debugPrint(
          '💚 PostDataSource: addInterest - post=$postId, profile=$profileId');

      // Create interest document
      await _firestore.collection('interests').add({
        'postId': postId,
        'interestedProfileId': profileId,
        'authorProfileId': authorProfileId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ PostDataSource: Interest adicionado com sucesso');
    } catch (e) {
      debugPrint('❌ PostDataSource: Erro em addInterest - $e');
      rethrow;
    }
  }

  @override
  Future<void> removeInterest(String postId, String profileId) async {
    try {
      debugPrint(
          '💔 PostDataSource: removeInterest - post=$postId, profile=$profileId');

      final snapshot = await _firestore
          .collection('interests')
          .where('postId', isEqualTo: postId)
          .where('interestedProfileId', isEqualTo: profileId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('✅ PostDataSource: Interest removido com sucesso');
    } catch (e) {
      debugPrint('❌ PostDataSource: Erro em removeInterest - $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getInterestedProfiles(String postId) async {
    try {
      debugPrint('🔍 PostDataSource: getInterestedProfiles - post=$postId');

      final snapshot = await _firestore
          .collection('interests')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: true)
          .get();

      final profileIds = snapshot.docs
          .map((doc) => doc.data()['interestedProfileId'] as String)
          .toList();

      debugPrint('✅ PostDataSource: ${profileIds.length} interested profiles');
      return profileIds;
    } catch (e) {
      debugPrint('❌ PostDataSource: Erro em getInterestedProfiles - $e');
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
          '🔍 PostDataSource: getNearbyPosts - lat=$latitude, lng=$longitude, radius=$radiusKm');

      // Simple geosearch - get all non-expired posts and filter by distance
      final snapshot = await _firestore
          .collection('posts')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final posts = snapshot.docs.map(PostEntity.fromFirestore).toList();

      debugPrint('✅ PostDataSource: ${posts.length} nearby posts loaded');
      return posts;
    } catch (e) {
      debugPrint('❌ PostDataSource: Erro em getNearbyPosts - $e');
      rethrow;
    }
  }

  @override
  Stream<List<PostEntity>> watchPosts(String uid) {
    try {
      debugPrint('👁️ PostDataSource: watchPosts - uid=$uid');

      return _firestore
          .collection('posts')
          .where('authorUid', isEqualTo: uid)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final posts = snapshot.docs.map(PostEntity.fromFirestore).toList();
        debugPrint('👁️ PostDataSource: Stream emitiu ${posts.length} posts');
        return posts;
      });
    } catch (e) {
      debugPrint('❌ PostDataSource: Erro em watchPosts - $e');
      rethrow;
    }
  }

  @override
  Stream<List<PostEntity>> watchPostsByProfile(String profileId) {
    try {
      debugPrint(
          '👁️ PostDataSource: watchPostsByProfile - profileId=$profileId');

      return _firestore
          .collection('posts')
          .where('authorProfileId', isEqualTo: profileId)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final posts = snapshot.docs.map(PostEntity.fromFirestore).toList();
        debugPrint('👁️ PostDataSource: Stream emitiu ${posts.length} posts');
        return posts;
      });
    } catch (e) {
      debugPrint('❌ PostDataSource: Erro em watchPostsByProfile - $e');
      rethrow;
    }
  }
}
