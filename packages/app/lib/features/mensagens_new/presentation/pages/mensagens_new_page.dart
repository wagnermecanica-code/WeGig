import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/entities.dart';
import '../providers/mensagens_new_providers.dart';
import '../widgets/widgets.dart';
import 'chat_new_page.dart';

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
  
  // Estado de seleção múltipla
  bool _isSelectionMode = false;
  final Set<String> _selectedConversations = {};

  // ✅ Estado para mostrar conversas arquivadas
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openChat(ConversationNewEntity conversation) {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    // Marcar como lida
    ref.read(markAsReadNewUseCaseProvider).call(
      conversationId: conversation.id,
      profileId: activeProfile.profileId,
    );

    // Obter dados do outro participante
    final otherParticipant =
        conversation.getOtherParticipantData(activeProfile.profileId);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatNewPage(
          conversationId: conversation.id,
          otherProfileId: otherParticipant?.profileId ?? '',
          otherUid: otherParticipant?.uid ?? '',
          otherName: otherParticipant?.name ?? 'Usuário',
          otherPhotoUrl: otherParticipant?.photoUrl,
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
    } catch (e) {
      debugPrint('Erro ao marcar como lida: $e');
    }
  }

  Future<void> _archiveSelected() async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

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
        '${_selectedConversations.length} conversas arquivadas',
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
    final activeProfile = ref.watch(activeProfileProvider);

    if (activeProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            conversationsNewStreamProvider(
              profileId: activeProfile.profileId,
              profileUid: activeProfile.uid,
              includeArchived: _showArchived,
            ),
          );
          // Aguarda um pouco para o stream reinicializar
          await Future.delayed(const Duration(milliseconds: 300));
        },
        color: AppColors.accent,
        child: conversationsAsync.when(
          data: (conversations) {
            if (conversations.isEmpty) {
              // CustomScrollView permite pull-to-refresh mesmo com lista vazia
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
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
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
