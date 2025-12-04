import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:iconsax/iconsax.dart';
import 'package:linkify/linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/features/messages/utils/mention_linkifier.dart';

/// Widget de bolha de mensagem (Instagram Direct style)
/// Exibe mensagem de texto, imagem, reações e reply preview
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.isMyMessage,
    required this.showTimestamp,
    required this.currentProfileId,
    required this.onReply,
    required this.onReact,
    required this.onCopy,
    required this.onDelete,
    super.key,
  });

  final Map<String, dynamic> message;
  final bool isMyMessage;
  final bool showTimestamp;
  final String? currentProfileId;
  final VoidCallback onReply;
  final void Function(String emoji) onReact;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  // Paleta de cores
  static const Color _primaryColor = AppColors.primary;
  static const Color _myMessageColor = AppColors.primary;
  static const Color _otherMessageColor = AppColors.surfaceVariant;
  static const Color _reactionBgColor = AppColors.divider;

  @override
  Widget build(BuildContext context) {
    final text = (message['text'] as String?) ?? '';
    final imageUrl = (message['imageUrl'] as String?) ?? '';
    final replyTo = message['replyTo'] as Map<String, dynamic>?;
    final reactions = (message['reactions'] as Map<String, dynamic>?) ?? {};
    final timestamp = message['timestamp'] as Timestamp?;
    final read = message['read'] as bool? ?? false;

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Timestamp divider
          if (showTimestamp) _buildTimestampDivider(timestamp),

          // Message bubble
          GestureDetector(
            onLongPress: () => _showContextMenu(context),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isMyMessage ? _myMessageColor : _otherMessageColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reply preview
                  if (replyTo != null) _buildReplyPreview(replyTo),

                  // Image
                  if (imageUrl.isNotEmpty) _buildImage(imageUrl),

                  // Text
                  if (text.isNotEmpty) _buildText(text, context),

                  // Time + Read indicator
                  _buildFooter(timestamp, read),
                ],
              ),
            ),
          ),

          // Reactions
          if (reactions.isNotEmpty) _buildReactions(reactions),
        ],
      ),
    );
  }

  Widget _buildTimestampDivider(Timestamp? timestamp) {
    if (timestamp == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    String label;

    if (messageTime.year == now.year &&
        messageTime.month == now.month &&
        messageTime.day == now.day) {
      label = 'Hoje';
    } else if (messageTime.year == now.year &&
        messageTime.month == now.month &&
        messageTime.day == now.day - 1) {
      label = 'Ontem';
    } else {
      label =
          '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(Map<String, dynamic> replyTo) {
    final replyText = replyTo['text'] as String? ?? '';
    final replyImage = replyTo['imageUrl'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMyMessage ? Colors.white : _primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: replyImage,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                memCacheWidth: 80,
                memCacheHeight: 80,
              ),
            ),
          if (replyImage.isNotEmpty) const SizedBox(width: 8),
          Flexible(
            child: Text(
              replyText.isNotEmpty ? replyText : '📷 Foto',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isMyMessage
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        memCacheWidth: 600,
        memCacheHeight: 600,
        placeholder: (_, __) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(child: Icon(Iconsax.gallery_slash)),
        ),
      ),
    );
  }

  Widget _buildText(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Linkify(
        text: text,
        linkifiers: <Linkifier>[
          ...defaultLinkifiers,
          const MentionLinkifier(),
        ],
        style: TextStyle(
          fontSize: 15,
          color: isMyMessage ? Colors.white : Colors.black87,
          height: 1.4,
        ),
        linkStyle: TextStyle(
          fontSize: 15,
          color: isMyMessage ? Colors.white : _primaryColor,
          decoration: TextDecoration.none,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        onOpen: (link) async {
          if (link is MentionElement) {
            context.pushProfileByUsername(link.username);
            return;
          }

          try {
            final uri = Uri.parse(link.url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            }
          } catch (e) {
            debugPrint('Erro ao abrir link: $e');
            AppSnackBar.showError(
              context,
              'Não foi possível abrir o link',
            );
          }
        },
      ),
    );
  }

  Widget _buildFooter(Timestamp? timestamp, bool read) {
    final label = timestamp != null
        ? _formatTime(timestamp.toDate())
        : (read ? 'Enviado' : 'Enviando...');

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isMyMessage
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.black54,
            ),
          ),
          if (isMyMessage) ...[
            const SizedBox(width: 4),
            Icon(
              read ? Iconsax.tick_square : Iconsax.tick_circle,
              size: 14,
              color:
                  read ? Colors.lightBlue : Colors.white.withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReactions(Map<String, dynamic> reactions) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _reactionBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '${entry.key} ${reactions.length > 1 ? reactions.length : ''}',
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.arrow_left),
              title: const Text('Responder'),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.emoji_happy),
              title: const Text('Reagir'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(context);
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.copy),
              title: const Text('Copiar'),
              onTap: () {
                Navigator.pop(context);
                onCopy();
              },
            ),
            if (isMyMessage)
              ListTile(
                leading: const Icon(Iconsax.trash, color: Colors.red),
                title: const Text('Excluir', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    final emojis = ['❤️', '👍', '😂', '😮', '😢', '🙏'];
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emojis.map((emoji) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onReact(emoji);
                },
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
