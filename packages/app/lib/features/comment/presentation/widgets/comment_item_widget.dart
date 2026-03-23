import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wegig_app/features/comment/domain/entities/comment_entity.dart';

/// Widget para exibir um comentário individual no bottom sheet.
///
/// Layout: [Avatar] [Nome + Texto + Timestamp + Responder] [Botão delete se for do autor]
/// Respostas são exibidas com indentação e indicador visual.
class CommentItemWidget extends StatelessWidget {
  const CommentItemWidget({
    required this.comment,
    required this.isOwnComment,
    this.canDelete = false,
    this.isReply = false,
    this.isLiked = false,
    this.likeCount = 0,
    this.onDelete,
    this.onTapProfile,
    this.onReply,
    this.onToggleLike,
    this.onViewLikers,
    this.onLongPress,
    super.key,
  });

  final CommentEntity comment;
  final bool isOwnComment;
  /// Se true, exibe o botão de excluir (autor do comentário OU dono do post)
  final bool canDelete;
  /// Se true, exibe com indentação (é uma resposta)
  final bool isReply;
  /// Se o usuário atual curtiu este comentário
  final bool isLiked;
  /// Quantidade de curtidas
  final int likeCount;
  final VoidCallback? onDelete;
  final VoidCallback? onTapProfile;
  /// Callback para responder a este comentário
  final VoidCallback? onReply;
  /// Callback para curtir/descurtir este comentário
  final VoidCallback? onToggleLike;
  /// Callback para ver quem curtiu
  final VoidCallback? onViewLikers;
  /// Callback para long press (menu de opções: excluir, denunciar, bloquear)
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Padding(
      padding: EdgeInsets.only(
        left: isReply ? 48 : 16,
        right: 16,
        top: isReply ? 4 : 8,
        bottom: isReply ? 4 : 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: onTapProfile,
            child: CircleAvatar(
              radius: isReply ? 14 : 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: (comment.authorPhotoUrl != null &&
                      comment.authorPhotoUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(comment.authorPhotoUrl!)
                  : null,
              child: (comment.authorPhotoUrl == null ||
                      comment.authorPhotoUrl!.isEmpty)
                  ? Icon(Icons.person, size: isReply ? 14 : 18, color: AppColors.primary)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Nome do autor
                    GestureDetector(
                      onTap: onTapProfile,
                      child: Text(
                        comment.authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isReply ? 12 : 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Timestamp
                    Text(
                      timeago.format(comment.createdAt, locale: 'pt_BR'),
                      style: TextStyle(
                        fontSize: isReply ? 10 : 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Indicador de resposta (ex: "@NomeDoUsuário")
                if (comment.isReply && comment.replyToName != null) ...[
                  Text(
                    '@${comment.replyToName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                // Texto do comentário
                Text(
                  comment.text,
                  style: TextStyle(
                    fontSize: isReply ? 13 : 14,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                // Botão Responder
                if (onReply != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onReply,
                    child: Text(
                      'Responder',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Botão curtir (coração + contagem)
          if (onToggleLike != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggleLike,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: isReply ? 18 : 21,
                      color: isLiked ? Colors.red : Colors.grey[400],
                    ),
                  ),
                ),
                if (likeCount > 0)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onViewLikers,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text(
                        '$likeCount',
                        style: TextStyle(
                          fontSize: isReply ? 13 : 14,
                          color: isLiked ? Colors.red : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    ),
    );
  }
}
