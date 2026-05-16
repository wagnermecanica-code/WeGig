import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:wegig_app/features/comment/domain/entities/comment_entity.dart';

/// Datasource remoto para comentários de posts.
///
/// Usa subcoleção Firestore: posts/{postId}/comments/{commentId}
/// Atualiza commentCount no documento pai (post) via batch write.
abstract class CommentRemoteDatasource {
  /// Retorna stream de comentários em tempo real para um post
  Stream<List<CommentEntity>> watchComments(String postId);

  /// Adiciona um comentário e incrementa commentCount no post
  Future<CommentEntity> addComment({
    required String postId,
    required String authorProfileId,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    required String text,
    String? parentCommentId,
    String? replyToName,
    String? replyToProfileId,
  });

  /// Deleta um comentário e decrementa commentCount no post
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  });

  /// Alterna curtida de um comentário (like/unlike)
  /// Usa FieldValue.arrayUnion/arrayRemove para atomicidade
  Future<void> toggleLike({
    required String postId,
    required String commentId,
    required String profileId,
  });

  /// Retorna a contagem de comentários de um post
  Future<int> getCommentCount(String postId);
}

class CommentRemoteDatasourceImpl implements CommentRemoteDatasource {
  CommentRemoteDatasourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _commentsRef(String postId) {
    return _firestore.collection('posts').doc(postId).collection('comments');
  }

  DocumentReference<Map<String, dynamic>> _postRef(String postId) {
    return _firestore.collection('posts').doc(postId);
  }

  Future<void> _reconcileCommentCount(String postId) async {
    final exactCount = await getCommentCount(postId);
    await _postRef(postId).set({
      'commentCount': exactCount,
    }, SetOptions(merge: true));
  }

  @override
  Stream<List<CommentEntity>> watchComments(String postId) {
    return _commentsRef(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommentEntity.fromFirestore(doc, postId: postId);
      }).toList();
    });
  }

  @override
  Future<CommentEntity> addComment({
    required String postId,
    required String authorProfileId,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    required String text,
    String? parentCommentId,
    String? replyToName,
    String? replyToProfileId,
  }) async {
    final now = DateTime.now();
    final comment = CommentEntity(
      id: '', // será preenchido pelo Firestore
      postId: postId,
      authorProfileId: authorProfileId,
      authorUid: authorUid,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      text: text,
      createdAt: now,
      parentCommentId: parentCommentId,
      replyToName: replyToName,
      replyToProfileId: replyToProfileId,
    );

    // Batch: criar comentário + incrementar commentCount
    final batch = _firestore.batch();

    final commentRef = _commentsRef(postId).doc();
    batch.set(commentRef, comment.toFirestore());

    batch.update(_postRef(postId), {
      'commentCount': FieldValue.increment(1),
    });

    await batch.commit();
    await _reconcileCommentCount(postId);

    debugPrint('✅ CommentDatasource: Comentário criado (postId: $postId)');

    return comment.copyWith(id: commentRef.id);
  }

  @override
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    // Batch: deletar comentário + decrementar commentCount
    final batch = _firestore.batch();

    batch.delete(_commentsRef(postId).doc(commentId));

    batch.update(_postRef(postId), {
      'commentCount': FieldValue.increment(-1),
    });

    await batch.commit();
    await _reconcileCommentCount(postId);

    debugPrint('✅ CommentDatasource: Comentário deletado (commentId: $commentId)');
  }

  @override
  Future<void> toggleLike({
    required String postId,
    required String commentId,
    required String profileId,
  }) async {
    final commentRef = _commentsRef(postId).doc(commentId);
    final doc = await commentRef.get();
    if (!doc.exists) return;

    final likedBy = (doc.data()?['likedBy'] as List<dynamic>?)?.cast<String>() ?? [];
    final isLiked = likedBy.contains(profileId);

    await commentRef.update({
      'likedBy': isLiked
          ? FieldValue.arrayRemove([profileId])
          : FieldValue.arrayUnion([profileId]),
      'likeCount': FieldValue.increment(isLiked ? -1 : 1),
    });

    debugPrint('✅ CommentDatasource: Like toggled (commentId: $commentId, liked: ${!isLiked})');
  }

  @override
  Future<int> getCommentCount(String postId) async {
    final snapshot = await _commentsRef(postId).count().get();
    return snapshot.count ?? 0;
  }
}
