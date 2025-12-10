/// WeGig - NotificationsNew Page
///
/// Tela principal de notificações com abas (Todas/Interesses).
/// Implementa paginação infinita, pull-to-refresh e multi-perfil.
///
/// Features:
/// - TabBar com estilo WeGig
/// - Paginação infinita por aba
/// - Pull-to-refresh por aba
/// - Marcar todas como lidas
/// - Skeleton loading
/// - Estado vazio e erro com retry
/// - Troca automática ao mudar perfil
library;

import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wegig_app/features/notifications_new/domain/entities/notification_new_entity.dart';
import 'package:wegig_app/features/notifications_new/presentation/controllers/notifications_new_controller.dart';
import 'package:wegig_app/features/notifications_new/presentation/providers/notifications_new_providers.dart';
import 'package:wegig_app/features/notifications_new/presentation/widgets/notification_new_empty_state.dart';
import 'package:wegig_app/features/notifications_new/presentation/widgets/notification_new_error_state.dart';
import 'package:wegig_app/features/notifications_new/presentation/widgets/notification_new_item.dart';
import 'package:wegig_app/features/notifications_new/presentation/widgets/notification_new_skeleton_tile.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

/// Página principal de notificações
///
/// Usa TabController para alternar entre:
/// - Tab 0: Todas as notificações
/// - Tab 1: Apenas interesses
class NotificationsNewPage extends ConsumerStatefulWidget {
  /// Cria página de notificações
  const NotificationsNewPage({super.key});

  @override
  ConsumerState<NotificationsNewPage> createState() =>
      _NotificationsNewPageState();
}

