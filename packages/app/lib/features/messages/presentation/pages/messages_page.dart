import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wegig_app/core/cache/image_cache_manager.dart';
import 'package:core_ui/features/messages/domain/entities/conversation_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/widgets/conversation_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wegig_app/features/messages/presentation/pages/chat_detail_page.dart';
import 'package:wegig_app/features/messages/presentation/providers/messages_providers.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

/// Tela principal de mensagens
/// Lista todas as conversas do usuário com preview da última mensagem
class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});
  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  final ScrollController _scrollController = ScrollController();
  
  // Estado local para paginação (limite do stream)
  int _limit = 20;
  
  // Seleção múltipla
  bool _isSelectionMode = false;
  final Set<String> _selectedConversations = {};

  // Paleta de cores
  static const Color _brandOrange = Color(0xFFE47911);
  static const Color _backgroundColor = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        // Aumentar limite para carregar mais
        // Isso fará o provider recriar o stream com novo limite
        setState(() {
          _limit += 20;
        });
      }
    }
  }

  Future<void> _hideConversation(
    String conversationId, {
    bool showFeedback = true,
  }) async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    try {
      await ref.read(deleteConversationUseCaseProvider).call(
            conversationId: conversationId,
            profileId: activeProfile.profileId,
          );

      if (mounted && showFeedback) {
        AppSnackBar.showSuccess(context, 'Conversa arquivada');
      }
    } catch (e) {
      debugPrint('MessagesPage: Erro ao ocultar conversa $conversationId: $e');
      if (mounted && showFeedback) {
        AppSnackBar.showError(context, 'Erro ao arquivar: $e');
      }
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    await _hideConversation(conversationId);
  }

  Future<void> _archiveSelectedConversations() async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    for (final conversationId in _selectedConversations) {
      await _hideConversation(conversationId, showFeedback: false);
    }

    if (mounted) {
      setState(() {
        _selectedConversations.clear();
        _isSelectionMode = false;
      });
      AppSnackBar.showSuccess(context, 'Conversas arquivadas');
    }
  }

  Future<void> _markAsRead(String conversationId) async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    try {
      await ref.read(markAsReadUseCaseProvider).call(
            conversationId: conversationId,
            profileId: activeProfile.profileId,
          );
    } catch (e) {
      debugPrint('Erro ao marcar conversa como lida: $e');
    }
  }

  void _openChat(ConversationEntity conversation) {
    _markAsRead(conversation.id);

    final activeProfileId = ref.read(activeProfileProvider)?.profileId;
    final otherProfile = conversation.participantProfilesData.firstWhere(
      (p) => p['profileId'] != activeProfileId,
      orElse: () => <String, dynamic>{},
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatDetailPage(
          conversationId: conversation.id,
          otherUserId: (otherProfile['uid'] as String?) ?? '',
          otherProfileId: (otherProfile['profileId'] as String?) ?? '',
          otherUserName: (otherProfile['name'] as String?) ?? 'Usuário',
          otherUserPhoto: (otherProfile['photoUrl'] as String?) ?? '',
        ),
      ),
    );
  }

  void _toggleSelection(String conversationId) {
    if (!mounted) return;
    setState(() {
      if (_selectedConversations.contains(conversationId)) {
        _selectedConversations.remove(conversationId);
        if (_selectedConversations.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedConversations.add(conversationId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);

    if (activeProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final conversationsAsync = ref.watch(conversationsStreamProvider(
      profileId: activeProfile.profileId,
      profileUid: activeProfile.uid,
      limit: _limit,
    ));

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(conversationsAsync.valueOrNull ?? []),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(conversationsStreamProvider);
            },
            color: _brandOrange,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                return _buildConversationItem(conversations[index]);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_brandOrange),
          ),
        ),
        error: (error, stack) {
          debugPrint('MessagesPage Error: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.warning_2, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Erro ao carregar conversas'),
                TextButton(
                  onPressed: () => ref.invalidate(conversationsStreamProvider),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(List<ConversationEntity> conversations) {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: _brandOrange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Iconsax.close_circle),
          onPressed: () {
            setState(() {
              _isSelectionMode = false;
              _selectedConversations.clear();
            });
          },
        ),
        title: Text('${_selectedConversations.length} selecionada(s)'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.archive),
            tooltip: 'Arquivar',
            onPressed: _archiveSelectedConversations,
          ),
          IconButton(
            icon: const Icon(Iconsax.trash),
            tooltip: 'Excluir',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Excluir conversas'),
                  content: Text(
                    'Deseja excluir ${_selectedConversations.length} conversa(s)?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              );

              if (confirm ?? false) {
                for (final id in _selectedConversations) {
                  await _deleteConversation(id);
                }
                setState(() {
                  _isSelectionMode = false;
                  _selectedConversations.clear();
                });
              }
            },
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: _brandOrange,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Mensagens',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Iconsax.search_normal, color: Colors.white),
            tooltip: 'Buscar',
            onPressed: () {
              showSearch(
                context: context,
                delegate: _ConversationSearchDelegate(conversations),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(conversationsStreamProvider),
      color: _brandOrange,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.message, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma conversa ainda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'As conversas aparecerão aqui',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(ConversationEntity conversation) {
    final conversationId = conversation.id;
    final isSelected = _selectedConversations.contains(conversationId);
    final activeProfileId = ref.read(activeProfileProvider)?.profileId;

    // Extrair dados do outro perfil usando participantProfilesData enriquecido
    final otherProfile = conversation.participantProfilesData.firstWhere(
      (p) => p['profileId'] != activeProfileId,
      orElse: () => <String, dynamic>{},
    );

    final unreadCount = activeProfileId != null
        ? conversation.getUnreadCountForProfile(activeProfileId)
        : 0;
    final isBand = (otherProfile['isBand'] as bool?) ?? false;
    final isOnline = (otherProfile['isOnline'] as bool?) ?? false;

    final conversationMap = {
      ...conversation.toJson(),
      'conversationId': conversation.id,
      'otherUserName': otherProfile['name'] ?? 'Usuário',
      'otherUserPhoto': otherProfile['photoUrl'] ?? '',
      'otherProfileId': otherProfile['profileId'] ?? '',
      'otherUserId': otherProfile['uid'] ?? '',
      'unreadCount': unreadCount,
      'currentProfileId': activeProfileId ?? '',
      'type': isBand ? 'band' : 'musician',
      'isOnline': isOnline,
      'lastMessageTimestamp': Timestamp.fromDate(conversation.lastMessageTimestamp),
    };

    return ConversationItem(
      conversation: conversationMap,
      isSelected: isSelected,
      isSelectionMode: _isSelectionMode,
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(conversationId);
        } else {
          _openChat(conversation);
        }
      },
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _toggleSelection(conversationId);
        });
      },
      onToggleSelection: () => _toggleSelection(conversationId),
      onDelete: _deleteConversation,
      onArchive: _hideConversation,
    );
  }
}

