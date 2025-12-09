import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:wegig_app/core/cache/image_cache_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:core_ui/models/search_params.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/widgets/mention_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/features/home/presentation/pages/home_page.dart';
import 'package:wegig_app/features/home/presentation/pages/search_page_new.dart';
import 'package:wegig_app/features/messages/presentation/pages/chat_detail_page.dart';
import 'package:wegig_app/features/messages/presentation/pages/messages_page.dart';
import 'package:wegig_app/features/messages/presentation/providers/messages_providers.dart';
import 'package:wegig_app/features/notifications/domain/services/notification_service.dart';
import 'package:wegig_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:wegig_app/features/notifications/presentation/utils/notification_action_handler.dart';
import 'package:wegig_app/features/notifications/presentation/widgets/notification_location_row.dart';
import 'package:wegig_app/features/post/presentation/pages/post_page.dart';
import 'package:wegig_app/features/post/presentation/providers/post_providers.dart';
import 'package:wegig_app/features/profile/presentation/pages/view_profile_page.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:wegig_app/features/profile/presentation/widgets/profile_switcher_bottom_sheet.dart';

/// Configuração de item da bottom nav
class _NavItemConfig {
  const _NavItemConfig({
    required this.icon,
    required this.label,
    this.hasBadge = false,
    this.isAvatar = false,
  });

  final IconData icon;
  final String label;
  final bool hasBadge;
  final bool isAvatar;
}

/// Bottom Navigation Scaffold - Navegação principal do app
///
/// Otimizações implementadas:
/// - CachedNetworkImage para avatar (reduz rebuilds)
/// - ValueNotifier para índice (evita setState no Scaffold)
/// - StreamBuilders otimizados (apenas onde necessário)
/// - IndexedStack preserva estado das páginas

class BottomNavScaffold extends ConsumerStatefulWidget {
  const BottomNavScaffold({super.key});

