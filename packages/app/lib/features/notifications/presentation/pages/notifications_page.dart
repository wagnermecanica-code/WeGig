import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/widgets/empty_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wegig_app/features/notifications/domain/services/notification_service.dart';
import 'package:wegig_app/features/notifications/presentation/widgets/notification_item.dart';
import 'package:wegig_app/features/post/presentation/pages/post_page.dart';
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

  // Pagination state
  final Map<String, bool> _hasMore = {'tab_0': true, 'tab_1': true};
  final Map<String, bool> _isLoadingMore = {'tab_0': false, 'tab_1': false};
  final Map<String, List<NotificationEntity>> _notifications = {'tab_0': [], 'tab_1': []};
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

  Future<void> _handleRefresh(
    String profileId,
    NotificationType? type,
  ) async {
    final tabIndex = type == null ? 0 : (type == NotificationType.interest ? 1 : 2);
    final key = 'tab_$tabIndex';

    setState(() {
      _hasMore[key] = true;
      _notifications[key] = [];
    });

    await ref.read(notificationServiceProvider).refreshNotifications(
          recipientProfileId: profileId,
          type: type,
        );

    // Recria o serviço para garantir nova assinatura
    ref.invalidate(notificationServiceProvider);
  }

  void _onScroll(int tabIndex) {
    final key = 'tab_$tabIndex';
    final controller = _scrollControllers[key];
    if (controller == null) return;

    // Load more when scrolled to 80% of the list
    if (controller.position.pixels >=
        controller.position.maxScrollExtent * 0.8) {
      final hasMore = _hasMore[key] ?? true;
      final isLoadingMore = _isLoadingMore[key] ?? false;
      
      if (hasMore && !isLoadingMore) {
        _loadMore(tabIndex);
      }
    }
  }

  /// Carrega mais notificações (paginação)
  Future<void> _loadMore(int tabIndex) async {
    final key = 'tab_$tabIndex';
    final currentNotifications = _notifications[key] ?? [];
    
    if (currentNotifications.isEmpty) return;

    setState(() {
      _isLoadingMore[key] = true;
    });

    try {
      final profileState = ref.read(profileProvider);
      final activeProfile = profileState.value?.activeProfile;
      if (activeProfile == null) return;

      // Determinar tipo baseado na tab
      final type = tabIndex == 1 ? NotificationType.interest : null;
      
      // Pegar último documento para cursor
      final lastNotification = currentNotifications.last;
      final lastDoc = lastNotification.document;
      
      // Buscar mais notificações com cursor-based pagination
      final newNotifications = await ref
          .read(notificationServiceProvider)
          .getNotifications(
            activeProfile.profileId,
            type: type,
            limit: 20,
            startAfter: lastDoc,
          )
          .first;

      if (!mounted) return;

      setState(() {
        if (newNotifications.length < 20) {
          _hasMore[key] = false;
        }
        _notifications[key] = [...currentNotifications, ...newNotifications];
        _isLoadingMore[key] = false;
      });

      debugPrint('📄 Paginação: Carregadas ${newNotifications.length} notificações (tab $tabIndex)');
    } catch (e) {
      debugPrint('❌ Erro ao carregar mais notificações: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingMore[key] = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();

    // Remove listeners and dispose scroll controllers
    // ✅ FIX: Não podemos remover listener inline pois cada tab tem closure diferente
    // A solução aqui é criar listeners nomeados OU simplesmente dispose (dispose já limpa)
    for (final entry in _scrollControllers.entries) {
      // ScrollController.dispose() já remove automaticamente todos os listeners
      entry.value.dispose();
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
                                  .read(notificationServiceProvider)
                                  .markAllAsRead();
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
                Icon(Iconsax.danger, size: 68, color: Colors.red.shade300),
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

        // Atualizar cache de notificações
          if (notifications.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && (_notifications[key]?.isEmpty ?? false)) {
                setState(() {
                  _notifications[key] = notifications;
                });
              }
            });
        }

        if (notifications.isEmpty) {
          return _buildEmptyState(type);
        }

        // Usar notificações do cache se houver paginação ativa
          final displayNotifications = (_notifications[key]?.isNotEmpty ?? false)
            ? _notifications[key]!
            : notifications;

        return RefreshIndicator(
          onRefresh: () async {
            await _handleRefresh(currentProfileId, type);

            final refreshController = controller;
            if (refreshController != null) {
              try {
                await refreshController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              } catch (_) {}
            }
          },
          color: AppColors.primary,
          child: ListView.builder(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
              itemCount:
                  displayNotifications.length + ((_isLoadingMore[key] ?? false) ? 1 : 0),
            itemBuilder: (context, index) {
            // Loading indicator no final
            if (index == displayNotifications.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            
            // ⚡ PERFORMANCE: Widget extraído para melhor manutenibilidade
            return NotificationItem(notification: displayNotifications[index]);
          },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(NotificationType? type) {
    if (type == NotificationType.interest) {
      return EmptyState(
        icon: Iconsax.heart,
        title: 'Nenhum interesse ainda',
        subtitle:
            'Quando alguém demonstrar interesse em seus posts, você será notificado aqui.',
        actionLabel: 'Criar novo post',
        onActionPressed: () => showPostModal(context, 'musician'),
      );
    }

    if (type == NotificationType.newMessage) {
      return EmptyState(
        icon: Iconsax.message,
        title: 'Nenhuma mensagem nova',
        subtitle:
            'Você ainda não recebeu mensagens. Inicie uma conversa para começar a trocar ideias!',
        actionLabel: 'Iniciar nova conversa',
        onActionPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Nova Conversa')),
                body: const Center(child: Text('Em desenvolvimento')),
              ),
            ),
          );
        },
      );
    }

    return EmptyState(
      icon: Iconsax.notification,
      title: 'Nenhuma notificação',
      subtitle:
          'Ative as notificações para não perder novidades e oportunidades.',
      actionLabel: 'Ativar notificações',
      onActionPressed: () {
        // Aqui pode abrir configurações ou mostrar instrução
        AppSnackBar.showInfo(
          context,
          'Ajuste as permissões de notificação nas configurações do sistema.',
        );
      },
    );
  }
}
