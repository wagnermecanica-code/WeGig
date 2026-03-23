import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../domain/entities/entities.dart';

/// Item de conversa na lista de mensagens
///
/// Exibe:
/// - Avatar do outro participante (ou avatares empilhados para grupos)
/// - Nome do participante ou nome do grupo
/// - Preview da última mensagem (com nome do remetente em grupos)
/// - Horário da última mensagem
/// - Badge de não lidas
/// - Indicadores de fixada/silenciada
/// - Ícone de grupo para conversas em grupo
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

  /// Verifica se é uma conversa em grupo
  bool get _isGroup => 
      conversation.isGroup || conversation.participantProfiles.length > 2;

  /// Nome para exibição (nome do grupo ou nome do outro participante)
  String get _displayName {
    if (_isGroup) {
      return conversation.groupName?.isNotEmpty == true
          ? conversation.groupName!
          : 'Grupo';
    }
    return conversation.getOtherParticipantData(currentProfileId)?.name ?? 'Usuário';
  }

  /// Obtém os outros participantes (excluindo o usuário atual)
  List<ParticipantData> get _otherParticipants {
    return conversation.participantsData
        .where((p) => p.profileId != currentProfileId)
        .toList();
  }

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
              // Avatar (empilhado para grupos, simples para 1:1)
              if (_isGroup)
                _buildGroupAvatar()
              else
                _buildSingleAvatar(otherParticipant),
              const SizedBox(width: 12),

              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome + indicadores + horário
                    Row(
                      children: [
                        // Ícone de grupo (se aplicável)
                        if (_isGroup) ...[
                          Icon(
                            Iconsax.people,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        // Nome
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _displayName,
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

  /// Avatar para conversas 1:1
  Widget _buildSingleAvatar(ParticipantData? participant) {
    return Stack(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: participant?.photoUrl != null && participant!.photoUrl!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: participant.photoUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    memCacheWidth: 112,
                    memCacheHeight: 112,
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

  /// Avatar empilhado para grupos (estilo Instagram/WhatsApp)
  Widget _buildGroupAvatar() {
    final participants = _otherParticipants;
    
    // Se tem foto de grupo, usa ela
    if (conversation.groupPhotoUrl != null && 
        conversation.groupPhotoUrl!.isNotEmpty) {
      return SizedBox(
        width: 56,
        height: 56,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: conversation.groupPhotoUrl!,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            memCacheWidth: 112,
            memCacheHeight: 112,
            placeholder: (context, url) => _buildGroupPlaceholder(),
            errorWidget: (context, url, error) => _buildGroupPlaceholder(),
          ),
        ),
      );
    }

    // Sem foto de grupo: mostrar avatares empilhados (máximo 2)
    if (participants.isEmpty) {
      return _buildGroupPlaceholderContainer();
    }

    if (participants.length == 1) {
      return _buildSingleAvatar(participants.first);
    }

    // 2+ participantes: avatares empilhados
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar de trás (segundo participante)
          Positioned(
            top: 0,
            right: 0,
            child: _buildSmallAvatar(
              participants.length > 1 ? participants[1] : null,
              size: 36,
            ),
          ),
          // Avatar da frente (primeiro participante)
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: _buildSmallAvatar(participants.first, size: 36),
            ),
          ),
          // Badge com número de participantes extras
          if (participants.length > 2)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '+${participants.length - 2}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Avatar pequeno para composição de grupo
  Widget _buildSmallAvatar(ParticipantData? participant, {required double size}) {
    return SizedBox(
      width: size,
      height: size,
      child: participant?.photoUrl != null && participant!.photoUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: participant.photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: (size * 2).toInt(),
                memCacheHeight: (size * 2).toInt(),
                placeholder: (context, url) => _buildPlaceholderAvatar(
                  participant.name,
                  fontSize: size * 0.4,
                ),
                errorWidget: (context, url, error) => _buildPlaceholderAvatar(
                  participant.name,
                  fontSize: size * 0.4,
                ),
              ),
            )
          : _buildPlaceholderAvatar(
              participant?.name ?? '?',
              fontSize: size * 0.4,
            ),
    );
  }

  /// Placeholder para grupo (ícone de pessoas)
  Widget _buildGroupPlaceholder() {
    return Center(
      child: Icon(
        Iconsax.people,
        size: 28,
        color: AppColors.textSecondary,
      ),
    );
  }

  /// Container com placeholder de grupo
  Widget _buildGroupPlaceholderContainer() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant,
      ),
      child: _buildGroupPlaceholder(),
    );
  }

  Widget _buildPlaceholderAvatar(String name, {double fontSize = 24}) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMessagePreview(int unreadCount) {
    final preview = conversation.lastMessage;
    final isFromMe = conversation.lastMessageSenderId == currentProfileId;
    final status = conversation.lastMessageStatus;

    // Para grupos, mostrar nome do remetente
    String? senderName;
    if (_isGroup && !isFromMe && conversation.lastMessageSenderId != null) {
      final sender = conversation.participantsData.firstWhere(
        (p) => p.profileId == conversation.lastMessageSenderId,
        orElse: () => const ParticipantData(
          profileId: '',
          uid: '',
          name: 'Alguém',
        ),
      );
      senderName = sender.name.split(' ').first; // Primeiro nome apenas
    }

    return Row(
      children: [
        if (isFromMe && !_isGroup) ...[
          _buildStatusIcon(status),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                // Nome do remetente em grupos
                if (isFromMe && _isGroup)
                  TextSpan(
                    text: 'Você: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (senderName != null)
                  TextSpan(
                    text: '$senderName: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                // Conteúdo da mensagem
                TextSpan(
                  text: preview.isEmpty ? 'Conversa iniciada' : preview,
                  style: TextStyle(
                    fontSize: 14,
                    color: unreadCount > 0
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(MessageDeliveryStatus status) {
    late final IconData icon;
    Color color = AppColors.textHint;

    switch (status) {
      case MessageDeliveryStatus.sending:
        icon = Iconsax.clock;
        break;
      case MessageDeliveryStatus.sent:
        icon = Iconsax.tick_circle;
        break;
      case MessageDeliveryStatus.delivered:
        icon = Iconsax.tick_circle;
        color = AppColors.textSecondary;
        break;
      case MessageDeliveryStatus.read:
        icon = Iconsax.tick_circle;
        color = AppColors.success;
        break;
      case MessageDeliveryStatus.failed:
        icon = Iconsax.warning_2;
        color = AppColors.error;
        break;
    }

    return Transform.translate(
      offset: const Offset(-2, 0),
      child: Icon(icon, size: 14, color: color),
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
