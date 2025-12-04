import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:core_ui/theme/app_colors.dart';
import 'package:iconsax/iconsax.dart';

/// Widget reutilizável para item de conversa na lista
/// Otimizado com CachedNetworkImage e timeago internacionalizado
class ConversationItem extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onToggleSelection;
  final Future<void> Function(String) onDelete;
  final Future<void> Function(String) onArchive;

  const ConversationItem({
    super.key,
    required this.conversation,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    this.onToggleSelection,
    required this.onDelete,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final conversationId = conversation['conversationId'] as String;

    final currentProfileId = conversation['currentProfileId'] as String?;
    final rawUnreadCount = conversation['unreadCount'];
    int unreadCount = 0;
    if (rawUnreadCount is int) {
      unreadCount = rawUnreadCount;
    } else if (rawUnreadCount is Map) {
      if (currentProfileId != null && currentProfileId.isNotEmpty) {
        final value = rawUnreadCount[currentProfileId];
        if (value is int) {
          unreadCount = value;
        }
      }
      if (unreadCount == 0 && rawUnreadCount.values.isNotEmpty) {
        final fallback = rawUnreadCount.values.first;
        if (fallback is int) {
          unreadCount = fallback;
        }
      }
    }
    final hasUnread = unreadCount > 0;

    // Tratar timestamp que pode vir como Timestamp ou int (do cache)
    final rawTimestamp = conversation['lastMessageTimestamp'];
    final Timestamp? timestamp = rawTimestamp is Timestamp
        ? rawTimestamp
        : rawTimestamp is int
            ? Timestamp.fromMillisecondsSinceEpoch(rawTimestamp)
            : null;

    final isOnline = (conversation['isOnline'] as bool?) ?? false;
    final type = conversation['type'] as String? ?? 'musician';

    final primaryColor = AppColors.primary;
    final secondaryColor = AppColors.accent;
    const textPrimary = Color(0xFF212121);
    const textSecondary = Color(0xFF757575);
    const textTertiary = Color(0xFF9E9E9E);

    // Formata tempo relativo com timeago (internacionalizado)
    String timeAgo = '';
    if (timestamp != null) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        timeAgo = '${date.day}/${date.month}/${date.year}';
      } else {
        timeAgo = timeago.format(date, locale: 'pt_BR');
      }
    }

    return Dismissible(
      key: ValueKey('conversation_$conversationId'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.trash, color: Colors.white, size: 34),
            SizedBox(height: 4),
            Text(
              'Apagar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.orange,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.sms, color: Colors.white, size: 34),
            SizedBox(height: 4),
            Text(
              'Não lida',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Arrastar para ESQUERDA = Apagar (solicitar confirmação)
          final confirmed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Iconsax.trash, color: Colors.red),
                  const SizedBox(width: 12),
                  const Text('Apagar conversa'),
                ],
              ),
              content: const Text(
                'Deseja realmente apagar esta conversa? Esta ação não pode ser desfeita.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apagar'),
                ),
              ],
            ),
          );
          return confirmed ?? false;
        } else if (direction == DismissDirection.endToStart) {
          // Arrastar para DIREITA = Marcar como não lida
          // Marcar conversa como não lida (incrementar unreadCount)
          try {
            await FirebaseFirestore.instance
                .collection('conversations')
                .doc(conversationId)
                .update({
              'unreadCount.${conversation['otherProfileId']}': FieldValue.increment(1),
            });
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Iconsax.tick_circle, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      const Text('Marcada como não lida'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            debugPrint('Erro ao marcar como não lida: $e');
          }
          return false; // Não remove da lista
        }
        return false;
      },
      child: Material(
        color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          splashColor: primaryColor.withValues(alpha: 0.2),
          highlightColor: primaryColor.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Checkbox no modo seleção
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggleSelection?.call(),
                      activeColor: primaryColor,
                    ),
                  ),

                // Avatar com status online e Hero animation
                Hero(
                  tag: 'avatar_$conversationId',
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: type == 'band'
                            ? secondaryColor.withValues(alpha: 0.2)
                            : primaryColor.withValues(alpha: 0.2),
                        child: conversation['otherUserPhoto'] != null &&
                                (conversation['otherUserPhoto'] as String).isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: conversation['otherUserPhoto'],
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    type == 'band' ? Iconsax.people : Iconsax.user,
                                    size: 28,
                                    color: type == 'band' ? secondaryColor : primaryColor,
                                  ),
                                  memCacheWidth: 112,
                                  memCacheHeight: 112,
                                  fadeInDuration: Duration.zero,
                                  maxWidthDiskCache: 112,
                                  maxHeightDiskCache: 112,
                                ),
                              )
                            : Icon(
                                type == 'band' ? Icons.group : Icons.person,
                                size: 28,
                                color: type == 'band' ? secondaryColor : primaryColor,
                              ),
                      ),
                      // Indicador de status online
                      if (isOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Nome, última mensagem e hora
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Nome do usuário
                          Expanded(
                            child: Text(
                              conversation['otherUserName'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Hora
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread ? primaryColor : textTertiary,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Preview da última mensagem
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation['lastMessage'],
                              style: TextStyle(
                                fontSize: 14,
                                color: hasUnread ? textSecondary : textTertiary,
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badge de mensagens não lidas
                          if (hasUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.badgeRed,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