  @override
  ConsumerState<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends ConsumerState<BottomNavScaffold> {
  // ValueNotifier evita rebuilds desnecessários do Scaffold
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier<int>(0);

  // notifier used to pass search params from SearchPage to HomePage
  final ValueNotifier<SearchParams?> _searchNotifier =
      ValueNotifier<SearchParams?>(null);

  // Notificador para forçar refresh manual da Home
  final ValueNotifier<int> _homeRefreshNotifier = ValueNotifier<int>(0);

  // Lazy initialization - páginas carregadas sob demanda
  late final List<Widget> _pages = [
    HomePage(
      key: const PageStorageKey('home_page'),
      searchNotifier: _searchNotifier,
      onOpenSearch: _openSearchPage,
      refreshNotifier: _homeRefreshNotifier,
    ),
    const NotificationsPage(),
    const SizedBox.shrink(), // Placeholder - abre bottom sheet ao tocar
    const MessagesPage(),
    // ViewProfilePage without userId shows the current authenticated user's profile
    const ViewProfilePage(),
  ];

  // Configuração dos itens da bottom nav (elimina código repetitivo)
  static const List<_NavItemConfig> _navItems = [
    _NavItemConfig(icon: Iconsax.home, label: 'Início'),
    _NavItemConfig(
        icon: Iconsax.notification, label: 'Notificações', hasBadge: true),
    _NavItemConfig(icon: Iconsax.add_circle, label: 'Criar Post'),
    _NavItemConfig(icon: Iconsax.message, label: 'Mensagens', hasBadge: true),
    _NavItemConfig(icon: Iconsax.user, label: 'Perfil', isAvatar: true),
  ];

  /// Abre a tela de filtros/busca
  void _openSearchPage() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => SearchPageNew(
          searchNotifier: _searchNotifier,
          onApply: () {
            // Fecha a tela de filtros e volta para HomePage
            Navigator.pop(context);
            // HomePage automaticamente reage ao _searchNotifier via listener
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentIndexNotifier.dispose();
    _searchNotifier.dispose();
    _homeRefreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Router garante que só chegamos aqui com perfil ativo
    return ValueListenableBuilder<int>(
      valueListenable: _currentIndexNotifier,
      builder: (context, currentIndex, child) {
        return Scaffold(
          body: IndexedStack(
            index: currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: (i) {
              if (i == 2) {
                // Tab "Criar Post" - mostrar bottom sheet de seleção
                _showPostTypeBottomSheet(context);
              } else {
                if (i == 0 && _currentIndexNotifier.value == 0) {
                  ref.invalidate(postNotifierProvider);
                  _homeRefreshNotifier.value++;
                  return;
                }
                _currentIndexNotifier.value = i;
              }
            },
            items: List.generate(
              _navItems.length,
              (index) =>
                  _buildNavItem(_navItems[index], index == currentIndex),
            ),
          ),
        );
      },
    );
  }

  /// Constrói item da bottom nav baseado na configuração
  BottomNavigationBarItem _buildNavItem(
      _NavItemConfig config, bool isSelected) {
    Widget icon;

    if (config.hasBadge) {
      // Badges: notificações ou mensagens
      if (config.label == 'Notificações') {
        icon = _buildNotificationIcon(isSelected: isSelected);
      } else if (config.label == 'Mensagens') {
        icon = _buildMessagesIcon(isSelected: isSelected);
      } else {
        icon = Icon(config.icon, size: 26);
      }
    } else if (config.isAvatar) {
      // Avatar do perfil com cache
      icon = _buildAvatarIcon(isSelected);
    } else {
      // Ícone padrão
      icon = Icon(config.icon, size: 26);
    }

    return BottomNavigationBarItem(
      icon: icon,
      label: config.label,
    );
  }

  /// Ícone de notificações com badge reativo
  Widget _buildNotificationIcon({bool isSelected = false}) {
    return StreamBuilder<int>(
      stream: ref.read(notificationServiceProvider).streamUnreadCount(),
      builder: (context, snapshot) {
        // Error state
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Iconsax.notification_bing,
              size: 28,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          );
        }

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Iconsax.notification,
                  size: 28,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
              ],
            ),
          );
        }

        final unreadCount = snapshot.data ?? 0;

        return Container(
          padding: const EdgeInsets.all(4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Iconsax.notification,
                size: 26,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }


  /// Ícone de mensagens com badge reativo
  Widget _buildMessagesIcon({bool isSelected = false}) {
    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;

    if (activeProfile == null) {
      return Icon(
        Iconsax.message,
        size: 28,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      );
    }

    return StreamBuilder<int>(
      // ✅ FIX: Passar uid para match com Security Rules
      stream: ref.read(unreadMessageCountForProfileProvider(activeProfile.profileId, activeProfile.uid).future).asStream(),
      builder: (context, snapshot) {
        // Error state
        if (snapshot.hasError) {
          return Icon(
            Iconsax.message,
            size: 28,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          );
        }

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Iconsax.message,
                size: 28,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              Positioned(
                right: -4,
                top: -4,
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
            ],
          );
        }

        final unreadCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 26,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
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
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Avatar do perfil ativo com CachedNetworkImage (otimizado)
  /// Suporta long press para mostrar o ProfileSwitcherBottomSheet
  Widget _buildAvatarIcon(bool isSelected) {
    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;
    final photo = activeProfile?.photoUrl;
    if (activeProfile == null) {
      return GestureDetector(
        onLongPress: () => _showProfileSwitcher(context),
        child: const CircleAvatar(
          radius: 14,
          backgroundColor: Colors.grey,
          child: Icon(Iconsax.user, size: 20),
        ),
      );
    }
    return GestureDetector(
      onLongPress: () => _showProfileSwitcher(context),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: _buildAvatarImage(photo),
      ),
    );
  }

  /// Constrói imagem do avatar com cache otimizado e skeleton loader
  Widget _buildAvatarImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: Colors.grey[200],
        child: const Icon(Iconsax.user, size: 20),
      );
    }

    // URL remota - usar CachedNetworkImage para performance
    if (photoUrl.startsWith('http')) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: Colors.grey[200],
        child: ClipOval(
          child: CachedNetworkImage(
            cacheManager: WeGigImageCacheManager.instance,
            imageUrl: photoUrl,
            width: 28,
            height: 28,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[300]!,
                    Colors.grey[200]!,
                  ],
                ),
              ),
            ),
            errorWidget: (context, url, error) => const Icon(
              Iconsax.user,
              size: 18,
            ),
            // Otimizações de cache
            memCacheWidth: 56, // 2x resolution
            memCacheHeight: 56,
            fadeInDuration: const Duration(milliseconds: 200),
          ),
        ),
      );
    }

    // Arquivo local - usar FileImage (menos comum)
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.grey[200],
      backgroundImage: _createLocalImageProvider(photoUrl),
      child: const Icon(Icons.person, size: 18),
    );
  }

  /// Cria ImageProvider para arquivo local (fallback assíncrono)
  ImageProvider? _createLocalImageProvider(String pathOrUrl) {
    try {
      String candidate = pathOrUrl;
      if (candidate.startsWith('file://')) {
        candidate = Uri.parse(candidate).toFilePath();
      }

      final f = File(candidate);
      // Verificação assíncrona evita bloquear UI
      if (f.existsSync()) {
        return FileImage(f);
      }
    } catch (e) {
      debugPrint('Error loading local image: $e');
    }

    return null; // Fallback para ícone padrão
  }
}

