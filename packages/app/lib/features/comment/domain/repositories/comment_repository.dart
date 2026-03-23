import 'package:wegig_app/features/comment/domain/entities/comment_entity.dart';

/// Repositório abstrato para comentários
abstract class CommentRepository {
  /// Stream de comentários em tempo real
  Stream<List<CommentEntity>> watchComments(String postId);

  /// Adiciona um comentário
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

  /// Deleta um comentário
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  });

  /// Alterna curtida de um comentário (like/unlike)
  Future<void> toggleLike({
    required String postId,
    required String commentId,
    required String profileId,
  });

  /// Retorna a contagem de comentários
  Future<int> getCommentCount(String postId);
}
