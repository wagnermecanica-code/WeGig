import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/widgets/mention_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/features/messages/presentation/pages/chat_detail_page.dart';
import 'package:wegig_app/features/notifications/domain/services/notification_service.dart';
import 'package:wegig_app/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wegig_app/features/notifications/presentation/widgets/notification_location_row.dart';

/// Widget extraído para exibir um item de notificação individual
///
/// ⚡ PERFORMANCE OPTIMIZATION: Extraído de notifications_page.dart
/// - Reduz complexidade do build method
/// - Facilita manutenção e testes
/// - Permite otimizações futuras (const constructor, etc)
class NotificationItem extends ConsumerWidget {
  const NotificationItem({
    required this.notification,
    super.key,
  });

  final NotificationEntity notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(notification.notificationId),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Iconsax.trash, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remover notificação'),
            content: const Text('Deseja remover esta notificação?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Remover'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        try {
          await ref
              .read(notificationServiceProvider)
              .deleteNotification(notification.notificationId);
          if (context.mounted) {
            AppSnackBar.showSuccess(
              context,
              'Notificação removida',
            );
          }
        } catch (e) {
          if (context.mounted) {
            AppSnackBar.showError(
              context,
              'Erro ao remover: $e',
            );
          }
        }
      },
      child: ColoredBox(
        color: notification.read
            ? Colors.white
            : AppColors.primary.withValues(alpha: 0.05),
        child: InkWell(
          onTap: () => _handleNotificationTap(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildNotificationIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MentionText(
                        text: _buildTitleText(notification),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        onMentionTap: (username) =>
                            context.pushProfileByUsername(username),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      NotificationLocationRow(notification: notification),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimeAgo(notification.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.read) const SizedBox(width: 8),
                if (!notification.read)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(width: 10, height: 10),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildTitleText(NotificationEntity notification) {
    final baseTitle = notification.title.trim();
    final username = notification.senderUsername;
    if (username == null || username.trim().isEmpty) {
      return baseTitle;
    }

    final cleaned = username.trim();
    final mention = cleaned.startsWith('@') ? cleaned : '@$cleaned';
    final normalizedTitle = baseTitle.toLowerCase();
    if (normalizedTitle.contains(mention.toLowerCase())) {
      return baseTitle;
    }

    if (baseTitle.isEmpty) {
      return mention;
    }

    return '$mention $baseTitle';
  }

  Widget _buildNotificationIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.interest:
        icon = Iconsax.heart5;
        color = Colors.pink;
      case NotificationType.newMessage:
        icon = Iconsax.message;
        color = AppColors.primary;
      case NotificationType.postExpiring:
        icon = Iconsax.clock;
        color = Colors.orange;
      case NotificationType.nearbyPost:
        icon = Iconsax.location;
        color = Colors.green;
      case NotificationType.profileMatch:
        icon = Iconsax.people;
        color = AppColors.accent;
      case NotificationType.interestResponse:
        icon = Iconsax.arrow_left_2;
        color = Colors.blue;
      case NotificationType.postUpdated:
        icon = Iconsax.edit;
        color = Colors.grey;
      case NotificationType.profileView:
        icon = Iconsax.eye;
        color = Colors.purple;
      case NotificationType.system:
        icon = Iconsax.info_circle;
        color = Colors.teal;
    }

    if (notification.senderPhoto != null &&
        notification.senderPhoto!.isNotEmpty) {
      return Stack(
        children: [
          CachedNetworkImage(
            imageUrl: notification.senderPhoto!,
            imageBuilder: (context, imageProvider) => CircleAvatar(
              radius: 28,
              backgroundImage: imageProvider,
            ),
            placeholder: (context, url) => CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (context, url, error) => CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(Iconsax.user, size: 28, color: color),
            ),
            memCacheWidth: 112, // 28 * 2 * devicePixelRatio (assume 2x)
            memCacheHeight: 112,
            fadeInDuration: Duration.zero,
            maxWidthDiskCache: 112,
            maxHeightDiskCache: 112,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(icon, size: 12, color: Colors.white),
            ),
          ),
        ],
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(icon, size: 28, color: color),
    );
  }

  Future<void> _handleNotificationTap(BuildContext context, WidgetRef ref) async {
    // Marcar como lida
    if (!notification.read) {
      try {
        await ref
            .read(notificationServiceProvider)
            .markAsRead(notification.notificationId);
      } catch (e) {
        // Não bloqueia a navegação
      }
    }

    if (!context.mounted) return;

    // Executar ação baseada no tipo
    switch (notification.actionType) {
      case NotificationActionType.viewProfile:
        final userId = notification.actionData?['userId'] as String?;
        final profileId = notification.actionData?['profileId'] as String?;
        if (userId != null) {
          context.pushProfile(profileId ?? userId);
        }
        return;

      case NotificationActionType.openChat:
        final conversationId =
            notification.actionData?['conversationId'] as String?;
        final otherUserId = notification.actionData?['otherUserId'] as String?;
        final otherProfileId =
            notification.actionData?['otherProfileId'] as String?;

        if (conversationId != null &&
            otherUserId != null &&
            otherProfileId != null) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChatDetailPage(
                conversationId: conversationId,
                otherUserId: otherUserId,
                otherProfileId: otherProfileId,
                otherUserName: notification.senderName ?? 'Usuário',
                otherUserPhoto: notification.senderPhoto ?? '',
              ),
            ),
          );
        }
        return;

