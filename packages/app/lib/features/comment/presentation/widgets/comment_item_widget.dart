import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wegig_app/features/comment/domain/entities/comment_entity.dart';

/// Widget para exibir um comentário individual no bottom sheet.
class CommentItemWidget extends StatelessWidget {
  const CommentItemWidget({
    required this.comment,
    required this.isOwnComment,
    this.canDelete = false,
    this.isReply = false,
    this.isLiked = false,
    this.likeCount = 0,
    this.onDelete,
    this.onReply,
    this.onToggleLike,
    this.onViewLikers,
    this.onLongPress,
    this.onTapProfile,
    super.key,
  });

  final CommentEntity comment;
  final bool isOwnComment;
  final bool canDelete;
  final bool isReply;
  final bool isLiked;
  final int likeCount;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final VoidCallback? onToggleLike;
  final VoidCallback? onViewLikers;
  final VoidCallback? onLongPress;
  final VoidCallback? onTapProfile;

  @override
  Widget build(BuildContext context) {
    final likeHitPadding = EdgeInsets.symmetric(
      horizontal: isReply ? 8 : 10,
      vertical: isReply ? 6 : 8,
    );

    final avatarRadius = isReply ? 14.0 : 18.0;
    final contentPadding = EdgeInsets.only(
      left: isReply ? 48 : 16,
      right: 16,
      top: isReply ? 4 : 8,
      bottom: isReply ? 4 : 8,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: Padding(
        padding: contentPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTapProfile,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: (comment.authorPhotoUrl != null &&
                        comment.authorPhotoUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(comment.authorPhotoUrl!)
                    : null,
                child: (comment.authorPhotoUrl == null ||
                        comment.authorPhotoUrl!.isEmpty)
                    ? Icon(
                        Icons.person,
                        size: isReply ? 14 : 18,
                        color: AppColors.primary,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onTapProfile,
                          child: Text(
                            comment.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isReply ? 12 : 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
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
                  if (comment.isReply && comment.replyToName != null) ...[
                    Text(
                      '@${comment.replyToName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    comment.text,
                    style: TextStyle(
                      fontSize: isReply ? 13 : 14,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (onReply != null)
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
                      if (canDelete && onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: Text(
                            'Excluir',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (isOwnComment)
                        Text(
                          'Seu comentário',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (onToggleLike != null || likeCount > 0)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onToggleLike != null)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onToggleLike,
                      child: Padding(
                        padding: likeHitPadding,
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
                        padding: EdgeInsets.only(
                          left: likeHitPadding.horizontal / 2,
                          right: likeHitPadding.horizontal / 2,
                          top: 0,
                          bottom: isReply ? 2 : 4,
                        ),
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
