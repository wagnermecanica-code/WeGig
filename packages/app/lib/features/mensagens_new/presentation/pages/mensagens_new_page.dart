import 'dart:async' show unawaited;

import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wegig_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:wegig_app/features/notifications_new/data/services/push_notification_service.dart';

import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/entities.dart';
import '../providers/mensagens_new_providers.dart';
import '../widgets/widgets.dart';
import 'chat_new_page.dart';
import 'group_chat_new_page.dart';

/// Página principal de mensagens - Lista de conversas
///
/// Features:
/// - Lista de conversas com preview da última mensagem
/// - Pull-to-refresh
/// - Swipe para arquivar/deletar
/// - Modo de seleção múltipla
/// - Badge de não lidas
/// - Skeleton loading
/// - Estado vazio
class MensagensNewPage extends ConsumerStatefulWidget {
  const MensagensNewPage({super.key});

  @override
  ConsumerState<MensagensNewPage> createState() => _MensagensNewPageState();
}

enum _ConversationSwipeAction {
  archive,
  delete,
}

class _MensagensNewPageState extends ConsumerState<MensagensNewPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  // Estado de seleção múltipla
  bool _isSelectionMode = false;
  final Set<String> _selectedConversations = {};

  // ✅ Estado para mostrar conversas arquivadas
  bool _showArchived = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ConversationNewEntity> _applySearchFilter(
    List<ConversationNewEntity> conversations,
    String currentProfileId,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return conversations;

    return conversations.where((conv) {
      final isGroup = conv.isGroup || conv.participantProfiles.length > 2;
      final groupName = conv.groupName ?? '';
      final other = conv.getOtherParticipantData(currentProfileId);
      final otherName = other?.name ?? '';
      // Usa profileId como fallback para "username" (identificador curto)
      final otherHandle = other?.profileId ?? '';
      final target = isGroup ? groupName : '$otherName $otherHandle';
      return target.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  void _openChat(ConversationNewEntity conversation) {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    // Marcar como lida e só então recalcular o badge.
    // Se atualizarmos o badge antes do write no Firestore, ele pode manter o valor antigo.
    unawaited(
      ref
          .read(markAsReadNewUseCaseProvider)
          .call(
            conversationId: conversation.id,
            profileId: activeProfile.profileId,
          )
          .then((_) => PushNotificationService().updateAppBadge(
                activeProfile.profileId,
                activeProfile.uid,
              ))
          .catchError((e, _) {
        debugPrint('Erro ao marcar conversa como lida (openChat): $e');
      }),
    );

    // Obter dados do outro participante
    final otherParticipant =
        conversation.getOtherParticipantData(activeProfile.profileId);

    final isGroup = conversation.isGroup || conversation.participantProfiles.length > 2;
    final displayName = isGroup
        ? (conversation.groupName?.isNotEmpty == true
            ? conversation.groupName!
            : 'Grupo')
        : (otherParticipant?.name ?? 'Usuário');

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatNewPage(
          conversationId: conversation.id,
          otherProfileId: isGroup ? '' : (otherParticipant?.profileId ?? ''),
          otherUid: isGroup ? '' : (otherParticipant?.uid ?? ''),
          otherName: displayName,
          otherPhotoUrl: isGroup ? conversation.groupPhotoUrl : otherParticipant?.photoUrl,
          isGroup: isGroup,
          groupPhotoUrl: conversation.groupPhotoUrl,
        ),
      ),
    );
  }

  void _toggleSelection(String conversationId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedConversations.contains(conversationId)) {
        _selectedConversations.remove(conversationId);
        if (_selectedConversations.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedConversations.add(conversationId);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedConversations.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _archiveConversation(String conversationId) async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    try {
      await ref.read(archiveConversationNewUseCaseProvider).call(
        conversationId: conversationId,
        profileId: activeProfile.profileId,
      );

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Conversa arquivada');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao arquivar conversa');
      }
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    try {
      await ref.read(deleteConversationNewUseCaseProvider).call(
        conversationId: conversationId,
        profileId: activeProfile.profileId,
      );

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Conversa removida');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao remover conversa');
      }
    }
  }

  Future<void> _markAsRead(String conversationId) async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    try {
      await ref.read(markAsReadNewUseCaseProvider).call(
        conversationId: conversationId,
        profileId: activeProfile.profileId,
      );

      // Atualiza o badge do ícone após marcar como lida.
      unawaited(
        PushNotificationService().updateAppBadge(
          activeProfile.profileId,
          activeProfile.uid,
        ),
      );
    } catch (e) {
      debugPrint('Erro ao marcar como lida: $e');
    }
  }

  Future<void> _archiveSelected() async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    // Captura quantidade antes de limpar seleção para exibir feedback correto
    final archivedCount = _selectedConversations.length;

    for (final id in _selectedConversations) {
      await ref.read(archiveConversationNewUseCaseProvider).call(
        conversationId: id,
        profileId: activeProfile.profileId,
      );
    }

    _clearSelection();

    if (mounted) {
      AppSnackBar.showSuccess(
        context,
        '$archivedCount conversas arquivadas',
      );
    }
  }

  Future<_ConversationSwipeAction?> _confirmArchiveOrDelete() async {
    return showModalBottomSheet<_ConversationSwipeAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Iconsax.archive_1, color: AppColors.textPrimary),
              title: const Text('Arquivar conversa'),
              onTap: () => Navigator.pop(context, _ConversationSwipeAction.archive),
            ),
            ListTile(
              leading: Icon(Iconsax.trash, color: AppColors.error),
              title: Text(
                'Deletar conversa',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () => Navigator.pop(context, _ConversationSwipeAction.delete),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUid = ref.watch(currentUserProvider)?.uid;
    final activeProfile = ref.watch(activeProfileProvider);

    final isProfileReadyForQueries =
        authUid != null && activeProfile != null && activeProfile.uid == authUid;

    if (!isProfileReadyForQueries) {
      return const Scaffold(
        body: Center(child: AppRadioPulseLoader(size: 52)),
      );
    }

    final conversationsAsync = ref.watch(
      conversationsNewStreamProvider(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
        includeArchived: _showArchived, // ✅ Toggle para mostrar arquivadas
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou @username',
                prefixIcon: Icon(Iconsax.search_normal_1, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar',
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  conversationsNewStreamProvider(
                    profileId: activeProfile.profileId,
                    profileUid: activeProfile.uid,
                    includeArchived: _showArchived,
                  ),
                );
                await Future.delayed(const Duration(milliseconds: 300));
              },
              color: AppColors.accent,
              child: conversationsAsync.when(
                data: (conversations) {
                  final filtered = _applySearchFilter(
                    conversations,
                    activeProfile.profileId,
                  );

                  if (filtered.isEmpty) {
                    return CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyConversationsNewState(
                            showArchived: _showArchived,
                            onToggleArchived: () {
                              setState(() => _showArchived = !_showArchived);
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final conversation = filtered[index];
                      return _buildConversationItem(conversation, activeProfile.profileId);
                    },
                  );
                },
                loading: () => const ConversationsNewSkeleton(),
                error: (error, stack) => CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorNewState(
                        message: error.toString(),
                        onRetry: () => ref.invalidate(
                          conversationsNewStreamProvider(
                            profileId: activeProfile.profileId,                        includeArchived: _showArchived,                      profileUid: activeProfile.uid,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          onPressed: _clearSelection,
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        title: Text(
          '${_selectedConversations.length} selecionada${_selectedConversations.length > 1 ? 's' : ''}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _archiveSelected,
            icon: const Icon(Iconsax.archive_1, color: Colors.white),
            tooltip: 'Arquivar',
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Text(
        _showArchived ? 'Arquivadas' : 'Mensagens',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        // ✅ Menu para alternar entre ativas e arquivadas
        PopupMenuButton<String>(
          icon: Icon(Iconsax.more, color: AppColors.textPrimary),
          onSelected: (value) {
            if (value == 'toggle_archived') {
              final activeProfile = ref.read(activeProfileProvider);
              if (activeProfile == null) return;

              setState(() {
                _showArchived = !_showArchived;
              });

              // ✅ INVALIDAR provider para forçar nova query com novo includeArchived
              ref.invalidate(conversationsNewStreamProvider(
                profileId: activeProfile.profileId,
                profileUid: activeProfile.uid,
                includeArchived: _showArchived,
              ));
            } else if (value == 'new_group_chat') {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GroupChatNewPage(),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'toggle_archived',
              child: Row(
                children: [
                  Icon(
                    _showArchived ? Iconsax.message : Iconsax.archive_1,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 12),
                  Text(_showArchived ? 'Ver conversas' : 'Ver arquivadas'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'new_group_chat',
              child: Row(
                children: [
                  Icon(Iconsax.messages_3, size: 20),
                  SizedBox(width: 12),
                  Text('Novo chat em grupo'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConversationItem(
    ConversationNewEntity conversation,
    String currentProfileId,
  ) {
    final isSelected = _selectedConversations.contains(conversation.id);

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.horizontal,
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.success,
        icon: Iconsax.tick_circle,
        label: 'Lida',
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.error,
        icon: Iconsax.trash,
        label: 'Deletar',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Marcar como lida
          await _markAsRead(conversation.id);
          return false; // Não remove o item
        } else {
          final action = await _confirmArchiveOrDelete();
          if (action == _ConversationSwipeAction.archive) {
            await _archiveConversation(conversation.id);
            return false;
          }

          if (action == _ConversationSwipeAction.delete) {
            return true;
          }

          return false;
        }
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await _deleteConversation(conversation.id);
        }
      },
      child: ConversationNewItem(
        conversation: conversation,
        currentProfileId: currentProfileId,
        isSelected: isSelected,
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(conversation.id);
          } else {
            _openChat(conversation);
          }
        },
        onLongPress: () => _toggleSelection(conversation.id),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerRight) ...[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: Colors.white),
          if (alignment == Alignment.centerLeft) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
