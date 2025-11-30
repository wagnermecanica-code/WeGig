import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/widgets/empty_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/features/messages/presentation/pages/chat_detail_page.dart';
// import 'package:wegig_app/models/profile.dart';
import 'package:wegig_app/features/notifications/domain/services/notification_service.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

/// Tela de notificações unificada
/// Exibe todos os tipos de notificações com suporte a ações

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Pagination state
  final Map<String, bool> _hasMore = {};
  final Map<String, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize timeago locale to Portuguese
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());

    // Initialize scroll controllers for each tab (3 tabs agora)
    for (var i = 0; i < 2; i++) {
      final controller = ScrollController();
      _scrollControllers['tab_$i'] = controller;
      controller.addListener(() => _onScroll(i));
    }
  }

  void _onScroll(int tabIndex) {
    final key = 'tab_$tabIndex';
    final controller = _scrollControllers[key];
    if (controller == null) return;

    // Load more when scrolled to 80% of the list
    if (controller.position.pixels >=
        controller.position.maxScrollExtent * 0.8) {
      final hasMore = _hasMore[key] ?? true;
      if (hasMore) {
        // Trigger load more (will be implemented in StreamBuilder)
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();

    // Dispose scroll controllers
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Você precisa estar logado para ver as notificações'),
        ),
      );
    }

    final profileState = ref.watch(profileProvider);
    final activeProfile = profileState.value?.activeProfile;
    if (activeProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final currentProfileId = activeProfile.profileId;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(currentProfileId),
      body: _buildBody(currentProfileId),
    );
  }

  PreferredSizeWidget _buildAppBar(String currentProfileId) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: const Text(
        'Notificações',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      actions: [
        Consumer(
          builder: (context, ref, _) {
            final profileState = ref.watch(profileProvider);
            final activeProfile = profileState.value?.activeProfile;
            if (activeProfile == null) return const SizedBox.shrink();
            return StreamBuilder<int>(
              stream: FirebaseFirestore.instance
                  .collection('profiles')
                  .doc(activeProfile.profileId)
                  .collection('notifications')
                  .where('read', isEqualTo: false)
                  .snapshots()
                  .map((snap) => snap.size),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return count > 0
                    ? Badge(
                        label: Text('$count'),
                        child: const Icon(Icons.notifications))
                    : const Icon(Icons.notifications_outlined);
              },
            );
          },
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'Todas'),
          Tab(text: 'Interesses'),
        ],
      ),
    );
  }

  Widget _buildBody(String currentProfileId) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildNotificationsList(currentProfileId, null),
        _buildNotificationsList(currentProfileId, NotificationType.interest),
      ],
    );
  }

  Widget _buildNotificationsList(
      String currentProfileId, NotificationType? type) {
    final tabIndex =
        type == null ? 0 : (type == NotificationType.interest ? 1 : 2);
    final key = 'tab_$tabIndex';
    final controller = _scrollControllers[key];

    return StreamBuilder<List<NotificationEntity>>(
      stream: ref
          .read(notificationServiceProvider)
          .getNotifications(currentProfileId, type: type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar notificações',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return _buildEmptyState(type);
        }

        return ListView.builder(
          controller: controller,
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return _buildNotificationItem(notifications[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(NotificationType? type) {
    String title;
    String subtitle;
    IconData icon;
    String? actionLabel;
    VoidCallback? onActionPressed;

    switch (type) {
      case NotificationType.interest:
        title = 'Nenhum interesse ainda';
        subtitle =
            'Quando alguém demonstrar interesse em seus posts, você será notificado aqui.';
        icon = Icons.favorite_border;
        actionLabel = 'Criar novo post';
        onActionPressed = () {
          Navigator.of(context).pushNamed('/post');
        };
      case NotificationType.newMessage:
        title = 'Nenhuma mensagem nova';
        subtitle =
            'Você ainda não recebeu mensagens. Inicie uma conversa para começar a trocar ideias!';
        icon = Icons.message;
        actionLabel = 'Iniciar nova conversa';
        onActionPressed = () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Nova Conversa')),
                body: const Center(child: Text('Em desenvolvimento')),
              ),
            ),
          );
        };
      default:
        title = 'Nenhuma notificação';
        subtitle =
            'Ative as notificações para não perder novidades e oportunidades.';
        icon = Icons.notifications_none;
        actionLabel = 'Ativar notificações';
        onActionPressed = () {
          // Aqui pode abrir configurações ou mostrar instrução
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Ajuste as permissões de notificação nas configurações do sistema.')),
          );
        };
    }

    return EmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  Widget _buildNotificationItem(NotificationEntity notification) {
    return Dismissible(
      key: Key(notification.notificationId),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Notificação removida'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Erro ao remover: $e'),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      child: ColoredBox(
        color: notification.read
            ? Colors.white
            : AppColors.primary.withValues(alpha: 0.05),
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildNotificationIcon(notification),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
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

  Widget _buildNotificationIcon(NotificationEntity notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.interest:
        icon = Icons.favorite;
        color = Colors.pink;
      case NotificationType.newMessage:
        icon = Icons.message;
        color = AppColors.primary;
      case NotificationType.postExpiring:
        icon = Icons.schedule;
        color = Colors.orange;
      case NotificationType.nearbyPost:
        icon = Icons.location_on;
        color = Colors.green;
      case NotificationType.profileMatch:
        icon = Icons.people;
        color = AppColors.accent;
      case NotificationType.interestResponse:
        icon = Icons.reply;
        color = Colors.blue;
      case NotificationType.postUpdated:
        icon = Icons.edit;
        color = Colors.grey;
      case NotificationType.profileView:
        icon = Icons.visibility;
        color = Colors.purple;
      case NotificationType.system:
        icon = Icons.info;
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
              backgroundColor: color.withOpacity(0.2),
              child: Icon(Icons.person, size: 28, color: color),
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
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, size: 28, color: color),
    );
  }

  Future<void> _handleNotificationTap(NotificationEntity notification) async {
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

    if (!mounted) return;

    // Executar ação baseada no tipo
    switch (notification.actionType) {
      case NotificationActionType.viewProfile:
        final userId = notification.actionData?['userId'] as String?;
        final profileId = notification.actionData?['profileId'] as String?;
        if (userId != null) {
          context.pushProfile(profileId ?? userId);
        }

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
            MaterialPageRoute(
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

      case NotificationActionType.viewPost:
        final postId = notification.actionData?['postId'] as String?;
        if (postId != null) {
          // TODO: Implementar navegação para detalhes do post
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Visualizar post (em desenvolvimento)')),
          );
        }

      case NotificationActionType.renewPost:
        final postId = notification.actionData?['postId'] as String?;
        if (postId != null) {
          // TODO: Implementar renovação de post
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Renovar post (em desenvolvimento)')),
          );
        }

      default:
        break;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    // Use timeago package for better internationalization
    return timeago.format(dateTime, locale: 'pt_BR');
  }
}
