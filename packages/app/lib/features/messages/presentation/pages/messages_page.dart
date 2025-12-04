import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/messages/domain/entities/conversation_entity.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/widgets/conversation_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wegig_app/features/messages/presentation/pages/chat_detail_page.dart';
import 'package:wegig_app/features/messages/presentation/providers/messages_providers.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

class _ConversationSnapshotFutures {
  const _ConversationSnapshotFutures({
    required this.doc,
    required this.otherProfileId,
    required this.otherUserId,
    required this.profileFuture,
    required this.userFuture,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String otherProfileId;
  final String otherUserId;
  final Future<DocumentSnapshot<Map<String, dynamic>>?> profileFuture;
  final Future<DocumentSnapshot<Map<String, dynamic>>?> userFuture;
}

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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _conversationsSubscription;
  Box<dynamic>? _conversationsBox;
  List<ConversationEntity> _conversations = [];
  bool _isLoading = true;
    ProviderSubscription<AsyncValue<ProfileState>>?
      _profileListener; // ✅ Armazena subscription para cleanup
    bool _hasSyncedInitialProfile = false;

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
    if (!mounted) return;
    setState(() => _isLoadingMore = true);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoadingMore = false);
      return;
    }
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) {
      debugPrint(
          'MessagesPage: ❌ Não há perfil ativo para carregar mais conversas');
      if (mounted) setState(() => _isLoadingMore = false);
      return;
    }
    final currentProfileId = activeProfile.profileId;
    final query = FirebaseFirestore.instance
        .collection('conversations')
        .where('participantProfiles', arrayContains: currentProfileId)
        .orderBy('lastMessageTimestamp', descending: true)
        .startAfterDocument(_lastConversationDoc!)
        .limit(_conversationsPerPage);
    final querySnapshot = await query.get();
    if (querySnapshot.docs.isEmpty) {
      if (mounted) {
        setState(() {
          _hasMoreConversations = false;
          _isLoadingMore = false;
        });
      }
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
      return _ConversationSnapshotFutures(
        doc: doc,
        otherProfileId: otherProfileId,
        otherUserId: otherUserId,
        profileFuture: otherProfileId.isNotEmpty
            ? FirebaseFirestore.instance
                .collection('profiles')
                .doc(otherProfileId)
                .get()
            : Future<DocumentSnapshot<Map<String, dynamic>>?>.value(),
        userFuture: otherUserId.isNotEmpty
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .get()
            : Future<DocumentSnapshot<Map<String, dynamic>>?>.value(),
      );
    }).toList();

    final profileSnapshots =
        await Future.wait(profileFutures.map((item) => item.profileFuture));

    final userSnapshots =
        await Future.wait(profileFutures.map((item) => item.userFuture));

    final newConversations = <ConversationEntity>[];
    for (var i = 0; i < profileFutures.length; i++) {
      final item = profileFutures[i];
      final doc = item.doc;
      final otherProfileDoc = profileSnapshots[i];
      final otherUserDoc = userSnapshots[i];

      if (otherProfileDoc == null || !otherProfileDoc.exists) {
        continue;
      }

      try {
        // Build profiles data list
        final otherProfileData = otherProfileDoc.data();
        final otherUserData = otherUserDoc?.data();

        final profilesData = <Map<String, dynamic>>[];
        if (otherProfileData != null) {
          profilesData.add({
            'profileId': otherProfileDoc.id,
            'uid': otherUserData?['uid'] ?? item.otherUserId,
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
    if (mounted) {
      final filtered = newConversations
          .where(
            (conversation) =>
                !conversation.archivedProfileIds.contains(currentProfileId),
          )
          .toList();

      setState(() {
        _conversations.addAll(filtered);
        _isLoadingMore = false;
        if (querySnapshot.docs.isNotEmpty) {
          _lastConversationDoc = querySnapshot.docs.last;
        }
      });
    }

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
        final activeProfileId = ref.read(activeProfileProvider)?.profileId;
        final cachedConversations = cached
            .map((item) =>
                ConversationEntity.fromJson(item as Map<String, dynamic>))
            .where(
              (conversation) => activeProfileId == null
                  ? true
                  : !conversation.archivedProfileIds
                      .contains(activeProfileId),
            )
            .toList();

        if (mounted) {
          setState(() {
            _conversations = cachedConversations;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('MessagesPage: Erro ao carregar cache: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final Set<String> _selectedConversations = {};

  // Paleta de cores
  static const Color _brandOrange = Color(0xFFE47911);
  static const Color _backgroundColor = Color(0xFFFFFFFF);

  /// Listener do ScrollController para paginação (evita memory leak)
  void _onScroll() {
    if (_scrollController.hasClients) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        _loadMoreConversations();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Configurar locale pt_BR para timeago
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
    _initCacheAndLoad();
    // Listener para paginação (carregar mais ao rolar até 90%)
    _scrollController.addListener(_onScroll);
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

    // ✅ FIX: Cancelar listener anterior antes de criar novo
    _profileListener?.close();
    _profileListener = ref.listenManual(
      profileProvider,
      _handleProfileStateChange,
    );

    _handleProfileStateChange(null, ref.read(profileProvider));
  }

  @override
  void dispose() {
    // ✅ FIX: Cancelar listener primeiro
    _profileListener?.close();
    _profileListener = null;

    // ✅ FIX: Remover scroll listener antes de dispose (usa mesma referência)
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _conversationsSubscription?.cancel();
    // ✅ FIX: Fechar box com tratamento de erro
    _conversationsBox?.close().catchError((Object e) {
      debugPrint('MessagesPage: Erro ao fechar Hive box: $e');
    });
    super.dispose();
  }

  /// Carrega conversas do Firestore em tempo real
  Future<void> _loadConversations({ProfileEntity? activeProfileOverride}) async {
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
      final activeProfile = activeProfileOverride ?? ref.read(activeProfileProvider);
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
          return _ConversationSnapshotFutures(
            doc: doc,
            otherProfileId: otherProfileId,
            otherUserId: otherUserId,
            profileFuture: otherProfileId.isNotEmpty
                ? FirebaseFirestore.instance
                    .collection('profiles')
                    .doc(otherProfileId)
                    .get()
                : Future<DocumentSnapshot<Map<String, dynamic>>?>.value(),
            userFuture: otherUserId.isNotEmpty
                ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get()
                : Future<DocumentSnapshot<Map<String, dynamic>>?>.value(),
          );
        }).toList();

        final profileSnapshots =
            await Future.wait(profileFutures.map((item) => item.profileFuture));

        final userSnapshots =
            await Future.wait(profileFutures.map((item) => item.userFuture));

        final conversations = <ConversationEntity>[];

        for (var i = 0; i < profileFutures.length; i++) {
          final item = profileFutures[i];
          final doc = item.doc;
          final otherProfileId = item.otherProfileId;
          final otherUserId = item.otherUserId;
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
            final otherProfileData = otherProfileDoc.data();
            final otherUserData = otherUserDoc?.data();

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

        final filteredConversations = conversations
            .where(
              (conversation) =>
                  !conversation.archivedProfileIds.contains(currentProfileId),
            )
            .toList();

        if (mounted) {
          setState(() {
            _conversations = filteredConversations;
            _isLoading = false;
            if (querySnapshot.docs.isNotEmpty) {
              _lastConversationDoc = querySnapshot.docs.last;
            }
          });
          // Salva no cache local usando toJson
          try {
            final conversationsForCache =
                filteredConversations.map((conv) => conv.toJson()).toList();
            _conversationsBox?.put('conversations', conversationsForCache);
          } catch (e) {
            debugPrint('MessagesPage: Erro ao salvar cache: $e');
          }
          debugPrint(
              'MessagesPage: ✅ ${conversations.length} conversas carregadas e exibidas');
        }
      }, onError: (Object error, StackTrace stackTrace) {
        debugPrint('MessagesPage: ❌ Erro no stream: $error');
        debugPrint('MessagesPage: StackTrace: $stackTrace');
        if (mounted) {
          setState(() => _isLoading = false);
          AppSnackBar.showError(
            context,
            'Erro ao carregar conversas: $error',
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
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _loadConversations();
  }

  void _handleProfileStateChange(
    AsyncValue<ProfileState>? previous,
    AsyncValue<ProfileState> next,
  ) {
    final previousProfileId = previous?.valueOrNull?.activeProfile?.profileId;
    final newProfile = next.valueOrNull?.activeProfile;

    if (newProfile == null) {
      return;
    }

    final hasProfileChanged = previousProfileId != newProfile.profileId;

    if (!_hasSyncedInitialProfile || hasProfileChanged) {
      debugPrint(
          'MessagesPage: Perfil sincronizado (${previousProfileId ?? "none"} -> ${newProfile.profileId})');
      _hasSyncedInitialProfile = true;
      if (mounted) {
        setState(() {
          _conversations = [];
          _isLoading = true;
          _lastConversationDoc = null;
          _hasMoreConversations = true;
          _isSelectionMode = false;
          _selectedConversations.clear();
        });
      }
      _loadConversations(activeProfileOverride: newProfile);
    }
  }

  // ...existing code...

  Future<void> _hideConversation(
    String conversationId, {
    bool showFeedback = true,
  }) async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) {
      debugPrint('MessagesPage: ❌ Não há perfil ativo para ocultar conversa');
      if (mounted && showFeedback) {
        AppSnackBar.showError(
          context,
          'Selecione um perfil para gerenciar conversas',
        );
      }
      return;
    }

    try {
      await ref.read(deleteConversationUseCaseProvider).call(
            conversationId: conversationId,
            profileId: activeProfile.profileId,
          );

      if (mounted && showFeedback) {
        AppSnackBar.showSuccess(
          context,
          'Conversa arquivada para este perfil',
        );
      }
    } catch (e) {
      debugPrint('MessagesPage: Erro ao ocultar conversa $conversationId: $e');
      if (mounted && showFeedback) {
        AppSnackBar.showError(
          context,
          'Erro ao arquivar: $e',
        );
      }
    }
  }

  /// Exclui (oculta) uma conversa apenas para o perfil atual
  Future<void> _deleteConversation(String conversationId) async {
    await _hideConversation(conversationId);
  }

  /// Arquiva conversas selecionadas
  Future<void> _archiveSelectedConversations() async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Selecione um perfil para arquivar conversas',
        );
      }
      return;
    }

    final deleteConversation = ref.read(deleteConversationUseCaseProvider);

    for (final conversationId in _selectedConversations) {
      try {
        await deleteConversation(
          conversationId: conversationId,
          profileId: activeProfile.profileId,
        );
      } catch (e) {
        debugPrint(
          'MessagesPage: Erro ao arquivar conversa $conversationId: $e',
        );
      }
    }

    if (mounted) {
      setState(() {
        _selectedConversations.clear();
        _isSelectionMode = false;
      });
    }

    if (mounted) {
      AppSnackBar.showSuccess(
        context,
        'Conversas arquivadas para este perfil',
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

  /// Toggle seleção de conversa
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
          icon: const Icon(Iconsax.close_circle),
          onPressed: () {
            if (mounted) {
              setState(() {
                _isSelectionMode = false;
                _selectedConversations.clear();
              });
            }
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
                if (mounted) {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedConversations.clear();
                  });
                }
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
          color: Colors.white,
        ),
      ),
      actions: [
        // Ícone de busca com padding adequado
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(Iconsax.search_normal, color: Colors.white),
            tooltip: 'Buscar',
            onPressed: () {
              showSearch(
                context: context,
                delegate: _ConversationSearchDelegate(_conversations),
              );
            },
          ),
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
                    Iconsax.message,
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
      'lastMessageTimestamp': Timestamp.fromDate(
        conversation.lastMessageTimestamp,
      ),
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
        await _hideConversation(id);
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
                          const Icon(Iconsax.user),
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
    );
  }
}
