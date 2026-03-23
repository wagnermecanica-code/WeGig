import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:wegig_app/core/firebase/blocked_profiles.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';
import 'package:wegig_app/features/notifications_new/data/services/push_notification_service.dart';

import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/entities.dart';
import '../providers/chat_new_controller.dart';
import '../providers/mensagens_new_providers.dart';
import '../widgets/widgets.dart';
import 'edit_group_page.dart';
import 'package:wegig_app/app/router/app_router.dart';

/// Página de chat individual
///
/// Features:
/// - Mensagens em tempo real
/// - Envio de texto e imagem
/// - Reações em mensagens (long press)
/// - Reply (responder mensagem)
/// - Editar/deletar mensagem
/// - Indicador de digitação
/// - Scroll automático para última mensagem
/// - Paginação (load more)
class ChatNewPage extends ConsumerStatefulWidget {
  const ChatNewPage({
    required this.conversationId,
    required this.otherProfileId,
    required this.otherUid,
    required this.otherName,
    this.otherPhotoUrl,
    this.isGroup = false,
    this.groupPhotoUrl,
    super.key,
  });

  /// ID da conversa
  final String conversationId;

  /// ProfileId do outro participante
  final String otherProfileId;

  /// UID do outro participante
  final String otherUid;

  /// Nome do outro participante
  final String otherName;

  /// Foto do outro participante
  final String? otherPhotoUrl;

  final bool isGroup;
  final String? groupPhotoUrl;

  @override
  ConsumerState<ChatNewPage> createState() => _ChatNewPageState();
}

class _ChatNewPageState extends ConsumerState<ChatNewPage> {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isUploading = false;

  StreamSubscription<List<String>>? _excludedSubscription;
  String? _resolvedOtherProfileId;
  ProviderSubscription<ChatNewState>? _chatStateSubscription;

  // Mensagem selecionada para ações
  MessageNewEntity? _selectedMessage;
  Offset? _selectedMessagePosition;

  // ✅ Cache de dados dos participantes para grupos
  Map<String, ParticipantData> _participantsCache = {};
  bool _isLoadingParticipants = false;

