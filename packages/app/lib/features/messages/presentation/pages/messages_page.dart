import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/messages/domain/entities/conversation_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/widgets/conversation_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  // Controllers e estado
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _conversationsSubscription;
  Box? _conversationsBox;
  List<ConversationEntity> _conversations = [];
  bool _isLoading = true;
  ProviderSubscription?
      _profileListener; // ✅ Armazena subscription para cleanup

  // Paginação
  DocumentSnapshot? _lastConversationDoc;
  bool _hasMoreConversations = true;
  final int _conversationsPerPage = 20;
  bool _isLoadingMore = false;

  // Seleção múltipla
  bool _isSelectionMode = false;

  /// Carrega mais conversas para paginação
  Future<void> _loadMoreConversations() async {
    if (_isLoadingMore || !_hasMoreConversations) return;
    setState(() => _isLoadingMore = true);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLoadingMore = false);
      return;
    }
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) {
      debugPrint(
          'MessagesPage: ❌ Não há perfil ativo para carregar mais conversas');
      setState(() => _isLoadingMore = false);
      return;
    }
    final currentProfileId = activeProfile.profileId;
    final query = FirebaseFirestore.instance
        .collection('conversations')
        .where('participantProfiles', arrayContains: currentProfileId)
        .where('archived', isEqualTo: false)
        .orderBy('lastMessageTimestamp', descending: true)
        .startAfterDocument(_lastConversationDoc!)
        .limit(_conversationsPerPage);
    final querySnapshot = await query.get();
    if (querySnapshot.docs.isEmpty) {
      setState(() {
        _hasMoreConversations = false;
        _isLoadingMore = false;
      });
      return;
    }
    final profileFutures = querySnapshot.docs.map((doc) {
      final data = doc.data();
      final participantProfiles =
          (data['participantProfiles'] as List?)?.cast<String>() ?? [];
      final participantUsers =
          (data['participants'] as List?)?.cast<String>() ?? [];
      final otherProfileId = participantProfiles.firstWhere(
        (id) => id != currentProfileId,
        orElse: () => '',
      );
      final otherUserId = participantUsers.firstWhere(
        (id) => id != currentUser.uid,
        orElse: () => currentUser.uid,
      );
      return {
        'doc': doc,
        'otherProfileId': otherProfileId,
        'otherUserId': otherUserId,
        'profileFuture': otherProfileId.isNotEmpty
            ? FirebaseFirestore.instance
                .collection('profiles')
                .doc(otherProfileId)
                .get()
            : Future.value(),
        'userFuture': otherUserId.isNotEmpty
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .get()
            : Future.value(),
      };
    }).toList();

    final profileSnapshots = await Future.wait(
      profileFutures
          .map((item) => item['profileFuture']! as Future<DocumentSnapshot?>)
          .toList(),
    );

    final userSnapshots = await Future.wait(
      profileFutures
          .map((item) => item['userFuture']! as Future<DocumentSnapshot?>)
          .toList(),
    );

    final newConversations = <ConversationEntity>[];
    for (var i = 0; i < profileFutures.length; i++) {
      final item = profileFutures[i];
      final doc = item['doc']! as QueryDocumentSnapshot<Map<String, dynamic>>;
      final otherProfileDoc = profileSnapshots[i];
      final otherUserDoc = userSnapshots[i];

      if (otherProfileDoc == null || !otherProfileDoc.exists) {
        continue;
      }

      try {
        // Build profiles data list
        final otherProfileData =
            otherProfileDoc.data() as Map<String, dynamic>?;
        final otherUserData = otherUserDoc?.data() as Map<String, dynamic>?;

        final profilesData = <Map<String, dynamic>>[];
        if (otherProfileData != null) {
          profilesData.add({
            'profileId': otherProfileDoc.id,
            'uid': otherUserData?['uid'] ?? item['otherUserId'],
            'name': otherProfileData['name'] ?? 'Usuário',
            'photoUrl': otherProfileData['photoUrl'] ?? '',
            ...otherProfileData,
          });
        }

        final entity =
            ConversationEntity.fromFirestore(doc, profilesData: profilesData);
        newConversations.add(entity);
      } catch (e) {
        debugPrint('MessagesPage: Erro ao parsear conversa ${doc.id}: $e');
        continue;
      }
    }
    setState(() {
      _conversations.addAll(newConversations);
      _isLoadingMore = false;
      if (querySnapshot.docs.isNotEmpty) {
        _lastConversationDoc = querySnapshot.docs.last;
      }
    });

    // Salvar no cache usando toJson
    try {
      final conversationsForCache =
          _conversations.map((conv) => conv.toJson()).toList();
      _conversationsBox?.put('conversations', conversationsForCache);
    } catch (e) {
      debugPrint('MessagesPage: Erro ao salvar cache: $e');
    }
  }

  /// Carrega conversas do cache local Hive
  Future<void> _loadConversationsFromCache() async {
    try {
      final cached = _conversationsBox?.get('conversations') as List<dynamic>?;
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _conversations = cached
              .map((item) =>
                  ConversationEntity.fromJson(item as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('MessagesPage: Erro ao carregar cache: $e');
      setState(() => _isLoading = false);
    }
  }

  final Set<String> _selectedConversations = {};

  // Paleta de cores
  static const Color _brandOrange = Color(0xFFE47911);
  static const Color _backgroundColor = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    // Configurar locale pt_BR para timeago
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
    _initCacheAndLoad();
    // Listener para paginação (carregar mais ao rolar até 90%)
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        _loadMoreConversations();
      }
    });
  }

  Future<void> _initCacheAndLoad() async {
    // ⚠️ Hive.initFlutter() deve ser chamado apenas UMA VEZ no main.dart
    // Remover daqui para evitar múltiplas inicializações
    try {
      _conversationsBox = await Hive.openBox('conversationsBox');
      await _loadConversationsFromCache();
      _loadConversations();
    } catch (e) {
      debugPrint('MessagesPage: Erro ao inicializar cache: $e');
      _loadConversations();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ FIX: Usar listenManual com cleanup no dispose
    _profileListener ??= ref.listenManual(
      profileProvider,
      (previous, next) {
        final previousProfileId = previous?.value?.activeProfile?.profileId;
        final newProfileId = next.value?.activeProfile?.profileId;

        if (newProfileId != null && newProfileId != previousProfileId) {
          debugPrint(
              'MessagesPage: Perfil mudou de $previousProfileId para $newProfileId');
          if (mounted) {
            setState(() {
              _conversations = [];
              _isLoading = true;
            });
            _loadConversations();
          }
        }
      },
    );
  }

  @override
  void dispose() {
    // ✅ FIX: Cancelar listener primeiro
    _profileListener?.close();
    _profileListener = null;

    _scrollController.dispose();
    _conversationsSubscription?.cancel();
    // ✅ FIX: Fechar box com tratamento de erro
    _conversationsBox?.close().catchError((e) {
      debugPrint('MessagesPage: Erro ao fechar Hive box: $e');
    });
    super.dispose();
  }

  /// Carrega conversas do Firestore em tempo real
  Future<void> _loadConversations() async {
    try {
      debugPrint('MessagesPage: Iniciando carregamento de conversas...');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('MessagesPage: ❌ Usuário não autenticado');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // ✅ FIX: Usar activeProfileProvider diretamente
      final activeProfile = ref.read(activeProfileProvider);
      debugPrint('MessagesPage: activeProfile = $activeProfile');

      if (activeProfile == null) {
        debugPrint(
            'MessagesPage: ❌ Perfil ativo não encontrado (activeProfile == null)');
        debugPrint(
            'MessagesPage: 💡 Dica: Verifique se o usuário tem perfis criados');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final currentProfileId = activeProfile.profileId;
      debugPrint(
          'MessagesPage: ✅ Buscando conversas para profileId: $currentProfileId (nome: ${activeProfile.name})');

      // Usar stream para atualização em tempo real
      _conversationsSubscription?.cancel();

      debugPrint(
          'MessagesPage: 📡 Criando stream para conversas com profileId: $currentProfileId');

      _conversationsSubscription = FirebaseFirestore.instance
          .collection('conversations')
          .where('participantProfiles', arrayContains: currentProfileId)
          .where('archived', isEqualTo: false)
          .orderBy('lastMessageTimestamp', descending: true)
          .limit(_conversationsPerPage)
          .snapshots()
          .listen((querySnapshot) async {
        debugPrint(
            'MessagesPage: 📦 Recebeu ${querySnapshot.docs.length} conversas do Firestore');

        // ✅ Guard: não processar se widget foi disposed
        if (!mounted) {
          debugPrint('MessagesPage: ⚠️ Widget disposed, ignorando snapshot');
          return;
        }

        // Paraleliza queries de perfis (busca diretamente da coleção profiles)
        final profileFutures = querySnapshot.docs.map((doc) {
          final data = doc.data();
          final participantProfiles =
              (data['participantProfiles'] as List?)?.cast<String>() ?? [];
          final participantUsers =
              (data['participants'] as List?)?.cast<String>() ?? [];
          final otherProfileId = participantProfiles.firstWhere(
            (id) => id != currentProfileId,
            orElse: () => '',
          );
          final otherUserId = participantUsers.firstWhere(
            (id) => id != currentUser.uid,
            orElse: () => currentUser.uid,
          );
          return {
            'doc': doc,
            'otherProfileId': otherProfileId,
            'otherUserId': otherUserId,
            'profileFuture': otherProfileId.isNotEmpty
                ? FirebaseFirestore.instance
                    .collection('profiles')
                    .doc(otherProfileId)
                    .get()
                : Future.value(),
            'userFuture': otherUserId.isNotEmpty
                ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get()
                : Future.value(),
          };
        }).toList();

        final profileSnapshots = await Future.wait(
          profileFutures
              .map(
                  (item) => item['profileFuture']! as Future<DocumentSnapshot?>)
              .toList(),
        );

        final userSnapshots = await Future.wait(
          profileFutures
              .map((item) => item['userFuture']! as Future<DocumentSnapshot?>)
              .toList(),
        );

        final conversations = <ConversationEntity>[];

        for (var i = 0; i < profileFutures.length; i++) {
          final item = profileFutures[i];
          final doc =
              item['doc']! as QueryDocumentSnapshot<Map<String, dynamic>>;
          final otherProfileId = item['otherProfileId']! as String;
          final otherUserId = item['otherUserId']! as String;
          final otherProfileDoc = profileSnapshots[i];
          final otherUserDoc = userSnapshots[i];

          // Debug: mostrar participantProfiles da conversa
          final data = doc.data();
          final participantProfiles =
              (data['participantProfiles'] as List?)?.cast<String>() ?? [];
          debugPrint(
              'MessagesPage: Conversa ${doc.id} tem participantProfiles: $participantProfiles');
          debugPrint(
              'MessagesPage: currentProfileId: $currentProfileId, otherProfileId: $otherProfileId');

          if (otherProfileId.isEmpty ||
              otherProfileDoc == null ||
              !otherProfileDoc.exists) {
            debugPrint(
                'MessagesPage: Ignorando conversa ${doc.id} - perfil do outro não encontrado');
            continue;
          }

          // Buscar dados do perfil diretamente da coleção profiles
          final otherProfileData =
              otherProfileDoc.data() as Map<String, dynamic>?;
          final otherUserData = otherUserDoc?.data() as Map<String, dynamic>?;

          // Build profiles data list
          final profilesData = <Map<String, dynamic>>[];
          if (otherProfileData != null) {
            profilesData.add({
              'profileId': otherProfileDoc.id,
              'uid': otherUserData?['uid'] ?? otherUserId,
              'name': otherProfileData['name'] ?? 'Usuário',
              'photoUrl': otherProfileData['photoUrl'] ?? '',
              'isBand': otherProfileData['isBand'] ?? false,
              'isOnline': otherUserData?['isOnline'] ?? false,
              ...otherProfileData,
            });
          }

          try {
            final entity = ConversationEntity.fromFirestore(doc,
                profilesData: profilesData);
            conversations.add(entity);
          } catch (e) {
            debugPrint('MessagesPage: Erro ao parsear conversa ${doc.id}: $e');
            continue;
          }
        }

        if (mounted) {
          setState(() {
            _conversations = conversations;
            _isLoading = false;
            if (querySnapshot.docs.isNotEmpty) {
              _lastConversationDoc = querySnapshot.docs.last;
            }
          });
          // Salva no cache local usando toJson
          try {
            final conversationsForCache =
                conversations.map((conv) => conv.toJson()).toList();
            _conversationsBox?.put('conversations', conversationsForCache);
          } catch (e) {
            debugPrint('MessagesPage: Erro ao salvar cache: $e');
          }
          debugPrint(
              'MessagesPage: ✅ ${conversations.length} conversas carregadas e exibidas');
        }
      }, onError: (error, stackTrace) {
        debugPrint('MessagesPage: ❌ Erro no stream: $error');
        debugPrint('MessagesPage: StackTrace: $stackTrace');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao carregar conversas: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('MessagesPage: Erro ao configurar stream: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Recarrega conversas (para pull-to-refresh)
  Future<void> _refreshConversations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _loadConversations();
  }

  // ...existing code...

  /// Exclui uma conversa
  Future<void> _deleteConversation(String conversationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversa excluída'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Arquiva conversas selecionadas
  Future<void> _archiveSelectedConversations() async {
    for (final conversationId in _selectedConversations) {
      try {
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .update({'archived': true});
      } catch (e) {
        debugPrint(
            'MessagesPage: Erro ao arquivar conversa $conversationId: $e');
      }
    }

    setState(() {
      _selectedConversations.clear();
      _isSelectionMode = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversas arquivadas'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Marca conversa como lida usando o MessageService
  Future<void> _markAsRead(String conversationId) async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) {
      debugPrint('MessagesPage: ❌ Não há perfil ativo para marcar como lida');
      return;
    }

    final currentProfileId = activeProfile.profileId;

    try {
      // Marca como lida usando o use case
      await ref.read(markAsReadUseCaseProvider).call(
            conversationId: conversationId,
            profileId: currentProfileId,
          );
    } catch (e) {
      debugPrint('Erro ao marcar conversa como lida: $e');
    }
  }

  /// Navega para tela de chat
  void _openChat(ConversationEntity conversation) {
    // Marca como lida
    _markAsRead(conversation.id);

    // Extrai dados do outro participante
    final activeProfileId =
        ref.read(profileProvider).value?.activeProfile?.profileId;
    final otherProfile = conversation.participantProfilesData.firstWhere(
      (p) => p['profileId'] != activeProfileId,
      orElse: () => <String, dynamic>{},
    );

    Navigator.of(context).push(
      MaterialPageRoute(
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

  /// Toggle seleção de conversa
  void _toggleSelection(String conversationId) {
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
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// AppBar com busca e ações
  PreferredSizeWidget _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: _brandOrange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
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
            icon: const Icon(Icons.archive),
            tooltip: 'Arquivar',
            onPressed: _archiveSelectedConversations,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
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
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        // Ícone de busca
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Buscar',
          onPressed: () {
            showSearch(
              context: context,
              delegate: _ConversationSearchDelegate(_conversations),
            );
          },
        ),
      ],
    );
  }

  /// Corpo principal com lista de conversas
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
        ),
      );
    }

    if (_conversations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshConversations,
        color: _brandOrange,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshConversations,
      color: _brandOrange,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _conversations.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator no final da lista
          if (index == _conversations.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
                ),
              ),
            );
          }

          final conversation = _conversations[index];
          return _buildConversationItem(conversation);
        },
      ),
    );
  }

  /// Item da lista de conversas usando widget reutilizável
  Widget _buildConversationItem(ConversationEntity conversation) {
    final conversationId = conversation.id;
    final isSelected = _selectedConversations.contains(conversationId);

    // Converte para Map para manter compatibilidade com ConversationItem widget
    // Adiciona campos necessários para o widget
    final activeProfileId =
        ref.read(profileProvider).value?.activeProfile?.profileId;
    final otherProfile = conversation.participantProfilesData.firstWhere(
      (p) => p['profileId'] != activeProfileId,
      orElse: () => <String, dynamic>{},
    );

    final conversationMap = {
      ...conversation.toJson(),
      'conversationId': conversation.id,
      'otherUserName': otherProfile['name'] ?? 'Usuário',
      'otherUserPhoto': otherProfile['photoUrl'] ?? '',
      'otherProfileId': otherProfile['profileId'] ?? '',
      'otherUserId': otherProfile['uid'] ?? '',
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
      onArchive: (id) async {
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(id)
            .update({'archived': true});
      },
    );
  }
}

/// SearchDelegate customizado para buscar conversas
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
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = conversations.where((conv) {
      // Busca no primeiro perfil (o outro participante)
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
        child: Text(
          'Nenhuma conversa encontrada',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
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
                      imageUrl: otherUserPhoto,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.person),
                      memCacheWidth: 80,
                      memCacheHeight: 80,
                    ),
                  )
                : const Icon(Icons.person),
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
    );
  }
}
