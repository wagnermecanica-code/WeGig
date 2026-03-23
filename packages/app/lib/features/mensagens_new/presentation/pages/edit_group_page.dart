import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/utils/debouncer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';

import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/entities.dart';

/// Página de edição/detalhes do grupo
///
/// Features:
/// - Editar nome do grupo
/// - Ver/gerenciar membros
/// - Adicionar novos membros
/// - Remover membros (apenas admin)
/// - Sair do grupo
/// - Deletar grupo (apenas admin)
class EditGroupPage extends ConsumerStatefulWidget {
  const EditGroupPage({
    required this.conversationId,
    required this.groupName,
    this.groupPhotoUrl,
    super.key,
  });

  final String conversationId;
  final String groupName;
  final String? groupPhotoUrl;

  @override
  ConsumerState<EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends ConsumerState<EditGroupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);

  // Estado
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSearching = false;
  bool _showAddMember = false;

  // Dados do grupo
  String? _groupPhotoUrl;
  String? _createdByProfileId;
  List<ParticipantData> _members = [];
  List<_SearchResult> _searchResults = [];
  Set<String> _excludedProfileIds = {};

  // Constantes
  static const int _maxGroupNameLength = 100;
  static const int _maxParticipants = 32;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.groupName;
    _groupPhotoUrl = widget.groupPhotoUrl;
    _loadGroupData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  /// Carrega dados completos do grupo
  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);

    try {
      final activeProfile = ref.read(activeProfileProvider);
      if (activeProfile == null) return;

      // Carregar conversa
      final conversationSnap = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .get();

      final data = conversationSnap.data();
      if (data == null) {
        if (mounted) {
          AppSnackBar.showError(context, 'Grupo não encontrado');
          Navigator.pop(context);
        }
        return;
      }

      _groupPhotoUrl = data['groupPhotoUrl'] as String?;
      _createdByProfileId = data['createdBy'] as String?;

      final participantProfiles =
          (data['participantProfiles'] as List<dynamic>?)?.cast<String>() ?? [];

      // Buscar dados dos membros
      final members = <ParticipantData>[];
      for (var i = 0; i < participantProfiles.length; i += 10) {
        final chunk = participantProfiles.sublist(
          i,
          i + 10 > participantProfiles.length
              ? participantProfiles.length
              : i + 10,
        );

        final profilesSnap = await FirebaseFirestore.instance
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in profilesSnap.docs) {
          final profileData = doc.data();
          members.add(ParticipantData(
            profileId: doc.id,
            uid: profileData['uid'] as String? ?? '',
            name: profileData['name'] as String? ?? 'Usuário',
            photoUrl: profileData['photoUrl'] as String?,
            profileType: profileData['type'] as String?,
          ));
        }
      }

      // Ordenar: criador primeiro, depois alfabético
      members.sort((a, b) {
        if (a.profileId == _createdByProfileId) return -1;
        if (b.profileId == _createdByProfileId) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      // Carregar perfis excluídos (bloqueados)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final excluded = await BlockedRelations.getExcludedProfileIds(
          firestore: FirebaseFirestore.instance,
          profileId: activeProfile.profileId,
          uid: currentUser.uid,
        );
        _excludedProfileIds = excluded.toSet();
      }

      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar grupo: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao carregar dados do grupo');
        setState(() => _isLoading = false);
      }
    }
  }

  /// Verifica se o usuário atual é o admin (criador) do grupo
  bool get _isAdmin {
    final activeProfile = ref.read(activeProfileProvider);
    return activeProfile?.profileId == _createdByProfileId;
  }

  /// Atualiza o nome do grupo
  Future<void> _updateGroupName() async {
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      AppSnackBar.showError(context, 'Nome do grupo não pode ser vazio');
      return;
    }

    if (newName.length > _maxGroupNameLength) {
      AppSnackBar.showError(
        context,
        'Nome muito longo (máx. $_maxGroupNameLength caracteres)',
      );
      return;
    }

    if (newName == widget.groupName) return;

    setState(() => _isSaving = true);

    try {
      final activeProfile = ref.read(activeProfileProvider);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (activeProfile == null || currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final now = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'groupName': newName,
        'updatedAt': now,
      });

      // Adicionar mensagem de sistema com todos os campos obrigatórios
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderProfileId': activeProfile.profileId,
        'senderName': activeProfile.name,
        'senderPhotoUrl': activeProfile.photoUrl ?? '',
        'text': '${activeProfile.name} alterou o nome do grupo para "$newName"',
        'type': 'system',
        'status': 'sent',
        'createdAt': now,
        'updatedAt': null,
        'replyTo': null,
        'deletedByProfiles': <String>[],
        'reactions': <String, dynamic>{},
      });

      // Atualizar lastMessage
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': '${activeProfile.name} alterou o nome do grupo',
        'lastMessageTimestamp': now,
        'lastMessageSenderId': currentUser.uid,
        'lastMessageSenderProfileId': activeProfile.profileId,
      });

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Nome do grupo atualizado');
      }
    } catch (e) {
      debugPrint('❌ Erro ao atualizar nome: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao atualizar nome');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Busca perfis para adicionar ao grupo
  void _onSearchChanged(String query) {
    final sanitized = _sanitizeQuery(query);
    // Debounce curto para busca responsiva
    _searchDebouncer.run(() => _searchProfiles(sanitized));
  }

  String _sanitizeQuery(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    // Remove prefixo @ para permitir buscas por username direto
    final withoutAt = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
    return withoutAt.trim().toLowerCase();
  }

  /// Carrega sugestões padrão (perfis recentes)
  Future<void> _loadDefaultSuggestions() async {
    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      final activeProfile = ref.read(activeProfileProvider);
      if (activeProfile == null) {
        if (mounted) setState(() => _isSearching = false);
        return;
      }

      // Buscar perfis recentes
      final snap = await FirebaseFirestore.instance
          .collection('profiles')
          .orderBy('createdAt', descending: true)
          .limit(30) // Buscar mais para ter margem após filtros
          .get();

      final results = <_SearchResult>[];
      for (final doc in snap.docs) {
        if (results.length >= 10) break;
        
        final profileId = doc.id;
        // Filtrar: eu mesmo, já membros, bloqueados
        if (profileId == activeProfile.profileId) continue;
        if (_members.any((m) => m.profileId == profileId)) continue;
        if (_excludedProfileIds.contains(profileId)) continue;

        final data = doc.data();
        results.add(_SearchResult(
          profileId: profileId,
          uid: data['uid'] as String? ?? '',
          name: data['name'] as String? ?? 'Usuário',
          username: data['username'] as String?,
          photoUrl: data['photoUrl'] as String?,
          profileType: data['type'] as String?,
        ));
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar sugestões padrão: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  /// Busca perfis por username ou nome
  Future<void> _searchProfiles(String query) async {
    if (!mounted) return;

    // Se query vazia, mostrar sugestões padrão
    if (query.isEmpty) {
      await _loadDefaultSuggestions();
      return;
    }

    setState(() => _isSearching = true);

    try {
      final activeProfile = ref.read(activeProfileProvider);
      if (activeProfile == null) {
        if (mounted) setState(() => _isSearching = false);
        return;
      }

      final results = <_SearchResult>[];
      final addedIds = <String>{}; // Evitar duplicatas

      // 1. Busca EXATA por username (mais prioritária)
      debugPrint('🔍 Buscando username exato: $query');
      final exactUsernameSnap = await FirebaseFirestore.instance
          .collection('profiles')
          .where('usernameLowercase', isEqualTo: query)
          .limit(5)
          .get();

      debugPrint('🔍 Resultados username exato: ${exactUsernameSnap.docs.length}');
      for (final doc in exactUsernameSnap.docs) {
        _addResultIfValid(doc, activeProfile.profileId, results, addedIds);
      }

      // 1b. Fallback EXATO em `username` (para docs legados sem usernameLowercase)
      if (results.length < 10) {
        debugPrint('🔍 Buscando username exato (fallback): $query');
        final exactUsernameFallbackSnap = await FirebaseFirestore.instance
            .collection('profiles')
            .where('username', isEqualTo: query)
            .limit(5)
            .get();

        debugPrint(
            '🔍 Resultados username exato (fallback): ${exactUsernameFallbackSnap.docs.length}');
        for (final doc in exactUsernameFallbackSnap.docs) {
          if (results.length >= 10) break;
          _addResultIfValid(doc, activeProfile.profileId, results, addedIds);
        }
      }

      // 2. Busca por PREFIXO de username (começa com...)
      if (results.length < 10) {
        debugPrint('🔍 Buscando username prefixo: $query*');
        final prefixUsernameSnap = await FirebaseFirestore.instance
            .collection('profiles')
            .orderBy('usernameLowercase')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(15)
            .get();

        debugPrint('🔍 Resultados username prefixo: ${prefixUsernameSnap.docs.length}');
        for (final doc in prefixUsernameSnap.docs) {
          if (results.length >= 10) break;
          _addResultIfValid(doc, activeProfile.profileId, results, addedIds);
        }
      }

      // 2b. Fallback PREFIXO em `username` (para docs legados)
      if (results.length < 10) {
        debugPrint('🔍 Buscando username prefixo (fallback): $query*');
        final prefixUsernameFallbackSnap = await FirebaseFirestore.instance
            .collection('profiles')
            .orderBy('username')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(15)
            .get();

        debugPrint(
            '🔍 Resultados username prefixo (fallback): ${prefixUsernameFallbackSnap.docs.length}');
        for (final doc in prefixUsernameFallbackSnap.docs) {
          if (results.length >= 10) break;
          _addResultIfValid(doc, activeProfile.profileId, results, addedIds);
        }
      }

      // 3. Busca por nome - carrega perfis recentes e filtra client-side
      // (campo nameLowercase não existe no Firestore)
      if (results.length < 10) {
        debugPrint('🔍 Buscando por nome (client-side): $query');
        final recentSnap = await FirebaseFirestore.instance
            .collection('profiles')
            .orderBy('createdAt', descending: true)
            .limit(100) // Buscar mais para ter margem
            .get();

        for (final doc in recentSnap.docs) {
          if (results.length >= 10) break;
          
          final data = doc.data();
          final name = (data['name'] as String? ?? '').toLowerCase();
          
          // Verificar se o nome contém a query
          if (name.contains(query)) {
            _addResultIfValid(doc, activeProfile.profileId, results, addedIds);
          }
        }
        debugPrint('🔍 Total resultados após busca por nome: ${results.length}');
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erro na busca: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  /// Helper para adicionar resultado se válido (não duplicado, não bloqueado, etc)
  void _addResultIfValid(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String currentProfileId,
    List<_SearchResult> results,
    Set<String> addedIds,
  ) {
    final profileId = doc.id;
    
    // Já adicionado?
    if (addedIds.contains(profileId)) return;
    // Sou eu?
    if (profileId == currentProfileId) return;
    // Já é membro?
    if (_members.any((m) => m.profileId == profileId)) return;
    // Bloqueado?
    if (_excludedProfileIds.contains(profileId)) return;

    final data = doc.data();
    results.add(_SearchResult(
      profileId: profileId,
      uid: data['uid'] as String? ?? '',
      name: data['name'] as String? ?? 'Usuário',
      username: data['username'] as String?,
      photoUrl: data['photoUrl'] as String?,
      profileType: data['type'] as String?,
    ));
    addedIds.add(profileId);
  }

  /// Adiciona um membro ao grupo
  Future<void> _addMember(_SearchResult profile) async {
    if (_members.length >= _maxParticipants) {
      AppSnackBar.showError(
        context,
        'Limite de $_maxParticipants participantes atingido',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final activeProfile = ref.read(activeProfileProvider);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (activeProfile == null || currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final now = FieldValue.serverTimestamp();

      // Criar novo entry para participantsData
      final newParticipantData = {
        'profileId': profile.profileId,
        'uid': profile.uid,
        'name': profile.name,
        'photoUrl': profile.photoUrl ?? '',
        'profileType': profile.profileType ?? '',
      };

      // Atualizar Firestore com participantsData
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'participantProfiles': FieldValue.arrayUnion([profile.profileId]),
        'participants': FieldValue.arrayUnion([profile.uid]),
        'participantsData.${profile.profileId}': newParticipantData,
        // Garantir que novos integrantes não vejam histórico anterior
        'clearHistoryTimestamp.${profile.profileId}': now,
        'updatedAt': now,
      });

      // Mensagem de sistema com todos os campos obrigatórios
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderProfileId': activeProfile.profileId,
        'senderName': activeProfile.name,
        'senderPhotoUrl': activeProfile.photoUrl ?? '',
        'text': '${activeProfile.name} adicionou ${profile.name} ao grupo',
        'type': 'system',
        'status': 'sent',
        'createdAt': now,
        'updatedAt': null,
        'replyTo': null,
        'deletedByProfiles': <String>[],
        'reactions': <String, dynamic>{},
      });

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': '${activeProfile.name} adicionou ${profile.name}',
        'lastMessageTimestamp': now,
        'lastMessageSenderId': currentUser.uid,
        'lastMessageSenderProfileId': activeProfile.profileId,
      });

      // Atualizar estado local
      if (mounted) {
        setState(() {
          _members.add(ParticipantData(
            profileId: profile.profileId,
            uid: profile.uid,
            name: profile.name,
            photoUrl: profile.photoUrl,
            profileType: profile.profileType,
          ));
          _searchResults.removeWhere((r) => r.profileId == profile.profileId);
          _searchController.clear();
        });
        AppSnackBar.showSuccess(context, '${profile.name} adicionado ao grupo');
      }
    } catch (e) {
      debugPrint('❌ Erro ao adicionar membro: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao adicionar membro');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Remove um membro do grupo (apenas admin)
  Future<void> _removeMember(ParticipantData member) async {
    // Não pode remover a si mesmo (usar "Sair do grupo")
    final activeProfile = ref.read(activeProfileProvider);
    if (member.profileId == activeProfile?.profileId) {
      AppSnackBar.showError(context, 'Use "Sair do grupo" para sair');
      return;
    }

    // Não pode remover o criador
    if (member.profileId == _createdByProfileId) {
      AppSnackBar.showError(context, 'Não é possível remover o criador do grupo');
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Remover ${member.name}?',
      message: 'Esta pessoa será removida do grupo.',
      confirmText: 'Remover',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (activeProfile == null || currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final now = FieldValue.serverTimestamp();

      // Mensagem de sistema ANTES da remoção (regras exigem que o remetente ainda seja participante)
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderProfileId': activeProfile.profileId,
        'senderName': activeProfile.name,
        'senderPhotoUrl': activeProfile.photoUrl ?? '',
        'text': '${activeProfile.name} removeu ${member.name} do grupo',
        'type': 'system',
        'status': 'sent',
        'createdAt': now,
        'updatedAt': null,
        'replyTo': null,
        'deletedByProfiles': <String>[],
        'reactions': <String, dynamic>{},
      });

      // Atualizar lastMessage ANTES de remover (mesma razão de permissão)
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': '${activeProfile.name} removeu ${member.name}',
        'lastMessageTimestamp': now,
        'lastMessageSenderId': currentUser.uid,
        'lastMessageSenderProfileId': activeProfile.profileId,
      });

      final hasSameUserOtherProfiles = _members.any(
        (m) => m.uid == member.uid && m.profileId != member.profileId,
      );

      final updateData = <String, dynamic>{
        'participantProfiles': FieldValue.arrayRemove([member.profileId]),
        'participantsData.${member.profileId}': FieldValue.delete(),
        'updatedAt': now,
      };

      if (!hasSameUserOtherProfiles) {
        updateData['participants'] = FieldValue.arrayRemove([member.uid]);
      }

      // Atualizar Firestore - remover do participantsData e, se aplicável, do participants
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update(updateData);

      if (mounted) {
        setState(() {
          _members.removeWhere((m) => m.profileId == member.profileId);
        });
        AppSnackBar.showSuccess(context, '${member.name} removido do grupo');
      }
    } catch (e) {
      debugPrint('❌ Erro ao remover membro: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao remover membro');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Sair do grupo
  Future<void> _leaveGroup() async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    // Se for o único membro, deletar o grupo
    if (_members.length <= 1) {
      await _deleteGroup();
      return;
    }

    // Se for o admin e tiver outros membros, transferir admin
    if (_isAdmin && _members.length > 1) {
      final confirmed = await _showConfirmDialog(
        title: 'Sair do grupo?',
        message:
            'Você é o administrador. Outro membro será promovido automaticamente.',
        confirmText: 'Sair',
        isDestructive: true,
      );

      if (confirmed != true) return;
    } else {
      final confirmed = await _showConfirmDialog(
        title: 'Sair do grupo?',
        message: 'Você deixará de receber mensagens deste grupo.',
        confirmText: 'Sair',
        isDestructive: true,
      );

      if (confirmed != true) return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final now = FieldValue.serverTimestamp();

      // Mensagem de sistema ANTES de sair (regras exigem que o remetente ainda seja participante)
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderProfileId': activeProfile.profileId,
        'senderName': activeProfile.name,
        'senderPhotoUrl': activeProfile.photoUrl ?? '',
        'text': '${activeProfile.name} saiu do grupo',
        'type': 'system',
        'status': 'sent',
        'createdAt': now,
        'updatedAt': null,
        'replyTo': null,
        'deletedByProfiles': <String>[],
        'reactions': <String, dynamic>{},
      });

      // Atualizar lastMessage ANTES de remover o participante
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': '${activeProfile.name} saiu do grupo',
        'lastMessageTimestamp': now,
        'lastMessageSenderId': currentUser.uid,
        'lastMessageSenderProfileId': activeProfile.profileId,
      });

      // Se for admin, transferir para o próximo membro
      final updateData = <String, dynamic>{
        'participantProfiles': FieldValue.arrayRemove([activeProfile.profileId]),
        'participantsData.${activeProfile.profileId}': FieldValue.delete(),
        'updatedAt': now,
      };

      final hasOtherProfilesSameUser = _members.any(
        (m) => m.uid == activeProfile.uid && m.profileId != activeProfile.profileId,
      );

      if (!hasOtherProfilesSameUser) {
        updateData['participants'] = FieldValue.arrayRemove([activeProfile.uid]);
      }

      if (_isAdmin && _members.length > 1) {
        final nextAdmin =
            _members.firstWhere((m) => m.profileId != activeProfile.profileId);
        updateData['createdBy'] = nextAdmin.profileId;
      }

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update(updateData);

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Você saiu do grupo');
        // Voltar para a lista de mensagens
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('❌ Erro ao sair do grupo: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao sair do grupo');
        setState(() => _isSaving = false);
      }
    }
  }

  /// Deletar grupo (apenas admin)
  Future<void> _deleteGroup() async {
    final confirmed = await _showConfirmDialog(
      title: 'Deletar grupo?',
      message:
          'Esta ação é irreversível. Todas as mensagens serão perdidas para todos os membros.',
      confirmText: 'Deletar',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      // Deletar mensagens em batch
      final messagesSnap = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in messagesSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Deletar conversa
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .delete();

      // Deletar foto do Storage (se existir)
      if (_groupPhotoUrl != null && _groupPhotoUrl!.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(_groupPhotoUrl!).delete();
        } catch (_) {
          // Ignorar erro ao deletar foto
        }
      }

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Grupo deletado');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('❌ Erro ao deletar grupo: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao deletar grupo');
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: TextStyle(
                color: isDestructive ? AppColors.error : AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
        ),
        title: Text(
          'Editar grupo',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto e nome do grupo
                  _buildGroupHeader(),

                  const SizedBox(height: 24),

                  // Membros
                  _buildMembersSection(),

                  const SizedBox(height: 24),

                  // Ações
                  _buildActionsSection(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildGroupHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatares empilhados dos membros (sem opção de editar foto)
          _buildStackedAvatars(),

          const SizedBox(height: 16),

          // Nome do grupo
          TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Nome do grupo',
              hintStyle: TextStyle(color: AppColors.textHint),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            maxLength: _maxGroupNameLength,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                null,
            onSubmitted: (_) => _updateGroupName(),
            onEditingComplete: _updateGroupName,
          ),

          Text(
            '${_members.length} participantes',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói avatares empilhados dos membros do grupo
  Widget _buildStackedAvatars() {
    const double avatarSize = 56;
    const double overlap = 20;
    final displayCount = _members.length > 4 ? 4 : _members.length;
    final totalWidth = displayCount > 0
        ? avatarSize + (displayCount - 1) * (avatarSize - overlap)
        : avatarSize;

    return SizedBox(
      width: totalWidth,
      height: avatarSize,
      child: Stack(
        children: [
          for (int i = 0; i < displayCount && i < _members.length; i++)
            Positioned(
              left: i * (avatarSize - overlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: ClipOval(
                  child: _members[i].photoUrl != null &&
                          _members[i].photoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _members[i].photoUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 112,
                          memCacheHeight: 112,
                          placeholder: (_, __) => _buildAvatarPlaceholder(
                            _members[i].name,
                            avatarSize,
                          ),
                          errorWidget: (_, __, ___) => _buildAvatarPlaceholder(
                            _members[i].name,
                            avatarSize,
                          ),
                        )
                      : _buildAvatarPlaceholder(_members[i].name, avatarSize),
                ),
              ),
            ),
          // Mostrar contador se tiver mais membros
          if (_members.length > 4)
            Positioned(
              left: 3 * (avatarSize - overlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceVariant,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+${_members.length - 3}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name, double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surfaceVariant,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header com botão adicionar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Participantes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_members.length < _maxParticipants)
                TextButton.icon(
                  onPressed: () {
                    final newValue = !_showAddMember;
                    setState(() {
                      _showAddMember = newValue;
                      if (!newValue) {
                        // Limpar resultados ao fechar
                        _searchResults = [];
                        _searchController.clear();
                      }
                    });
                    if (newValue) {
                      // Carregar sugestões iniciais imediatamente
                      _loadDefaultSuggestions();
                    }
                  },
                  icon: Icon(
                    _showAddMember ? Iconsax.close_circle : Iconsax.add_circle,
                    size: 20,
                  ),
                  label: Text(_showAddMember ? 'Cancelar' : 'Adicionar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                  ),
                ),
            ],
          ),
        ),

        // Campo de busca (se adicionando)
        if (_showAddMember) _buildSearchField(),

        // Resultados da busca ou estado vazio
        if (_showAddMember) _buildSearchResults(),

        // Lista de membros
        Container(
          color: AppColors.surface,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              return _buildMemberTile(member);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar por @username ou nome',
          hintStyle: TextStyle(color: AppColors.textHint),
          prefixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Icon(Iconsax.search_normal, color: AppColors.textHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    // Estado de carregamento
    if (_isSearching) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Estado vazio
    if (_searchResults.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Iconsax.user_search,
                size: 40,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 12),
              Text(
                _searchController.text.isEmpty
                    ? 'Digite para buscar perfis'
                    : 'Nenhum perfil encontrado',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Lista de resultados
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return ListTile(
            leading: _buildAvatar(result.photoUrl, result.name),
            title: Text(
              result.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: result.username != null
                ? Text(
                    '@${result.username}',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                : null,
            trailing: IconButton(
              onPressed: _isSaving ? null : () => _addMember(result),
              icon: Icon(Iconsax.add_circle, color: AppColors.accent),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberTile(ParticipantData member) {
    final activeProfile = ref.watch(activeProfileProvider);
    final isMe = member.profileId == activeProfile?.profileId;
    final isCreator = member.profileId == _createdByProfileId;

    return ListTile(
      onTap: isMe
          ? null
          : () {
              // Navegar para perfil
              context.pushProfile(member.profileId);
            },
      leading: _buildAvatar(member.photoUrl, member.name),
      title: Row(
        children: [
          Flexible(
            child: Text(
              isMe ? 'Você' : member.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCreator) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Admin',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: member.profileType != null
          ? Text(
              member.profileType == 'musician'
                  ? 'Músico'
                  : member.profileType == 'band'
                      ? 'Banda'
                      : 'Espaço',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: _isAdmin && !isMe && !isCreator
          ? IconButton(
              onPressed: _isSaving ? null : () => _removeMember(member),
              icon: Icon(Iconsax.close_circle, color: AppColors.error),
              tooltip: 'Remover',
            )
          : null,
    );
  }

  Widget _buildAvatar(String? photoUrl, String name) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant,
      ),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                memCacheWidth: 88,
                memCacheHeight: 88,
              ),
            )
          : Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Sair do grupo
          ListTile(
            onTap: _isSaving ? null : _leaveGroup,
            leading: Icon(Iconsax.logout, color: AppColors.error),
            title: Text(
              'Sair do grupo',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Deletar grupo (apenas admin)
          if (_isAdmin)
            ListTile(
              onTap: _isSaving ? null : _deleteGroup,
              leading: Icon(Iconsax.trash, color: AppColors.error),
              title: Text(
                'Deletar grupo',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Modelo para resultados de busca
class _SearchResult {
  const _SearchResult({
    required this.profileId,
    required this.uid,
    required this.name,
    this.username,
    this.photoUrl,
    this.profileType,
  });

  final String profileId;
  final String uid;
  final String name;
  final String? username;
  final String? photoUrl;
  final String? profileType;
}