      case NotificationActionType.viewPost:
        final postId = notification.targetId;
        if (postId != null) {
          await _openPostDetail(context, ref, postId);
        }
        return;

      case NotificationActionType.renewPost:
        final postId = notification.actionData?['postId'] as String?;
        if (postId != null) {
          debugPrint('🔄 NotificationItem: Solicitando renovação de post $postId');
          
          // Renovar post (atualizar expiresAt para +30 dias)
          try {
            final now = DateTime.now();
            final newExpiresAt = now.add(const Duration(days: 30));
            
            await FirebaseFirestore.instance
                .collection('posts')
                .doc(postId)
                .update({
              'expiresAt': Timestamp.fromDate(newExpiresAt),
              'renewedAt': Timestamp.now(),
              'renewCount': FieldValue.increment(1),
            });
            
            debugPrint('✅ Post $postId renovado até ${newExpiresAt.toIso8601String()}');
            
            if (context.mounted) {
              AppSnackBar.showSuccess(
                context,
                'Post renovado por mais 30 dias! 🎉',
              );
            }
            
            // Marcar notificação como lida após renovação
            await ref.read(markNotificationAsReadUseCaseProvider)(
              notificationId: notification.notificationId,
              profileId: notification.recipientProfileId,
            );
          } catch (e) {
            debugPrint('❌ Erro ao renovar post: $e');
            if (context.mounted) {
              AppSnackBar.showError(
                context,
                'Erro ao renovar post: $e',
              );
            }
          }
        }
        return;

      default:
        break;
    }

    // Fallback: notificações de interesse sempre abrem o post
    if (notification.type == NotificationType.interest) {
      final postId = notification.targetId;
      if (postId != null) {
        await _openPostDetail(context, ref, postId);
      }
    }
  }

  Future<void> _openPostDetail(
    BuildContext context,
    WidgetRef ref,
    String postId,
  ) async {
    debugPrint('📍 NotificationItem: Navegando para post $postId');
    context.push(AppRoutes.postDetail(postId));

    try {
      await ref.read(markNotificationAsReadUseCaseProvider)(
        notificationId: notification.notificationId,
        profileId: notification.recipientProfileId,
      );
    } catch (e) {
      debugPrint('⚠️ Erro ao marcar notificação como lida: $e');
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    // Use timeago package for better internationalization
    return timeago.format(dateTime, locale: 'pt_BR');
  }
}