class _NotificationsNewPageState extends ConsumerState<NotificationsNewPage>
    with SingleTickerProviderStateMixin {
  /// Controller de abas
  late final TabController _tabController;

  /// Scroll controllers por aba (para paginação independente)
  final Map<int, ScrollController> _scrollControllers = {};

  /// Listeners de scroll por aba (para cleanup)
  final Map<int, VoidCallback> _scrollListeners = {};

  /// ID do último perfil ativo (para detectar troca)
  String? _lastProfileId;

  @override
  void initState() {
    super.initState();

    // Inicializa TabController com 2 abas
    _tabController = TabController(length: 2, vsync: this);

    // Configura locale pt-BR para timeago
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());

    // Inicializa scroll controllers com listeners para cada aba
    for (var i = 0; i < 2; i++) {
      final controller = ScrollController();
      _scrollControllers[i] = controller;

      // Listener nomeado para poder remover no dispose
      void listener() => _onScroll(i);
      _scrollListeners[i] = listener;
      controller.addListener(listener);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();

    // Remove listeners ANTES de dispose dos controllers
    for (final entry in _scrollControllers.entries) {
      final listener = _scrollListeners[entry.key];
      if (listener != null) {
        entry.value.removeListener(listener);
      }
      entry.value.dispose();
    }
    _scrollListeners.clear();
    _scrollControllers.clear();

    super.dispose();
  }

  /// Detecta scroll para paginação infinita
  void _onScroll(int tabIndex) {
    final controller = _scrollControllers[tabIndex];

    if (controller == null || !controller.hasClients) return;

    // Carrega mais quando chega a 80% do fim
    if (controller.position.pixels >=
        controller.position.maxScrollExtent * 0.8) {
      final profileState = ref.read(profileProvider);
      final activeProfile = profileState.value?.activeProfile;
      if (activeProfile == null) return;

      // Tab 0 = Todas (type: null), Tab 1 = Interesses (type: interest)
      final type = tabIndex == 1 ? NotificationType.interest : null;

      ref
          .read(notificationsNewControllerProvider(activeProfile.profileId,
                  type: type)
              .notifier)
          .loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observa perfil ativo
    final profileState = ref.watch(profileProvider);
    final activeProfile = profileState.value?.activeProfile;

    // Loading se perfil não carregou
    if (activeProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentProfileId = activeProfile.profileId;

    // DEBUG: Log para verificar profileId
    debugPrint('📱 NotificationsNewPage: currentProfileId=$currentProfileId, uid=${activeProfile.uid}');

    // Detecta troca de perfil
    if (_lastProfileId != null && _lastProfileId != currentProfileId) {
      debugPrint(
          '🔄 NotificationsNewPage: Perfil mudou de $_lastProfileId para $currentProfileId');

      // Invalida controllers do perfil anterior
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lastProfileId != null) {
          ref.invalidate(
              notificationsNewControllerProvider(_lastProfileId!, type: null));
          ref.invalidate(notificationsNewControllerProvider(_lastProfileId!,
              type: NotificationType.interest));
        }
      });
    }
    _lastProfileId = currentProfileId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(currentProfileId, activeProfile.uid),
      body: _buildBody(currentProfileId),
    );
  }

  /// AppBar com título, botão marcar todas e TabBar
  PreferredSizeWidget _buildAppBar(String profileId, String recipientUid) {
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
        _buildMarkAllAsReadButton(profileId, recipientUid),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        tabs: const [
          Tab(text: 'Todas'),
          Tab(text: 'Interesses'),
        ],
      ),
    );
  }

  /// Botão para marcar todas como lidas
  Widget _buildMarkAllAsReadButton(String profileId, String recipientUid) {
    return Consumer(
      builder: (context, ref, _) {
        // Observa contador de não lidas
        final unreadCountAsync = ref.watch(
          unreadNotificationCountNewStreamProvider(profileId, recipientUid),
        );

        final count = unreadCountAsync.valueOrNull ?? 0;
        final hasUnread = count > 0;

        return IconButton(
          onPressed: hasUnread
              ? () => _markAllAsRead(profileId)
              : null,
          icon: Icon(
            Iconsax.tick_circle,
            color: hasUnread ? Colors.white : Colors.white38,
          ),
          tooltip: 'Marcar todas como lidas',
        );
      },
    );
  }

  /// Marca todas as notificações como lidas
  Future<void> _markAllAsRead(String profileId) async {
    // Marca em ambas as abas
    await ref
        .read(notificationsNewControllerProvider(profileId, type: null).notifier)
        .markAllAsRead();

    await ref
        .read(notificationsNewControllerProvider(profileId,
                type: NotificationType.interest)
            .notifier)
        .markAllAsRead();
  }

  /// Body com TabBarView
  Widget _buildBody(String profileId) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Tab 0: Todas
        _buildNotificationsList(
          profileId: profileId,
          type: null,
          tabIndex: 0,
        ),
        // Tab 1: Interesses
        _buildNotificationsList(
          profileId: profileId,
          type: NotificationType.interest,
          tabIndex: 1,
        ),
      ],
    );
  }

  /// Lista de notificações com estados de loading/error/empty
  Widget _buildNotificationsList({
    required String profileId,
    required NotificationType? type,
    required int tabIndex,
  }) {
    final controllerState =
        ref.watch(notificationsNewControllerProvider(profileId, type: type));

    return controllerState.when(
      // Loading inicial
      loading: () => _buildSkeletonList(),

      // Erro
      error: (error, stack) => NotificationNewErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(
            notificationsNewControllerProvider(profileId, type: type)),
      ),

      // Dados carregados
      data: (state) {
        // Estado vazio - ainda permite pull-to-refresh
        if (state.notifications.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref
                .read(notificationsNewControllerProvider(profileId, type: type)
                    .notifier)
                .refresh(),
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollControllers[tabIndex],
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: NotificationNewEmptyState(
                    isInterestsTab: type == NotificationType.interest,
                  ),
                ),
              ],
            ),
          );
        }

        // Lista com pull-to-refresh
        return RefreshIndicator(
          onRefresh: () => ref
              .read(notificationsNewControllerProvider(profileId, type: type)
                  .notifier)
              .refresh(),
          color: AppColors.primary,
          child: ListView.separated(
            controller: _scrollControllers[tabIndex],
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              // Loading more indicator no final
              if (index == state.notifications.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final notification = state.notifications[index];
              return NotificationNewItem(
                notification: notification,
                profileId: profileId,
                type: type,
              );
            },
          ),
        );
      },
    );
  }

  /// Lista de skeletons para loading
  Widget _buildSkeletonList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, __) => const NotificationNewSkeletonTile(),
    );
  }
}