class _ConversationSearchDelegate extends SearchDelegate<ConversationEntity?> {
  _ConversationSearchDelegate(this.conversations);
  final List<ConversationEntity> conversations;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Iconsax.close_circle),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Iconsax.arrow_left_2),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final results = conversations.where((conv) {
      final otherProfile = conv.participantProfilesData.isNotEmpty
          ? conv.participantProfilesData.first
          : <String, dynamic>{};

      final name = (otherProfile['name'] as String? ?? '').toLowerCase();
      final message = conv.lastMessage.toLowerCase();
      final q = query.toLowerCase();

      return name.contains(q) || message.contains(q);
    }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text('Nenhuma conversa encontrada', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          color: Colors.grey[100],
          child: const Text(
            'Buscando nas conversas carregadas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final conversation = results[index];
              final otherProfile = conversation.participantProfilesData.isNotEmpty
                  ? conversation.participantProfilesData.first
                  : <String, dynamic>{};

              final otherUserPhoto = otherProfile['photoUrl'] as String? ?? '';
              final otherUserName = otherProfile['name'] as String? ?? 'Usuário';

              return ListTile(
                leading: CircleAvatar(
                  child: otherUserPhoto.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            cacheManager: WeGigImageCacheManager.instance,
                            imageUrl: otherUserPhoto,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
                            ),
                            errorWidget: (context, url, error) => const Icon(Iconsax.user),
                            memCacheWidth: 80,
                            memCacheHeight: 80,
                          ),
                        )
                      : const Icon(Iconsax.user),
                ),
                title: Text(otherUserName),
                subtitle: Text(
                  conversation.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => close(context, conversation),
              );
            },
          ),
        ),
      ],
    );
  }
}
