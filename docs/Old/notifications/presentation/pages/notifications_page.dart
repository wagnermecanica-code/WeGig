import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/widgets/empty_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wegig_app/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:wegig_app/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:wegig_app/features/notifications/presentation/widgets/notification_error_state.dart';
import 'package:wegig_app/features/notifications/presentation/widgets/notification_item.dart';
import 'package:wegig_app/features/notifications/presentation/widgets/notification_skeleton_tile.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

/// Tela de notificações unificada com abas de filtro (Todas/Interesses)
/// 
/// Implementa paginação infinita, pull-to-refresh e gerenciamento de memória
/// para evitar leaks ao trocar de perfil.
class NotificationsPage extends ConsumerStatefulWidget {
  /// Constrói a página de notificações com abas de filtro.
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

/// State que controla as abas de notificações com paginação e lógica de refresh.
class _NotificationsPageState extends ConsumerState<NotificationsPage>
  with SingleTickerProviderStateMixin {
  /// Controlador de abas (Todas/Interesses)
  late final TabController _tabController;

  /// Controladores de scroll para cada aba (permite paginação independente)
  final Map<String, ScrollController> _scrollControllers = {};
  
  /// ✅ FIX: Armazena listeners de scroll para cleanup adequado (previne memory leak)
  /// Cada listener é uma função nomeada, não uma closure inline, permitindo remoção
  final Map<String, VoidCallback> _scrollListeners = {};
  
  /// ✅ FIX: Rastreia mudanças de perfil ativo para invalidar providers antigos
  /// Quando o usuário troca de perfil, invalidamos os controllers do perfil anterior
  String? _lastProfileId;

  @override
  void initState() {
    super.initState();
    // Inicializa controller de abas com 2 tabs (Todas/Interesses)
    _tabController = TabController(length: 2, vsync: this);

    // Configura locale português brasileiro para formatação de datas ("há 2 horas", etc)
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());

    // ✅ FIX: Inicializa scroll controllers com listeners nomeados
    // Cada aba tem seu próprio ScrollController para paginação independente
    for (var i = 0; i < 2; i++) {
      final key = 'tab_$i';
      final controller = ScrollController();
      _scrollControllers[key] = controller;
      
      // Cria função listener NOMEADA (não inline) para permitir remoção no dispose
      // Isso previne memory leaks documentados em MEMORY_LEAK_AUDIT_2025-11-30.md
      void listener() => _onScroll(i);
      _scrollListeners[key] = listener;
      controller.addListener(listener);
    }
  }

  @override
  void dispose() {
    // Libera recursos do controller de abas
    _tabController.dispose();
    
    // ✅ FIX: Remove listeners ANTES de fazer dispose dos controllers
    // ORDEM IMPORTA: remover listener → dispose controller → limpar mapa
    // Se não remover listener antes, o listener pode tentar acessar controller já disposed
    for (final entry in _scrollControllers.entries) {
      final listener = _scrollListeners[entry.key];
      if (listener != null) {
        entry.value.removeListener(listener);
      }
      entry.value.dispose();
    }
    _scrollListeners.clear();
    
    super.dispose();
  }

  /// Detecta scroll para implementar paginação infinita
  /// Carrega mais notificações quando usuário rola até 80% da lista
  void _onScroll(int tabIndex) {
    final key = 'tab_$tabIndex';
    final controller = _scrollControllers[key];
    
    // ✅ FIX: Verifica hasClients para evitar erro quando controller não tem widgets anexados
    // Pode acontecer durante transições de aba ou dispose
    if (controller == null || !controller.hasClients) return;

    // Carrega mais notificações quando scroll atinge 80% do final da lista
    // Isso dá tempo de carregar antes do usuário chegar no final
    if (controller.position.pixels >=
        controller.position.maxScrollExtent * 0.8) {
      
      final profileState = ref.read(profileProvider);
      final activeProfile = profileState.value?.activeProfile;
      if (activeProfile == null) return;

      // tabIndex 0 = Todas (type: null), tabIndex 1 = Interesses (type: interest)
      final type = tabIndex == 1 ? NotificationType.interest : null;
      
      // Chama loadMore() no controller da aba atual
      ref.read(notificationsControllerProvider(activeProfile.profileId, type: type).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Valida autenticação - usuário precisa estar logado
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Você precisa estar logado para ver as notificações'),
        ),
      );
    }

