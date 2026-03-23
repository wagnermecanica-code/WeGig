import 'package:wegig_app/features/comment/data/datasources/comment_remote_datasource.dart';
import 'package:wegig_app/features/comment/domain/entities/comment_entity.dart';
import 'package:wegig_app/features/comment/domain/repositories/comment_repository.dart';

/// Implementação do repositório de comentários
class CommentRepositoryImpl implements CommentRepository {
  CommentRepositoryImpl({
    required CommentRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  final CommentRemoteDatasource _remoteDatasource;

  @override
  Stream<List<CommentEntity>> watchComments(String postId) {
    return _remoteDatasource.watchComments(postId);
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
  }) {
    return _remoteDatasource.addComment(
      postId: postId,
      authorProfileId: authorProfileId,
      authorUid: authorUid,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      text: text,
      parentCommentId: parentCommentId,
      replyToName: replyToName,
      replyToProfileId: replyToProfileId,
    );
  }

  @override
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) {
    return _remoteDatasource.deleteComment(
      postId: postId,
      commentId: commentId,
    );
  }

  @override
  Future<void> toggleLike({
    required String postId,
    required String commentId,
    required String profileId,
  }) {
    return _remoteDatasource.toggleLike(
      postId: postId,
      commentId: commentId,
      profileId: profileId,
    );
  }

  @override
  Future<int> getCommentCount(String postId) {
    return _remoteDatasource.getCommentCount(postId);
  }
}
