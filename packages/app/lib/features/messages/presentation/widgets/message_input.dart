import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Input de mensagem com campo de texto e ações
/// Permite enviar texto, imagens e mostra preview de reply
class MessageInput extends StatelessWidget {
  const MessageInput({
    required this.messageController,
    required this.messageFocusNode,
    required this.replyingTo,
    required this.isUploading,
    required this.onSendMessage,
    required this.onSendImage,
    required this.onCancelReply,
    super.key,
  });

  final TextEditingController messageController;
  final FocusNode messageFocusNode;
  final Map<String, dynamic>? replyingTo;
  final bool isUploading;
  final VoidCallback onSendMessage;
  final VoidCallback onSendImage;
  final VoidCallback onCancelReply;

  static const Color _primaryColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview
          if (replyingTo != null) _buildReplyPreview(),

          // Input row
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Gallery button
                  IconButton(
                    icon: const Icon(
                      Iconsax.gallery,
                      color: _primaryColor,
                    ),
                    onPressed: isUploading ? null : onSendImage,
                  ),

                  // Text field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: messageController,
                        focusNode: messageFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Mensagem...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !isUploading,
                      ),
                    ),
                  ),

                  // Send button
                  IconButton(
                    icon: Icon(
                      isUploading ? Iconsax.clock : Iconsax.send_2,
                      color: _primaryColor,
                    ),
                    onPressed: isUploading ? null : onSendMessage,
                  ),
                ],
              ),
            ),
          ),

          // Upload progress
          if (isUploading)
            const LinearProgressIndicator(
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    final replyText = replyingTo!['text'] as String? ?? '';
    final replyImage = replyingTo!['imageUrl'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: const Border(
          left: BorderSide(
            color: _primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Respondendo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  replyText.isNotEmpty
                      ? replyText
                      : (replyImage.isNotEmpty ? '📷 Foto' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.close_circle, size: 22),
            onPressed: onCancelReply,
          ),
        ],
      ),
    );
  }
}
