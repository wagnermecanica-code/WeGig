import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../domain/entities/entities.dart';

/// Item de conversa na lista de mensagens
///
/// Exibe:
/// - Avatar do outro participante
/// - Nome do participante
/// - Preview da última mensagem
/// - Horário da última mensagem
/// - Badge de não lidas
/// - Indicadores de fixada/silenciada
class ConversationNewItem extends StatelessWidget {
  const ConversationNewItem({
    required this.conversation,
    required this.currentProfileId,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    super.key,
  });

  /// Dados da conversa
  final ConversationNewEntity conversation;

  /// ProfileId do usuário atual
  final String currentProfileId;

  /// Callback ao tocar no item
  final VoidCallback onTap;

  /// Callback ao pressionar longamente
  final VoidCallback? onLongPress;

  /// Se o item está selecionado (modo seleção)
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final otherParticipant = conversation.getOtherParticipantData(currentProfileId);
    final unreadCount = conversation.getUnreadCountForProfile(currentProfileId);
    final isPinned = conversation.isPinnedForProfile(currentProfileId);
    final isMuted = conversation.isMutedForProfile(currentProfileId);
    final isTyping = conversation.isOtherTyping(currentProfileId);

    return Material(
      color: isSelected ? AppColors.primaryLight : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(otherParticipant),
              const SizedBox(width: 12),

              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome + indicadores + horário
                    Row(
                      children: [
                        // Nome
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  otherParticipant?.name ?? 'Usuário',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: unreadCount > 0
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPinned) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Iconsax.attach_square5,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                              ],
                              if (isMuted) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Iconsax.volume_slash,
                                  size: 14,
                                  color: AppColors.textHint,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Horário
                        Text(
                          _formatTimestamp(conversation.lastMessageTimestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: unreadCount > 0
                                ? AppColors.accent
                                : AppColors.textHint,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Preview da mensagem + badge
                    Row(
                      children: [
                        Expanded(
                          child: isTyping
                              ? _buildTypingIndicator()
                              : _buildMessagePreview(unreadCount),
                        ),

                        // Badge de não lidas
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          _buildUnreadBadge(unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ParticipantData? participant) {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceVariant,
          ),
          child: participant?.photoUrl != null && participant!.photoUrl!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: participant.photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholderAvatar(participant.name),
                    errorWidget: (context, url, error) => _buildPlaceholderAvatar(participant.name),
                  ),
                )
              : _buildPlaceholderAvatar(participant?.name ?? '?'),
        ),

        // Indicador online
        if (participant?.isOnline == true)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMessagePreview(int unreadCount) {
    final preview = conversation.lastMessage;
    final isFromMe = conversation.lastMessageSenderId == currentProfileId;

    return Row(
      children: [
        if (isFromMe) ...[
          Icon(
            Iconsax.tick_circle,
            size: 14,
            color: AppColors.textHint,
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            preview.isEmpty ? 'Conversa iniciada' : preview,
            style: TextStyle(
              fontSize: 14,
              color: unreadCount > 0
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight:
                  unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Text(
          'digitando',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.accent,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 4),
        _TypingDots(),
      ],
    );
  }

  Widget _buildUnreadBadge(int count) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: count > 9 ? 6 : 0,
        vertical: 0,
      ),
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      // Hoje: mostrar horário
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ontem';
    } else if (diff.inDays < 7) {
      return timeago.format(timestamp, locale: 'pt_BR');
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

/// Animação de pontos de digitação
class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            final opacity = value < 0.5 ? value * 2 : 2 - value * 2;

            return Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