  // ✅ Set de profileIds bloqueados (para filtrar mensagens em grupos)
  Set<String> _blockedProfileIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // 🔒 Bloqueios: impede abrir conversa com usuário bloqueado (apenas 1:1)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isGroup) {
        _exitIfBlocked();
      } else {
        // Para grupos: carregar lista de bloqueados para filtrar mensagens
        _loadBlockedProfiles();
      }
    });

    // Marcar como lida ao abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final activeProfile = ref.read(activeProfileProvider);
      if (activeProfile == null) return;
      
      // Para grupos, marcar como received primeiro (implica que chegou no dispositivo)
      if (widget.isGroup) {
        _markGroupMessagesAsReceived(activeProfile.profileId);
      }
      
      _markAsRead();

      // ✅ Marcar como lida sempre que chegar nova mensagem enquanto o chat está aberto
      _chatStateSubscription = ref.listenManual(
        chatNewControllerProvider(widget.conversationId),
        (prev, next) {
          if (!mounted) return;

          final currentProfile = ref.read(activeProfileProvider);
          if (currentProfile == null) return;

          final hasUnreadIncoming = next.messages.any(
            (msg) =>
                msg.senderProfileId != currentProfile.profileId &&
                msg.status != MessageDeliveryStatus.read,
          );

          if (hasUnreadIncoming) {
            // Para grupos, marcar received também
            if (widget.isGroup) {
              _markGroupMessagesAsReceived(currentProfile.profileId);
            }
            _markAsRead();
          }
        },
      );
    });

    // ✅ Carregar participantes se for grupo
    if (widget.isGroup) {
      _loadGroupParticipants();
    }
  }

  /// ✅ Carrega lista de perfis bloqueados (para filtrar mensagens em grupos)
  Future<void> _loadBlockedProfiles() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    try {
      final excluded = await BlockedRelations.getExcludedProfileIds(
        firestore: FirebaseFirestore.instance,
        profileId: activeProfile.profileId,
        uid: currentUser.uid,
      );

      if (mounted) {
        setState(() {
          _blockedProfileIds = excluded.toSet();
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar perfis bloqueados: $e');
    }
  }

  /// ✅ Verifica se um perfil está bloqueado
  bool _isProfileBlocked(String profileId) {
    return _blockedProfileIds.contains(profileId);
  }

  /// ✅ Carrega dados de todos os participantes do grupo
  Future<void> _loadGroupParticipants() async {
    if (_isLoadingParticipants) return;
    setState(() => _isLoadingParticipants = true);
    try {
      final conversationSnap = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .get();

      final data = conversationSnap.data();
      if (data == null) return;

      final participantProfiles =
          (data['participantProfiles'] as List<dynamic>?)?.cast<String>() ?? [];

      // Buscar dados de todos os participantes
      final activeProfile = ref.read(activeProfileProvider);
      final currentProfileId = activeProfile?.profileId ?? '';

      final otherIds = participantProfiles
          .where((id) => id != currentProfileId)
          .toList();

      if (otherIds.isEmpty) return;

      // Buscar em batches de 10 (limite do Firestore)
      final cache = <String, ParticipantData>{};
      for (var i = 0; i < otherIds.length; i += 10) {
        final chunk = otherIds.sublist(
          i,
          i + 10 > otherIds.length ? otherIds.length : i + 10,
        );

        final profilesSnap = await FirebaseFirestore.instance
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in profilesSnap.docs) {
          final profileData = doc.data();
          cache[doc.id] = ParticipantData(
            profileId: doc.id,
            uid: profileData['uid'] as String? ?? '',
            name: profileData['name'] as String? ?? 'Usuário',
            photoUrl: profileData['photoUrl'] as String?,
            profileType: profileData['type'] as String?,
          );
        }
      }

      if (mounted) {
        setState(() {
          _participantsCache = cache;
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar participantes do grupo: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingParticipants = false);
      }
    }
  }

  /// ✅ Obtém dados de um participante pelo profileId
  ParticipantData? _getParticipantData(String profileId) {
    return _participantsCache[profileId];
  }

  Future<String> _resolveOtherProfileId() async {
    if (_resolvedOtherProfileId != null) return _resolvedOtherProfileId!;

    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) {
      _resolvedOtherProfileId = widget.otherProfileId.trim();
      return _resolvedOtherProfileId!;
    }

    var otherProfileId = widget.otherProfileId.trim();
    if (otherProfileId.isEmpty) {
      try {
        final conversationSnap = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(widget.conversationId)
            .get();
        final data = conversationSnap.data();
        final participantProfiles =
            (data?['participantProfiles'] as List<dynamic>?)?.cast<String>() ??
                <String>[];
        otherProfileId = participantProfiles.firstWhere(
          (p) => p != activeProfile.profileId,
          orElse: () => '',
        );
      } catch (_) {
        // Best-effort only.
      }
    }

    _resolvedOtherProfileId = otherProfileId.trim();
    return _resolvedOtherProfileId!;
  }

  Future<void> _startBlockedWatcher() async {
    if (_excludedSubscription != null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    final otherProfileId = await _resolveOtherProfileId();
    if (otherProfileId.isEmpty) return;

    _excludedSubscription = BlockedRelations.watchExcludedProfileIds(
      firestore: FirebaseFirestore.instance,
      profileId: activeProfile.profileId,
      uid: currentUser.uid,
    ).listen(
      (excluded) {
        if (!mounted) return;
        if (excluded.contains(otherProfileId)) {
          AppSnackBar.showError(context, 'Conversa indisponível');
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        }
      },
      onError: (_) {
        // Não derrubar a UI por falha de stream.
      },
    );
  }

  Future<void> _exitIfBlocked() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    try {
      final otherProfileId = await _resolveOtherProfileId();
      if (otherProfileId.isEmpty) return;

      final excluded = await BlockedRelations.getExcludedProfileIds(
        firestore: FirebaseFirestore.instance,
        profileId: activeProfile.profileId,
        uid: currentUser.uid,
      );

      if (excluded.contains(otherProfileId)) {
        if (!mounted) return;
        AppSnackBar.showError(context, 'Conversa indisponível');
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        return;
      }

      await _startBlockedWatcher();
    } catch (_) {
      // Se falhar, não bloqueia a UI; guard adicional existe no envio.
    }
  }

  Future<bool> _isOtherUserBlocked() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return false;

    final otherProfileId = await _resolveOtherProfileId();
    if (otherProfileId.isEmpty) return false;

    final excluded = await BlockedRelations.getExcludedProfileIds(
      firestore: FirebaseFirestore.instance,
      profileId: activeProfile.profileId,
      uid: currentUser.uid,
    );
    return excluded.contains(otherProfileId);
  }

  @override
  void dispose() {
    _excludedSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more quando chegar perto do topo (lista invertida)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref
          .read(chatNewControllerProvider(widget.conversationId).notifier)
          .loadMore();
    }
  }

  void _markAsRead() {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    if (widget.isGroup) {
      // Para grupos, usar método específico que atualiza readBy/receivedBy
      _markGroupMessagesAsRead(activeProfile.profileId);
    } else {
      // Para 1:1, usa método padrão
      unawaited(
        ref
            .read(markAsReadNewUseCaseProvider)
            .call(
              conversationId: widget.conversationId,
              profileId: activeProfile.profileId,
            )
            .then((_) => PushNotificationService().updateAppBadge(
                  activeProfile.profileId,
                  activeProfile.uid,
                ))
            .catchError((e, _) {
          debugPrint('Erro ao marcar conversa como lida (chat): $e');
        }),
      );
    }
  }

  /// Marca mensagens como lidas em grupo (atualiza readBy de cada mensagem)
  void _markGroupMessagesAsRead(String profileId) {
    unawaited(
      ref
          .read(mensagensNewRepositoryProvider)
          .markGroupMessagesAsRead(
            conversationId: widget.conversationId,
            profileId: profileId,
          )
          .then((_) {
            final activeProfile = ref.read(activeProfileProvider);
            if (activeProfile != null) {
              PushNotificationService().updateAppBadge(
                activeProfile.profileId,
                activeProfile.uid,
              );
            }
          })
          .catchError((e, _) {
        debugPrint('Erro ao marcar mensagens do grupo como lidas: $e');
      }),
    );
  }

  /// Marca mensagens como recebidas em grupo (atualiza receivedBy de cada mensagem)
  void _markGroupMessagesAsReceived(String profileId) {
    unawaited(
      ref
          .read(mensagensNewRepositoryProvider)
          .markGroupMessagesAsReceived(
            conversationId: widget.conversationId,
            profileId: profileId,
          )
          .catchError((e, _) {
        debugPrint('Erro ao marcar mensagens do grupo como recebidas: $e');
      }),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (await _isOtherUserBlocked()) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Conversa indisponível');
      return;
    }

    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    final chatState = ref.read(chatNewControllerProvider(widget.conversationId));
    final chatNotifier =
        ref.read(chatNewControllerProvider(widget.conversationId).notifier);

    // Se estiver editando, atualiza a mensagem
    final editing = chatState.editingMessage;
    if (editing != null) {
      await chatNotifier.editMessage(
        messageId: editing.id,
        newText: text,
      );
      return;
    }

    await ref
        .read(chatNewControllerProvider(widget.conversationId).notifier)
        .sendMessage(
          senderId: activeProfile.uid,
          senderProfileId: activeProfile.profileId,
          text: text,
          senderName: activeProfile.name,
          senderPhotoUrl: activeProfile.photoUrl,
        );

    // Scroll para o final
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    try {
      if (await _isOtherUserBlocked()) {
        if (!mounted) return;
        AppSnackBar.showError(context, 'Conversa indisponível');
        return;
      }

      debugPrint('📷 ChatNewPage: Iniciando seleção de imagem...');
      
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        requestFullMetadata: false, // Evita problemas de permissão no iOS 18
      );

      if (pickedFile == null) {
        debugPrint('📷 ChatNewPage: Nenhuma imagem selecionada');
        return;
      }

      debugPrint('📷 ChatNewPage: Imagem selecionada: ${pickedFile.path}');
      setState(() => _isUploading = true);

      // Verificar se o arquivo existe
      final file = File(pickedFile.path);
      if (!await file.exists()) {
        throw Exception('Arquivo de imagem não encontrado');
      }

      // Comprimir imagem
      debugPrint('📷 ChatNewPage: Comprimindo imagem...');
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        targetPath,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg, // Força JPEG sem alpha channel
        keepExif: false, // Remove metadados desnecessários
      );

      if (compressedFile == null) {
        throw Exception('Erro ao comprimir imagem');
      }

      debugPrint('📷 ChatNewPage: Imagem comprimida: ${compressedFile.path}');

      // Upload para Firebase Storage
      final activeProfile = ref.read(activeProfileProvider);
      if (activeProfile == null) {
        throw Exception('Perfil ativo não encontrado');
      }

      // Verificar autenticação
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      debugPrint('📷 ChatNewPage: Usuário autenticado: ${currentUser.uid}');

      debugPrint('📷 ChatNewPage: Fazendo upload para Firebase Storage...');
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(compressedFile.path)}';
      final storagePath = 'chat_images/${widget.conversationId}/$fileName';
      debugPrint('📷 ChatNewPage: Storage path: $storagePath');
      
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      // Adicionar metadata com content-type
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': currentUser.uid,
          'conversationId': widget.conversationId,
        },
      );

      final uploadTask = storageRef.putFile(
        File(compressedFile.path),
        metadata,
      );
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      debugPrint('📷 ChatNewPage: Upload concluído: $imageUrl');

      // Enviar mensagem com imagem
      await ref
          .read(chatNewControllerProvider(widget.conversationId).notifier)
          .sendImageMessage(
            senderId: activeProfile.uid,
            senderProfileId: activeProfile.profileId,
            imageUrl: imageUrl,
            senderName: activeProfile.name,
            senderPhotoUrl: activeProfile.photoUrl,
          );

      debugPrint('✅ ChatNewPage: Imagem enviada com sucesso!');
      _scrollToBottom();
    } catch (e, stackTrace) {
      debugPrint('❌ ChatNewPage: Erro ao enviar imagem - $e');
      debugPrint('$stackTrace');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao enviar imagem: ${e.toString().split(':').last.trim()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _typingDisplayName(ChatNewState chatState) {
    final typingId = chatState.typingProfileId;

    if (widget.isGroup) {
      final participantName = typingId != null
          ? _getParticipantData(typingId)?.name
          : null;
      if (participantName != null && participantName.isNotEmpty) {
        return participantName;
      }
      return 'Alguém';
    }

    if (widget.otherName.isNotEmpty) {
      return widget.otherName;
    }
    return 'Contato';
  }

  void _onTyping() {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    ref
        .read(chatNewControllerProvider(widget.conversationId).notifier)
        .onTyping(activeProfile.profileId);
  }

  void _showMessageActions(MessageNewEntity message, Offset position) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedMessage = message;
      _selectedMessagePosition = position;
    });
  }

  void _hideMessageActions() {
    setState(() {
      _selectedMessage = null;
      _selectedMessagePosition = null;
    });
  }

  Future<void> _handleReaction(String emoji) async {
    if (_selectedMessage == null) return;

    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    final currentReaction =
        _selectedMessage!.getReactionByProfile(activeProfile.profileId);

    if (currentReaction == emoji) {
      // Remover reação
      await ref
          .read(chatNewControllerProvider(widget.conversationId).notifier)
          .removeReaction(
            messageId: _selectedMessage!.id,
            profileId: activeProfile.profileId,
          );
    } else {
      // Adicionar/trocar reação
      await ref
          .read(chatNewControllerProvider(widget.conversationId).notifier)
          .addReaction(
            messageId: _selectedMessage!.id,
            profileId: activeProfile.profileId,
            emoji: emoji,
          );
    }

    _hideMessageActions();
  }

  void _replyToMessage(MessageNewEntity message) {
    ref
        .read(chatNewControllerProvider(widget.conversationId).notifier)
        .setReplyingTo(message);
    _hideMessageActions();
  }

  void _editMessage(MessageNewEntity message) {
    ref
        .read(chatNewControllerProvider(widget.conversationId).notifier)
        .setEditingMessage(message);
    _hideMessageActions();
  }

  Future<void> _deleteMessage(MessageNewEntity message, bool forEveryone) async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    if (forEveryone) {
      await ref
          .read(chatNewControllerProvider(widget.conversationId).notifier)
          .deleteMessageForEveryone(messageId: message.id);
    } else {
      await ref
          .read(chatNewControllerProvider(widget.conversationId).notifier)
          .deleteMessageForMe(
            messageId: message.id,
            profileId: activeProfile.profileId,
          );
    }

    _hideMessageActions();
  }

  void _showDeleteDialog(MessageNewEntity message) {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    final isMine = message.senderProfileId == activeProfile.profileId;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Iconsax.trash, color: AppColors.textSecondary),
                title: const Text('Apagar para mim'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message, false);
                },
              ),
              if (isMine)
                ListTile(
                  leading: Icon(Iconsax.trash, color: AppColors.error),
                  title: Text(
                    'Apagar para todos',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message, true);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);
    final chatState =
        ref.watch(chatNewControllerProvider(widget.conversationId));

    if (activeProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(chatState),
      body: Stack(
        children: [
          Column(
            children: [
              // Lista de mensagens
              Expanded(
                child: _buildMessagesList(chatState, activeProfile.profileId),
              ),

              if (chatState.isOtherTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_typingDisplayName(chatState)} digitando...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),

              // Input bar
              ChatNewInputBar(
                onSend: _sendMessage,
                onTyping: _onTyping,
                onImageTap: _isUploading ? null : _pickAndSendImage,
                replyingTo: chatState.replyingTo,
                editingMessage: chatState.editingMessage,
                onCancelReplyOrEdit: () {
                  ref
                      .read(chatNewControllerProvider(widget.conversationId)
                          .notifier)
                      .cancelReplyOrEdit();
                },
                isSending: chatState.isSending || _isUploading,
              ),
            ],
          ),

          // Overlay de reações e menu de ações
          if (_selectedMessage != null)
            ReactionNewPickerModal(
              onReactionSelected: _handleReaction,
              onDismiss: _hideMessageActions,
              currentReaction: _selectedMessage!
                  .getReactionByProfile(activeProfile.profileId),
              anchorPosition: _selectedMessagePosition,
              isMine: _selectedMessage!.senderProfileId == activeProfile.profileId,
              canEdit: _selectedMessage!.canEdit(activeProfile.profileId),
              onReply: () => _replyToMessage(_selectedMessage!),
              onEdit: _selectedMessage!.canEdit(activeProfile.profileId)
                  ? () => _editMessage(_selectedMessage!)
                  : null,
              onCopy: _selectedMessage!.text.isNotEmpty
                  ? () => _copyMessageText(_selectedMessage!)
                  : null,
              onDelete: () => _showDeleteDialog(_selectedMessage!),
            ),
        ],
      ),
    );
  }

  void _copyMessageText(MessageNewEntity message) {
    Clipboard.setData(ClipboardData(text: message.text));
    AppSnackBar.showSuccess(context, 'Texto copiado');
  }

  PreferredSizeWidget _buildAppBar(ChatNewState chatState) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {
          if (widget.isGroup) {
            // ✅ Abrir página de edição do grupo
            _openEditGroup();
            return;
          }
          // ✅ Navegar para ViewProfile do outro usuário
          final otherProfileId = _resolvedOtherProfileId ?? widget.otherProfileId;
          if (otherProfileId.isEmpty) return;
          context.pushProfile(otherProfileId);
        },
        child: Row(
          children: [
            // Avatar (empilhado para grupos)
            if (widget.isGroup)
              _buildGroupAvatarAppBar()
            else
              _buildSingleAvatarAppBar(),

            const SizedBox(width: 12),

            // Nome e status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.isGroup) ...[
                        Icon(
                          Iconsax.people,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          widget.otherName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // ✅ Indicador de que é clicável para grupos
                      if (widget.isGroup) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Iconsax.arrow_right_3,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                      ],
                    ],
                  ),
                  if (widget.isGroup && _participantsCache.isNotEmpty)
                    Text(
                      '${_participantsCache.length + 1} participantes',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: widget.isGroup
          ? [
              // ✅ Menu de opções do grupo
              PopupMenuButton<String>(
                icon: Icon(Iconsax.more, color: AppColors.textPrimary),
                onSelected: _onGroupMenuSelected,
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Iconsax.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Editar grupo'),
                      ],
                    ),
                  ),
                ],
              ),
            ]
          : const [],
    );
  }

  /// ✅ Abre a página de edição do grupo
  void _openEditGroup() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditGroupPage(
          conversationId: widget.conversationId,
          groupName: widget.otherName,
          groupPhotoUrl: _groupPhotoUrl ?? widget.groupPhotoUrl,
        ),
      ),
    );
  }

  /// ✅ Handler do menu do grupo
  void _onGroupMenuSelected(String value) {
    if (value == 'edit') {
      _openEditGroup();
    }
  }

  /// ✅ Foto do grupo (atualizada se mudou)
  String? get _groupPhotoUrl => widget.groupPhotoUrl;

  /// ✅ Avatar único para chat 1:1
  Widget _buildSingleAvatarAppBar() {
    return SizedBox(
      width: 40,
      height: 40,
      child: (widget.otherPhotoUrl != null && widget.otherPhotoUrl!.isNotEmpty)
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: widget.otherPhotoUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                memCacheWidth: 80,
                memCacheHeight: 80,
                placeholder: (_, __) => Container(
                  color: AppColors.surfaceVariant,
                  child: Icon(
                    Iconsax.user,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceVariant,
                  child: Icon(
                    Iconsax.user,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceVariant,
              ),
              child: Icon(
                Iconsax.user,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
    );
  }

  /// ✅ Avatares empilhados para grupos (estilo Instagram/WhatsApp)
  Widget _buildGroupAvatarAppBar() {
    // Se tem foto do grupo, usa ela
    if (widget.groupPhotoUrl != null && widget.groupPhotoUrl!.isNotEmpty) {
      return SizedBox(
        width: 40,
        height: 40,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: widget.groupPhotoUrl!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            memCacheWidth: 80,
            memCacheHeight: 80,
            placeholder: (_, __) => Container(
              color: AppColors.surfaceVariant,
              child: Icon(
                Iconsax.people,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: AppColors.surfaceVariant,
              child: Icon(
                Iconsax.people,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    // Sem foto do grupo: avatares empilhados
    final participants = _participantsCache.values.take(2).toList();
    
    if (participants.isEmpty) {
      // Loading ou sem participantes: mostrar ícone de grupo
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceVariant,
        ),
        child: Center(
          child: Icon(
            Iconsax.people,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      );
    }

    if (participants.length == 1) {
      // Apenas 1 participante visível
      return _buildMiniAvatar(participants.first, 40);
    }

    // 2+ participantes: avatares empilhados
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar de trás
          Positioned(
            top: 0,
            right: 0,
            child: _buildMiniAvatar(participants[1], 26),
          ),
          // Avatar da frente
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
              child: _buildMiniAvatar(participants[0], 26),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Mini avatar para composição de grupo
  Widget _buildMiniAvatar(ParticipantData participant, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: (participant.photoUrl != null && participant.photoUrl!.isNotEmpty)
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: participant.photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: (size * 2).toInt(),
                memCacheHeight: (size * 2).toInt(),
                placeholder: (_, __) => Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceVariant,
                  ),
                  child: Center(
                    child: Text(
                      participant.name.isNotEmpty
                          ? participant.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceVariant,
                  ),
                  child: Center(
                    child: Text(
                      participant.name.isNotEmpty
                          ? participant.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceVariant,
              ),
              child: Center(
                child: Text(
                  participant.name.isNotEmpty
                      ? participant.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMessagesList(ChatNewState chatState, String currentProfileId) {
    // ✅ MOSTRAR SKELETON APENAS DURANTE CARREGAMENTO INICIAL
    if (chatState.isInitialLoading) {
      return const MessagesNewSkeleton();
    }

    // ✅ SE CARREGOU E NÃO TEM MENSAGENS, MOSTRAR ESTADO VAZIO
    if (chatState.messages.isEmpty && chatState.error == null) {
      return const EmptyChatState();
    }

    if (chatState.error != null && chatState.messages.isEmpty) {
      return ErrorNewState(
        message: chatState.error!,
        onRetry: () => ref.invalidate(
          chatNewControllerProvider(widget.conversationId),
        ),
      );
    }

    // ✅ Filtrar mensagens de perfis bloqueados (apenas em grupos)
    final messages = widget.isGroup && _blockedProfileIds.isNotEmpty
        ? chatState.messages.where((m) {
            // Sempre mostrar mensagens próprias e do sistema
            if (m.senderProfileId == currentProfileId) return true;
            if (m.isSystemMessage) return true;
            // Ocultar mensagens de perfis bloqueados
            return !_isProfileBlocked(m.senderProfileId);
          }).toList()
        : chatState.messages;

    // ✅ Verificar se ficou vazio após filtro
    if (messages.isEmpty && chatState.error == null) {
      return const EmptyChatState();
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length + (chatState.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator no topo
        if (index == messages.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final message = messages[index];
        final isMine = message.senderProfileId == currentProfileId;

        // Para agrupamento visual (avatar/nome), ignorar mensagens de sistema e mensagens ocultas
        // (ex.: a primeira mensagem "normal" após uma mensagem de sistema do mesmo remetente)
        String? nextComparableSenderProfileId;
        if (index < messages.length - 1) {
          for (var i = index + 1; i < messages.length; i++) {
          final next = messages[i];
          if (next.isSystemMessage) continue;
          if (next.isDeletedForProfile(currentProfileId)) continue;
          nextComparableSenderProfileId = next.senderProfileId;
          break;
          }
        }

        // Verificar se deve mostrar avatar
        final showAvatar =
          !isMine &&
          !message.isSystemMessage &&
          (nextComparableSenderProfileId == null ||
            nextComparableSenderProfileId != message.senderProfileId);

        // ✅ Para grupos: verificar se deve mostrar nome do remetente
        // Mostra nome quando é primeira mensagem do remetente em sequência
        final showSenderName =
          false;

        // ✅ Obter nome e foto do remetente correto
        String? senderName;
        String? senderPhotoUrl;

        if (!isMine) {
          if (widget.isGroup) {
            // Para grupos: buscar do cache de participantes
            final participant = _getParticipantData(message.senderProfileId);
            senderName = participant?.name ?? message.senderName ?? 'Usuário';
            senderPhotoUrl = participant?.photoUrl ?? message.senderPhotoUrl;
          } else {
            // Para 1:1: usar dados do widget
            senderName = widget.otherName;
            senderPhotoUrl = widget.otherPhotoUrl;
          }
        }

        return GestureDetector(
          onLongPressStart: (details) {
            _showMessageActions(message, details.globalPosition);
          },
          child: MessageNewBubble(
            message: message,
            isMine: isMine,
            currentProfileId: currentProfileId,
            isGroup: widget.isGroup,
            otherParticipantIds: widget.isGroup 
                ? _participantsCache.keys.where((id) => id != message.senderProfileId).toList()
                : [],
            showAvatar: showAvatar,
            showSenderName: showSenderName,
            senderName: senderName,
            senderPhotoUrl: senderPhotoUrl,
            onReactionTap: (emoji) async {
              final activeProfile = ref.read(activeProfileProvider);
              if (activeProfile == null) return;

              final currentReaction =
                  message.getReactionByProfile(activeProfile.profileId);

              if (currentReaction == emoji) {
                // Remover reação se clicar na mesma
                await ref
                    .read(chatNewControllerProvider(widget.conversationId)
                        .notifier)
                    .removeReaction(
                      messageId: message.id,
                      profileId: activeProfile.profileId,
                    );
              } else {
                // Adicionar ou trocar reação
                await ref
                    .read(chatNewControllerProvider(widget.conversationId)
                        .notifier)
                    .addReaction(
                      messageId: message.id,
                      profileId: activeProfile.profileId,
                      emoji: emoji,
                    );
              }
            },
            onReactorsPressed: () => _showReactors(message),
            onProfileTap: (profileId) => context.pushProfile(profileId),
            onPostTap: (postId) => context.pushPostDetail(postId),
            onReplyTap: (messageId) {
              // TODO: Scroll para mensagem original
            },
          ),
        );
      },
    );
  }

  /// ✅ Mostrar quem reagiu (long press nas reações)
  void _showReactors(MessageNewEntity message) {
    if (message.reactions.isEmpty) return;
    
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReactorsBottomSheet(
        reactions: message.reactions,
        conversationId: widget.conversationId,
      ),
    );
  }
}

/// Estado vazio para chat sem mensagens
class EmptyChatState extends StatelessWidget {
  const EmptyChatState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Comece a conversa!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Envie uma mensagem para iniciar o chat',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
