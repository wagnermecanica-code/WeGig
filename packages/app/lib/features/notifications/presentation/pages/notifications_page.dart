import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/widgets/empty_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wegig_app/features/notifications/domain/services/notification_service.dart';
import 'package:wegig_app/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:wegig_app/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:wegig_app/features/notifications/presentation/widgets/notification_error_state.dart';
import 'package:wegig_app/features/notifications/presentation/widgets/notification_item.dart';
import 'package:wegig_app/features/notifications/presentation/widgets/notification_skeleton_tile.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

/// Tela de notificações unificada
class NotificationsPage extends ConsumerStatefulWidget {
  /// Constrói a página de notificações com abas de filtro.
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

/// State backing the notifications tabs with pagination and refresh logic.
class _NotificationsPageState extends ConsumerState<NotificationsPage>
  with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Scroll controllers for each tab
  final Map<String, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize timeago locale to Portuguese
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());

    // Initialize scroll controllers for each tab
    for (var i = 0; i < 2; i++) {
      final controller = ScrollController();
      _scrollControllers['tab_$i'] = controller;
      controller.addListener(() => _onScroll(i));
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

  void _onScroll(int tabIndex) {
    final key = 'tab_$tabIndex';
    final controller = _scrollControllers[key];
    if (controller == null) return;

    // Load more when scrolled to 80% of the list
    if (controller.position.pixels >=
        controller.position.maxScrollExtent * 0.8) {
      
      final profileState = ref.read(profileProvider);
      final activeProfile = profileState.value?.activeProfile;
      if (activeProfile == null) return;

      final type = tabIndex == 1 ? NotificationType.interest : null;
      
      ref.read(notificationsControllerProvider(activeProfile.profileId, type: type).notifier).loadMore();
    }
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
      centerTitle: true,
      title: const Text(
        'Notificações',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Consumer(
            builder: (context, ref, _) {
              final profileState = ref.watch(profileProvider);
              final activeProfile = profileState.value?.activeProfile;
              if (activeProfile == null) return const SizedBox.shrink();
              
              final unreadCountAsync = ref.watch(unreadNotificationCountForProfileProvider(
                activeProfile.profileId,
                activeProfile.uid,
              ));
              
              final count = unreadCountAsync.value ?? 0;
              final hasUnread = count > 0;
              
              return IconButton(
                icon: Icon(
                  Iconsax.tick_circle,
                  color: hasUnread
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
                    tooltip: 'Marcar todas como lidas',
                    onPressed: hasUnread
                        ? () async {
                            try {
                              await ref
                                  .read(notificationsRepositoryNewProvider)
                                  .markAllAsRead(
                                    profileId: activeProfile.profileId,
                                    recipientUid: activeProfile.uid,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Todas as notificações foram marcadas como lidas'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao marcar como lidas: $e'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                  );
            },
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
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

    final stateAsync = ref.watch(notificationsControllerProvider(currentProfileId, type: type));

    return stateAsync.when(
      loading: () => ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => const NotificationSkeletonTile(),
      ),
      error: (error, stack) {
        debugPrint('NotificationsPage: Erro no controller: $error');
        return NotificationErrorState(
          message: 'Não foi possível carregar suas notificações. Verifique sua conexão e tente novamente.',
          onRetry: () {
            ref.invalidate(notificationsControllerProvider(currentProfileId, type: type));
          },
        );
      },
      data: (state) {
        if (state.notifications.isEmpty) {
          return _buildEmptyState(type);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(notificationsControllerProvider(currentProfileId, type: type).notifier).refresh();
          },
          color: AppColors.primary,
          child: ListView.builder(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.notifications.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              return NotificationItem(notification: state.notifications[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(NotificationType? type) {
    if (type == NotificationType.interest) {
      return const EmptyState(
        icon: Iconsax.heart,
        title: 'Nenhum interesse ainda',
        subtitle:
            'Quando alguém demonstrar interesse em seus posts, você será notificado aqui.',
      );
    }

    if (type == NotificationType.newMessage) {
      return const EmptyState(
        icon: Iconsax.message,
        title: 'Nenhuma mensagem nova',
        subtitle:
            'Você ainda não recebeu mensagens.',
      );
    }

    return const EmptyState(
      icon: Iconsax.notification,
      title: 'Nenhuma notificação',
      subtitle:
          'Você ainda não tem notificações.',
    );
  }
}