/// Modal de notificações rápidas
class NotificationsModal extends ConsumerStatefulWidget {
  const NotificationsModal({super.key});

  @override
  ConsumerState<NotificationsModal> createState() =>
      _NotificationsModalState();
}

class _NotificationsModalState extends ConsumerState<NotificationsModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notificações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to full notifications page
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                  },
                  child: const Text('Ver todas'),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                // ✅ FIX: Usar watch() para reatividade ao trocar perfil
                final profileState = ref.watch(profileProvider);
                final activeProfile = profileState.value?.activeProfile;
                if (activeProfile == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                // ...existing code for notifications...
                return StreamBuilder<List<NotificationEntity>>(
                  // ✅ FIX: Key baseada em profileId para forçar rebuild ao trocar perfil
                  key: ValueKey('notifications_modal_${activeProfile.profileId}'),
                  stream: ref.read(notificationServiceProvider).streamActiveProfileNotifications(),
                  builder: (context, snapshot) {
                    // ✅ FIX: Mostrar loading apenas no primeiro carregamento
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // ✅ FIX: Tratar erros com UI de retry
                    if (snapshot.hasError) {
                      debugPrint('NotificationsModal: Erro no stream: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.warning_2, size: 48, color: Colors.orange.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Erro ao carregar notificações',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => ref.invalidate(notificationServiceProvider),
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      );
                    }
                    final notifications = snapshot.data ?? [];
                    final recentNotifications = notifications.take(10).toList();
                    if (recentNotifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.notification,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma notificação',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _refreshModalNotifications(
                        activeProfile.profileId,
                      ),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: recentNotifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationItem(
                            recentNotifications[index],
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshModalNotifications(String profileId) async {
    await ref.read(notificationServiceProvider).refreshNotifications(
          recipientProfileId: profileId,
        );
  }

  Widget _buildNotificationItem(NotificationEntity notification) {
    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        color: notification.read ? Colors.white : Colors.blue.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(notification),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MentionText(
                    text: notification.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    onMentionTap: (username) =>
                        context.pushProfileByUsername(username),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  NotificationLocationRow(
                    notification: notification,
                    iconColor: AppColors.primary,
                    textStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimeAgo(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.read)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationEntity notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.interest:
        icon = Iconsax.heart5;
        color = Colors.pink;
        break;
      case NotificationType.newMessage:
        icon = Iconsax.message;
        color = Colors.blue;
        break;
      case NotificationType.postExpiring:
        icon = Iconsax.clock;
        color = Colors.orange;
        break;
      case NotificationType.nearbyPost:
        icon = Iconsax.location;
        color = Colors.green;
        break;
      case NotificationType.profileMatch:
        icon = Iconsax.people;
        color = Colors.purple;
        break;
      case NotificationType.interestResponse:
        icon = Iconsax.arrow_left;
        color = Colors.blue;
        break;
      case NotificationType.postUpdated:
        icon = Iconsax.edit;
        color = Colors.grey;
        break;
      case NotificationType.profileView:
        icon = Iconsax.eye;
        color = Colors.purple;
        break;
      case NotificationType.system:
        icon = Iconsax.info_circle;
        color = Colors.teal;
        break;
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Future<void> _handleNotificationTap(NotificationEntity notification) async {
    // Close modal first
    Navigator.pop(context);

    // ✅ Delegar para handler centralizado
    final handler = NotificationActionHandler(ref: ref, context: context);
    await handler.handle(notification);
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min atrás';
    } else {
      return 'Agora';
    }
  }
}

/// Método auxiliar para mostrar bottom sheet de seleção de tipo de post
extension on _BottomNavScaffoldState {
  /// Mostra bottom sheet para selecionar tipo de post (Músico ou Banda)
  void _showPostTypeBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle visual
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Título
            const Text(
              'Criar post como:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF37475A),
              ),
            ),
            const SizedBox(height: 24),
            
            // Opção: Músico
            _buildPostTypeOption(
              context: context,
              icon: Iconsax.user,
              title: 'Músico',
              subtitle: 'Procuro banda, freela ou projeto',
              color: const Color(0xFF37475A), // Cor escura para músicos
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (context) => PostPage(postType: 'musician'),
                  ),
                );
                if (result == true) {
                  // Post criado com sucesso - invalidar providers
                  ref.invalidate(postNotifierProvider);
                  ref.invalidate(profileProvider);
                }
              },
            ),
            const SizedBox(height: 12),
            
            // Opção: Banda
            _buildPostTypeOption(
              context: context,
              icon: Iconsax.people,
              title: 'Banda',
              subtitle: 'Procuro músico para a banda',
              color: const Color(0xFFE47911), // Cor laranja para bandas
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (context) => PostPage(postType: 'band'),
                  ),
                );
                if (result == true) {
                  // Post criado com sucesso - invalidar providers
                  ref.invalidate(postNotifierProvider);
                  ref.invalidate(profileProvider);
                }
              },
            ),
            const SizedBox(height: 20),

            // Opção: Anúncio
            _buildPostTypeOption(
              context: context,
              icon: Iconsax.tag,
              title: 'Anúncio',
              subtitle: 'Oferecer produto ou serviço',
              color: AppColors.salesBlue, // Cor azul para anúncios
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (context) => PostPage(postType: 'sales'),
                  ),
                );
                if (result == true) {
                  // Post criado com sucesso - invalidar providers
                  ref.invalidate(postNotifierProvider);
                  ref.invalidate(profileProvider);
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Constrói opção de tipo de post no bottom sheet
  Widget _buildPostTypeOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  /// Mostra bottom sheet de troca de perfil
  void _showProfileSwitcher(BuildContext context) {
    final activeProfileId = ref.read(profileProvider).value?.activeProfile?.profileId;
    
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileSwitcherBottomSheet(
        activeProfileId: activeProfileId,
        onProfileSelected: (String profileId) {
          // Invalidar providers quando perfil mudar
          ref.invalidate(profileProvider);
          ref.invalidate(postNotifierProvider);
          Navigator.pop(context);
        },
      ),
    );
  }
}