    // Observa mudanças no perfil ativo (ref.watch reage a mudanças)
    final profileState = ref.watch(profileProvider);
    final activeProfile = profileState.value?.activeProfile;
    if (activeProfile == null) {
      // Ainda carregando perfil - mostra loading
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final currentProfileId = activeProfile.profileId;
    
    // ✅ FIX: Detecta troca de perfil e invalida providers do perfil anterior
    // Isso garante que notificações antigas não apareçam após trocar de perfil
    // Ver SESSION_14_MULTI_PROFILE_REFACTORING.md para contexto
    if (_lastProfileId != null && _lastProfileId != currentProfileId) {
      debugPrint('🔄 NotificationsPage: Perfil mudou de $_lastProfileId para $currentProfileId');
      // addPostFrameCallback garante invalidação após build completo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lastProfileId != null) {
          // Invalida ambas as abas (Todas e Interesses) do perfil anterior
          ref.invalidate(notificationsControllerProvider(_lastProfileId!, type: null));
          ref.invalidate(notificationsControllerProvider(_lastProfileId!, type: NotificationType.interest));
        }
      });
    }
    _lastProfileId = currentProfileId;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(currentProfileId),
      body: _buildBody(currentProfileId),
    );
  }

  /// Constrói a AppBar com título e botão "Marcar todas como lidas"
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
        // Botão "Marcar todas como lidas" no canto superior direito
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Consumer(
            builder: (context, ref, _) {
              // Obtém perfil ativo atual
              final profileState = ref.watch(profileProvider);
              final activeProfile = profileState.value?.activeProfile;
              if (activeProfile == null) return const SizedBox.shrink();
              
              // Observa contador de notificações não lidas em tempo real
              // Usa provider stream que consulta Firestore com recipientUid
              final unreadCountAsync = ref.watch(unreadNotificationCountForProfileProvider(
                activeProfile.profileId,
                activeProfile.uid,
              ));
              
              final count = unreadCountAsync.value ?? 0;
              final hasUnread = count > 0;
              
              // Ícone fica opaco quando não há notificações não lidas
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
      // Abas de filtro de notificações
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'Todas'),      // Mostra todas as notificações
          Tab(text: 'Interesses'), // Filtra apenas notificações de interesse em posts
        ],
      ),
    );
  }

  /// Constrói o corpo da página com as abas de notificações
  Widget _buildBody(String currentProfileId) {
    return TabBarView(
      // ✅ FIX: ValueKey força rebuild completo quando perfil muda
      // Sem isso, o TabBarView pode manter state antigo ao trocar perfil
      key: ValueKey('notifications_tabs_$currentProfileId'),
      controller: _tabController,
      children: [
        _buildNotificationsList(currentProfileId, null),                          // Aba "Todas"
        _buildNotificationsList(currentProfileId, NotificationType.interest),     // Aba "Interesses"
      ],
    );
  }

  /// Constrói a lista de notificações para uma aba específica
  /// 
  /// [currentProfileId] ID do perfil ativo
  /// [type] Filtro de tipo (null = todas, NotificationType.interest = só interesses)
  Widget _buildNotificationsList(
      String currentProfileId, NotificationType? type) {
    // Calcula índice da aba para buscar ScrollController correto
    final tabIndex =
        type == null ? 0 : (type == NotificationType.interest ? 1 : 2);
    final key = 'tab_$tabIndex';
    final controller = _scrollControllers[key];

    // Observa state do controller de notificações (AsyncValue com loading/error/data)
    final stateAsync = ref.watch(notificationsControllerProvider(currentProfileId, type: type));

    // Pattern Riverpod: AsyncValue.when() para lidar com 3 estados possíveis
    return stateAsync.when(
      // Estado LOADING: mostra 10 skeleton tiles animados
      loading: () => ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => const NotificationSkeletonTile(),
      ),
      // Estado ERROR: mostra tela de erro com botão de retry
      error: (error, stack) {
        debugPrint('NotificationsPage: Erro no controller: $error');
        return NotificationErrorState(
          message: 'Não foi possível carregar suas notificações. Verifique sua conexão e tente novamente.',
          onRetry: () {
            // Invalida provider para forçar nova query ao Firestore
            ref.invalidate(notificationsControllerProvider(currentProfileId, type: type));
          },
        );
      },
      // Estado DATA: mostra lista de notificações com pull-to-refresh
      data: (state) {
        // Se não há notificações, mostra estado vazio
        if (state.notifications.isEmpty) {
          return _buildEmptyState(type);
        }

        // Lista com pull-to-refresh habilitado
        return RefreshIndicator(
          onRefresh: () async {
            // Chama refresh() no controller para recarregar do início
            await ref.read(notificationsControllerProvider(currentProfileId, type: type).notifier).refresh();
          },
          color: AppColors.primary,
          child: ListView.builder(
            controller: controller, // ScrollController para detectar scroll (paginação)
            physics: const AlwaysScrollableScrollPhysics(), // Permite pull-to-refresh mesmo com poucos itens
            // +1 item se estiver carregando mais (mostra loading indicator no final)
            itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Último item = loading indicator (aparece ao paginar)
              if (index == state.notifications.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              // Renderiza NotificationItem para cada notificação
              return NotificationItem(notification: state.notifications[index]);
            },
          ),
        );
      },
    );
  }

  /// Constrói estado vazio customizado conforme tipo de filtro
  Widget _buildEmptyState(NotificationType? type) {
    // Aba "Interesses" vazia
    if (type == NotificationType.interest) {
      return const EmptyState(
        icon: Iconsax.heart,
        title: 'Nenhum interesse ainda',
        subtitle:
            'Quando alguém demonstrar interesse em seus posts, você será notificado aqui.',
      );
    }

    // Aba "Mensagens" vazia (caso futuro)
    if (type == NotificationType.newMessage) {
      return const EmptyState(
        icon: Iconsax.message,
        title: 'Nenhuma mensagem nova',
        subtitle:
            'Você ainda não recebeu mensagens.',
      );
    }

    // Aba "Todas" vazia
    return const EmptyState(
      icon: Iconsax.notification,
      title: 'Nenhuma notificação',
      subtitle:
          'Você ainda não tem notificações.',
    );
  }
}
