import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/utils/debouncer.dart';
import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';
import 'package:wegig_app/features/mensagens_new/presentation/pages/chat_new_page.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

/// Página para criar novo chat em grupo (estilo Instagram/WhatsApp)
/// 
/// Features:
/// - Busca por @username ou nome com debounce
/// - Prevenção de leaks: filtra perfis bloqueados
/// - Limite de participantes (32, como Instagram)
/// - Chips visuais com avatar dos selecionados
/// - Validações robustas
/// - Loading states
class GroupChatNewPage extends ConsumerStatefulWidget {
  const GroupChatNewPage({super.key});

  @override
  ConsumerState<GroupChatNewPage> createState() => _GroupChatNewPageState();
}

class _GroupChatNewPageState extends ConsumerState<GroupChatNewPage> {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // Debouncer para busca (300ms como Instagram)
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);
  
  // Estado
  final Set<_ProfileResult> _selected = {};
  List<_ProfileResult> _results = [];
  Set<String> _excludedProfileIds = {};
  bool _isLoading = false;
  bool _isCreating = false;
  bool _hasSearched = false;
  
  // Limites (Instagram limita grupos a 32 participantes)
  static const int _maxParticipants = 32;
  static const int _minParticipants = 1;
  static const int _maxGroupNameLength = 100;
  static const int _searchResultsLimit = 20;

  @override
  void initState() {
    super.initState();
    _loadExcludedProfiles();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _groupNameController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchDebouncer.cancel();
    super.dispose();
  }

  /// Carrega perfis bloqueados/que me bloquearam para filtrar resultados
  Future<void> _loadExcludedProfiles() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final activeProfile = ref.read(activeProfileProvider);
    
    if (currentUser == null || activeProfile == null) return;
    
    try {
      final excluded = await BlockedRelations.getExcludedProfileIds(
        firestore: FirebaseFirestore.instance,
        profileId: activeProfile.profileId,
        uid: currentUser.uid,
      );
      
      if (mounted) {
        setState(() => _excludedProfileIds = excluded.toSet());
      }
    } catch (e) {
      debugPrint('⚠️ GroupChatNewPage: Erro ao carregar bloqueados: $e');
    }
  }

  void _onSearchChanged() {
    _searchDebouncer.run(_runSearch);
  }

  void _onSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus) return;

    // Ao focar o campo vazio, mostrar sugestões (mesmo comportamento do "Adicionar" no editar grupo)
    if (_searchController.text.trim().isEmpty) {
      _loadDefaultSuggestions();
    }
  }

  Future<void> _loadDefaultSuggestions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final activeProfile = ref.read(activeProfileProvider);
    final currentProfileId = activeProfile?.profileId ?? '';

    try {
      final snap = await FirebaseFirestore.instance
          .collection('profiles')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final results = <_ProfileResult>[];
      final seenIds = <String>{};

      for (final doc in snap.docs) {
        if (results.length >= _searchResultsLimit) break;

        final profileId = doc.id;
        if (seenIds.contains(profileId)) continue;
        if (profileId == currentProfileId) continue;
        if (_excludedProfileIds.contains(profileId)) continue;

        final candidate = _ProfileResult.fromFirestore(doc.id, doc.data());
        if (_selected.contains(candidate)) continue;

        // Evitar cards sem username completamente vazio
        if (candidate.username.trim().isEmpty && candidate.name.trim().isEmpty) {
          continue;
        }

        seenIds.add(profileId);
        results.add(candidate);
      }

      if (!mounted) return;
      setState(() {
        _results = results;
      });
    } catch (e) {
      debugPrint('❌ GroupChatNewPage: Erro ao carregar sugestões: $e');
      if (!mounted) return;
      setState(() {
        _results = [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runSearch() async {
    final rawQuery = _searchController.text.trim();
    
    if (rawQuery.isEmpty) {
      // Se o campo está focado, manter a lista de sugestões
      if (_searchFocusNode.hasFocus) {
        await _loadDefaultSuggestions();
        return;
      }

      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    
    // Normaliza: remove @ e converte para lowercase
    final withoutAt = rawQuery.startsWith('@') ? rawQuery.substring(1) : rawQuery;
    final query = withoutAt.trim().toLowerCase();
    
    if (query.length < 2) {
      setState(() {
        _results = [];
        _hasSearched = true;
      });
      return;
    }

    setState(() => _isLoading = true);

    final activeProfile = ref.read(activeProfileProvider);
    final currentProfileId = activeProfile?.profileId ?? '';

    try {
      // Busca por username (exato + prefixo) OU por nome
      final results = <_ProfileResult>[];
      final seenIds = <String>{};
      
      // 1. Busca por username exato
      final usernameSnap = await FirebaseFirestore.instance
          .collection('profiles')
          .where('usernameLowercase', isEqualTo: query)
          .limit(_searchResultsLimit)
          .get();
      
      for (final doc in usernameSnap.docs) {
        final profileId = doc.id;
        
        // Filtros de segurança
        if (seenIds.contains(profileId)) continue;
        if (profileId == currentProfileId) continue; // Não mostrar próprio perfil
        if (_excludedProfileIds.contains(profileId)) continue; // Bloqueados
        
        seenIds.add(profileId);
        final data = doc.data();
        results.add(_ProfileResult.fromFirestore(doc.id, data));
      }

      // 1b. Fallback: username exato (docs legados sem usernameLowercase)
      if (results.length < _searchResultsLimit) {
        final usernameExactFallbackSnap = await FirebaseFirestore.instance
            .collection('profiles')
            .where('username', isEqualTo: query)
            .limit(_searchResultsLimit - results.length)
            .get();

        for (final doc in usernameExactFallbackSnap.docs) {
          final profileId = doc.id;
          if (seenIds.contains(profileId)) continue;
          if (profileId == currentProfileId) continue;
          if (_excludedProfileIds.contains(profileId)) continue;

          final data = doc.data();
          final candidate = _ProfileResult.fromFirestore(doc.id, data);
          if (_selected.contains(candidate)) continue;

          seenIds.add(profileId);
          results.add(candidate);
          if (results.length >= _searchResultsLimit) break;
        }
      }

      // 2. Busca por username prefixo (para permitir busca parcial)
      if (results.length < _searchResultsLimit) {
        final usernamePrefixSnap = await FirebaseFirestore.instance
            .collection('profiles')
            .orderBy('usernameLowercase')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(_searchResultsLimit - results.length)
            .get();

        for (final doc in usernamePrefixSnap.docs) {
          final profileId = doc.id;
          if (seenIds.contains(profileId)) continue;
          if (profileId == currentProfileId) continue;
          if (_excludedProfileIds.contains(profileId)) continue;

          final data = doc.data();
          final candidate = _ProfileResult.fromFirestore(doc.id, data);
          if (_selected.contains(candidate)) continue;

          seenIds.add(profileId);
          results.add(candidate);
          if (results.length >= _searchResultsLimit) break;
        }
      }

      // 2b. Fallback: username prefixo (docs legados)
      if (results.length < _searchResultsLimit) {
        final usernamePrefixFallbackSnap = await FirebaseFirestore.instance
            .collection('profiles')
            .orderBy('username')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(_searchResultsLimit - results.length)
            .get();

        for (final doc in usernamePrefixFallbackSnap.docs) {
          final profileId = doc.id;
          if (seenIds.contains(profileId)) continue;
          if (profileId == currentProfileId) continue;
          if (_excludedProfileIds.contains(profileId)) continue;

          final data = doc.data();
          final candidate = _ProfileResult.fromFirestore(doc.id, data);
          if (_selected.contains(candidate)) continue;

          seenIds.add(profileId);
          results.add(candidate);
          if (results.length >= _searchResultsLimit) break;
        }
      }
      
      // 2. Busca por nome (se ainda tiver espaço nos resultados)
      if (results.length < _searchResultsLimit) {
        try {
          final nameSnap = await FirebaseFirestore.instance
              .collection('profiles')
              .orderBy('nameLowercase')
              .startAt([query])
              .endAt(['$query\uf8ff'])
              .limit(_searchResultsLimit - results.length)
              .get();

          for (final doc in nameSnap.docs) {
            final profileId = doc.id;

            if (seenIds.contains(profileId)) continue;
            if (profileId == currentProfileId) continue;
            if (_excludedProfileIds.contains(profileId)) continue;

            final data = doc.data();
            final candidate = _ProfileResult.fromFirestore(doc.id, data);
            if (_selected.contains(candidate)) continue;

            seenIds.add(profileId);
            results.add(candidate);
          }
        } catch (e) {
          debugPrint('⚠️ GroupChatNewPage: nameLowercase query falhou: $e');

          final recentSnap = await FirebaseFirestore.instance
              .collection('profiles')
              .orderBy('createdAt', descending: true)
              .limit(100)
              .get();

          for (final doc in recentSnap.docs) {
            if (results.length >= _searchResultsLimit) break;
            final profileId = doc.id;
            if (seenIds.contains(profileId)) continue;
            if (profileId == currentProfileId) continue;
            if (_excludedProfileIds.contains(profileId)) continue;

            final data = doc.data();
            final name = (data['name'] as String? ?? '').toLowerCase();
            if (!name.contains(query)) continue;

            final candidate = _ProfileResult.fromFirestore(doc.id, data);
            if (_selected.contains(candidate)) continue;

            seenIds.add(profileId);
            results.add(candidate);
          }
        }
      }

      if (mounted) {
        setState(() {
          _results = results;
          _hasSearched = true;
        });
      }
    } catch (e) {
      debugPrint('❌ GroupChatNewPage: Erro na busca: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao buscar perfis');
        setState(() => _hasSearched = true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelection(_ProfileResult profile) {
    HapticFeedback.selectionClick();
    
    setState(() {
      if (_selected.contains(profile)) {
        _selected.remove(profile);
      } else {
        // Verifica limite de participantes
        if (_selected.length >= _maxParticipants - 1) { // -1 porque o criador já conta
          AppSnackBar.showInfo(
            context,
            'Máximo de $_maxParticipants participantes',
          );
          return;
        }
        _selected.add(profile);
      }
    });
  }

  void _removeSelection(_ProfileResult profile) {
    HapticFeedback.lightImpact();
    setState(() => _selected.remove(profile));
  }

  bool _validateInputs() {
    final groupName = _groupNameController.text.trim();
    
    if (groupName.isEmpty) {
      AppSnackBar.showInfo(context, 'Digite um nome para o grupo');
      return false;
    }
    
    if (groupName.length > _maxGroupNameLength) {
      AppSnackBar.showInfo(
        context,
        'Nome do grupo muito longo (máx. $_maxGroupNameLength caracteres)',
      );
      return false;
    }
    
    if (_selected.length < _minParticipants) {
      AppSnackBar.showInfo(
        context,
        'Selecione pelo menos $_minParticipants participante${_minParticipants > 1 ? "s" : ""}',
      );
      return false;
    }
    
    return true;
  }

  Future<void> _createGroup() async {
    if (_isCreating) return;
    if (!_validateInputs()) return;

    final activeProfile = ref.read(activeProfileProvider);
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (activeProfile == null || currentUser == null) {
      AppSnackBar.showError(context, 'Sessão expirada. Faça login novamente.');
      return;
    }

    final groupName = _groupNameController.text.trim();

    // Monta listas de participantes (perfil criador sempre primeiro)
    final participantsProfiles = <String>[activeProfile.profileId];
    final participantsUids = <String>[currentUser.uid];
    final participantsData = <Map<String, dynamic>>[
      {
        'profileId': activeProfile.profileId,
        'uid': currentUser.uid,
        'name': activeProfile.name,
        'photoUrl': activeProfile.photoUrl ?? '',
      },
    ];

    for (final profile in _selected) {
      if (profile.uid.isEmpty) continue; // Segurança extra
      
      participantsProfiles.add(profile.profileId);
      participantsUids.add(profile.uid);
      participantsData.add({
        'profileId': profile.profileId,
        'uid': profile.uid,
        'name': profile.name,
        'photoUrl': profile.photoUrl,
      });
    }

    setState(() => _isCreating = true);

    final now = DateTime.now();
    final unreadCount = {
      for (final pid in participantsProfiles) pid: 0,
    };

    try {
      // Cria conversa de grupo
      final docRef = await FirebaseFirestore.instance
          .collection('conversations')
          .add({
        // Identificação - CRÍTICO: campos canônicos para distinguir tipo
        'isGroup': true,
        'conversationType': 'group', // Campo canônico imutável
        'groupName': groupName,
        'groupPhotoUrl': null,
        
        // Participantes (UIDs para Security Rules + ProfileIds para queries)
        'participants': participantsUids,
        'participantProfiles': participantsProfiles,
        'participantsData': participantsData, // Cache para evitar lookups
        
        // Última mensagem
        'lastMessage': 'Grupo criado',
        'lastMessageTimestamp': now,
        'lastMessageSenderId': currentUser.uid,
        'lastMessageSenderProfileId': activeProfile.profileId,
        
        // Contadores e status
        'unreadCount': unreadCount,
        'createdAt': now,
        'updatedAt': null,
        'createdBy': activeProfile.profileId,
        
        // Flags por perfil
        'archived': false,
        'archivedByProfiles': <String>[],
        'mutedByProfiles': <String>[],
        'pinnedByProfiles': <String>[],
        'deletedByProfiles': <String>[],
        'clearHistoryTimestamp': <String, dynamic>{},
        'typingIndicators': <String, dynamic>{},
      });

      // Mensagem de sistema inicial
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(docRef.id)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderProfileId': activeProfile.profileId,
        'senderName': activeProfile.name,
        'senderPhotoUrl': activeProfile.photoUrl ?? '',
        'text': '${activeProfile.name} criou o grupo "$groupName"',
        'createdAt': now,
        'updatedAt': null,
        'status': 'sent',
        'type': 'system', // Tipo especial para mensagens de sistema
        'replyTo': null,
        'deletedByProfiles': <String>[],
        'reactions': <String, dynamic>{},
      });

      if (!mounted) return;

      // Navega para o chat do grupo
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ChatNewPage(
            conversationId: docRef.id,
            otherProfileId: '', // Grupo não tem "outro" único
            otherUid: '',
            otherName: groupName,
            otherPhotoUrl: null,
            isGroup: true,
            groupPhotoUrl: null,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ GroupChatNewPage: Erro ao criar grupo: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao criar grupo. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _selected.isNotEmpty && 
                      _groupNameController.text.trim().isNotEmpty &&
                      !_isCreating;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(canCreate),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Header: nome do grupo + busca
            _buildHeader(),
            
            // Participantes selecionados (chips com avatar)
            if (_selected.isNotEmpty) _buildSelectedChips(),
            
            // Divisor
            const Divider(height: 1),
            
            // Resultados da busca
            Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool canCreate) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left_2),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Novo grupo',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: canCreate ? _createGroup : null,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: AppRadioPulseLoader(size: 20, color: AppColors.primary),
                  )
                : Text(
                    'Criar',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: canCreate ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Nome do grupo
          TextField(
            controller: _groupNameController,
            textInputAction: TextInputAction.next,
            maxLength: _maxGroupNameLength,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Nome do grupo',
              hintText: 'Ex.: Banda da semana',
              counterText: '', // Esconde contador
              prefixIcon: const Icon(Iconsax.people, size: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            onChanged: (_) => setState(() {}), // Atualiza botão Criar
          ),
          
          const SizedBox(height: 12),
          
          // Busca de participantes
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou @username',
              prefixIcon: const Icon(Iconsax.search_normal_1, size: 22),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Iconsax.close_circle, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        if (_searchFocusNode.hasFocus) {
                          _loadDefaultSuggestions();
                        } else {
                          setState(() {
                            _results = [];
                            _hasSearched = false;
                          });
                        }
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
          
          // Contador de participantes
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.profile_2user,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_selected.length + 1}/$_maxParticipants participantes',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedChips() {
    return Container(
      color: AppColors.surface,
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _selected.length,
        itemBuilder: (context, index) {
          final profile = _selected.elementAt(index);
          return _SelectedProfileChip(
            profile: profile,
            onRemove: () => _removeSelection(profile),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: AppRadioPulseLoader(size: 44, color: AppColors.primary),
        ),
      );
    }
    
    if (!_hasSearched) {
      return _buildEmptyState(
        icon: Iconsax.search_normal_1,
        title: 'Adicionar participantes',
        subtitle: 'Busque por nome ou @username para\nadicionar pessoas ao grupo',
      );
    }
    
    if (_results.isEmpty) {
      return _buildEmptyState(
        icon: Iconsax.user_search,
        title: 'Nenhum resultado',
        subtitle: 'Nenhum perfil encontrado.\nTente outro nome ou username.',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final profile = _results[index];
        final isSelected = _selected.contains(profile);
        
        return _ProfileListTile(
          profile: profile,
          isSelected: isSelected,
          onTap: () => _toggleSelection(profile),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGETS AUXILIARES
// ============================================================================

/// Chip de perfil selecionado (com avatar estilo Instagram)
class _SelectedProfileChip extends StatelessWidget {
  const _SelectedProfileChip({
    required this.profile,
    required this.onRemove,
  });

  final _ProfileResult profile;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar com X de remover
            Stack(
              children: [
                _ProfileAvatar(
                  photoUrl: profile.photoUrl,
                  isBand: profile.isBand,
                  size: 48,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Nome truncado
            Text(
              profile.firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ListTile de perfil nos resultados de busca
class _ProfileListTile extends StatelessWidget {
  const _ProfileListTile({
    required this.profile,
    required this.isSelected,
    required this.onTap,
  });

  final _ProfileResult profile;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _ProfileAvatar(
        photoUrl: profile.photoUrl,
        isBand: profile.isBand,
        size: 48,
      ),
      title: Text(
        profile.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        '@${profile.username}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

/// Avatar de perfil com CachedNetworkImage
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.photoUrl,
    required this.isBand,
    this.size = 44,
  });

  final String photoUrl;
  final bool isBand;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: (size * 2).toInt(),
          memCacheHeight: (size * 2).toInt(),
          placeholder: (_, __) => _buildPlaceholder(),
          errorWidget: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }
    
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.1),
      ),
      child: Icon(
        isBand ? Iconsax.people : Iconsax.user,
        size: size * 0.5,
        color: AppColors.primary,
      ),
    );
  }
}

// ============================================================================
// MODEL
// ============================================================================

/// Resultado de busca de perfil
@immutable
class _ProfileResult {
  const _ProfileResult({
    required this.profileId,
    required this.uid,
    required this.name,
    required this.username,
    required this.photoUrl,
    required this.isBand,
  });

  factory _ProfileResult.fromFirestore(String id, Map<String, dynamic> data) {
    return _ProfileResult(
      profileId: id,
      uid: (data['uid'] as String?)?.trim() ?? '',
      name: (data['name'] as String?)?.trim() ?? 'Perfil',
      username: (data['username'] as String?)?.trim() ?? '',
      photoUrl: (data['photoUrl'] as String?)?.trim() ?? '',
      isBand: data['isBand'] as bool? ?? false,
    );
  }

  final String profileId;
  final String uid;
  final String name;
  final String username;
  final String photoUrl;
  final bool isBand;

  /// Nome para exibição
  String get displayName => name.isNotEmpty ? name : '@$username';
  
  /// Primeiro nome (para chips)
  String get firstName {
    if (name.isEmpty) return '@$username';
    final parts = name.split(' ');
    return parts.first;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ProfileResult && other.profileId == profileId;

  @override
  int get hashCode => profileId.hashCode;
}
