import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../domain/entities/entities.dart';

/// Bubble de mensagem no chat
///
/// Suporta:
/// - Mensagens de texto e imagem
/// - Reações com emoji
/// - Reply (resposta a outra mensagem)
/// - Status de entrega (sent/delivered/read)
/// - Edição e deleção
/// - Long press para ações
class MessageNewBubble extends StatelessWidget {
  const MessageNewBubble({
    required this.message,
    required this.isMine,
    required this.currentProfileId,
    this.onReactionTap,
    this.onLongPress,
    this.onReplyTap,
    this.onReactorsPressed,
    this.showAvatar = false,
    this.senderName,
    this.senderPhotoUrl,
    super.key,
  });

  /// Dados da mensagem
  final MessageNewEntity message;

  /// Se a mensagem é do usuário atual
  final bool isMine;

  /// ProfileId do usuário atual
  final String currentProfileId;

  /// Callback ao tocar em uma reação
  final void Function(String emoji)? onReactionTap;

  /// Callback ao pressionar longamente
  final VoidCallback? onLongPress;

  /// Callback ao tocar no reply
  final void Function(String messageId)? onReplyTap;

  /// ✅ Callback ao pressionar longamente nas reações (mostrar quem reagiu)
  final VoidCallback? onReactorsPressed;

  /// Se deve mostrar avatar (para mensagens recebidas)
  final bool showAvatar;

  /// Nome do remetente (para mensagens recebidas)
  final String? senderName;

  /// Foto do remetente (para mensagens recebidas)
  final String? senderPhotoUrl;

  @override
  Widget build(BuildContext context) {
    // Mensagem deletada para todos
    if (message.isDeletedForEveryone) {
      return _buildDeletedMessage();
    }

    // Mensagem deletada para mim
    if (message.isDeletedForProfile(currentProfileId)) {
      return const SizedBox.shrink();
    }

    // Mensagem de sistema
    if (message.isSystemMessage) {
      return _buildSystemMessage();
    }

    // ✅ Removido GestureDetector - long press é tratado na ChatNewPage
    return Padding(
        padding: EdgeInsets.only(
          left: isMine ? 48 : 8,
          right: isMine ? 8 : 48,
          top: 2,
          bottom: message.hasReactions ? 12 : 2,
        ),
        child: Row(
          mainAxisAlignment:
              isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar (apenas para mensagens recebidas)
            if (!isMine && showAvatar)
              _buildAvatar()
            else if (!isMine)
              const SizedBox(width: 36),

            const SizedBox(width: 8),

            // Bubble
            Flexible(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildBubble(context),

                  // Reações
                  if (message.hasReactions)
                    Positioned(
                      bottom: -10,
                      right: isMine ? null : 8,
                      left: isMine ? 8 : null,
                      child: _buildReactions(),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildAvatar() {
    final photoUrl = senderPhotoUrl ?? message.senderPhotoUrl;
    final name = senderName ?? message.senderName ?? '?';

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant,
      ),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildAvatarPlaceholder(name),
                errorWidget: (context, url, error) =>
                    _buildAvatarPlaceholder(name),
              ),
            )
          : _buildAvatarPlaceholder(name),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isMine ? AppColors.primary : AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMine ? 18 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply preview
          if (message.isReply) _buildReplyPreview(),

          // Imagem
          if (message.hasImage) _buildImage(),

          // Texto
          if (message.hasText || message.isEdited) _buildTextContent(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    final reply = message.replyTo!;

    return GestureDetector(
      onTap: () => onReplyTap?.call(reply.messageId),
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isMine ? Colors.white70 : AppColors.accent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reply.senderName ?? 'Usuário',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isMine ? Colors.white70 : AppColors.accent,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (reply.imageUrl != null) ...[
                  Icon(
                    Iconsax.image,
                    size: 12,
                    color: isMine ? Colors.white60 : AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    reply.preview,
                    style: TextStyle(
                      fontSize: 12,
                      color: isMine ? Colors.white60 : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft:
            message.hasText ? Radius.zero : Radius.circular(isMine ? 18 : 4),
        bottomRight:
            message.hasText ? Radius.zero : Radius.circular(isMine ? 4 : 18),
      ),
      child: CachedNetworkImage(
        imageUrl: message.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: AppColors.surfaceVariant,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: AppColors.surfaceVariant,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.image, color: AppColors.textHint),
              const SizedBox(height: 4),
              Text(
                'Erro ao carregar',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        message.hasImage ? 8 : 10,
        12,
        6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texto
          if (message.hasText)
            Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                color: isMine ? Colors.white : AppColors.textPrimary,
                height: 1.3,
              ),
            ),

          const SizedBox(height: 4),

          // Horário + editado + status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.isEdited) ...[
                Text(
                  'editada',
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine ? Colors.white54 : AppColors.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: isMine ? Colors.white54 : AppColors.textHint,
                ),
              ),
              if (isMine) ...[
                const SizedBox(width: 4),
                _buildStatusIcon(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color = Colors.white54;

    switch (message.status) {
      case MessageDeliveryStatus.sending:
        icon = Iconsax.clock;
        break;
      case MessageDeliveryStatus.sent:
        icon = Iconsax.tick_circle;
        break;
      case MessageDeliveryStatus.delivered:
        icon = Iconsax.tick_circle;
        color = Colors.white70;
        break;
      case MessageDeliveryStatus.read:
        icon = Iconsax.tick_circle5;
        color = Colors.white;
        break;
      case MessageDeliveryStatus.failed:
        icon = Iconsax.warning_2;
        color = AppColors.error;
        break;
    }

    return Icon(icon, size: 12, color: color);
  }

  Widget _buildReactions() {
    final reactionCounts = message.reactionCounts;
    final myReaction = message.getReactionByProfile(currentProfileId);

    return GestureDetector(
      onLongPress: () {
        // ✅ Long press mostra quem reagiu
        HapticFeedback.mediumImpact();
        onReactorsPressed?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: reactionCounts.entries.map((entry) {
            final isMyReaction = myReaction == entry.key;

            return GestureDetector(
              onTap: () => onReactionTap?.call(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: isMyReaction
                    ? BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 14)),
                    if (entry.value > 1) ...[
                      const SizedBox(width: 2),
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
        ),
      ),
    );
  }

  Widget _buildDeletedMessage() {
    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 48 : 44,
        right: isMine ? 8 : 48,
        top: 2,
        bottom: 2,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.slash,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  'Mensagem apagada',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 48),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
