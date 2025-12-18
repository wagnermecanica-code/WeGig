import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
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

import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/entities.dart';
import '../providers/chat_new_controller.dart';
import '../providers/mensagens_new_providers.dart';
import '../widgets/widgets.dart';
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

  @override
  ConsumerState<ChatNewPage> createState() => _ChatNewPageState();
}

class _ChatNewPageState extends ConsumerState<ChatNewPage> {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isUploading = false;

  // Mensagem selecionada para ações
  MessageNewEntity? _selectedMessage;
  Offset? _selectedMessagePosition;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Marcar como lida ao abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }

  @override
  void dispose() {
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

    ref.read(markAsReadNewUseCaseProvider).call(
      conversationId: widget.conversationId,
      profileId: activeProfile.profileId,
    );
  }

  Future<void> _sendMessage(String text) async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    final chatNotifier =
        ref.read(chatNewControllerProvider(widget.conversationId).notifier);

    // Se estiver editando, atualiza a mensagem
    final editing = chatNotifier.state.editingMessage;
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
                      'Digitando...',
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
          // ✅ Navegar para ViewProfile do outro usuário
          context.pushProfile(widget.otherProfileId);
        },
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceVariant,
              ),
              child: widget.otherPhotoUrl != null &&
                      widget.otherPhotoUrl!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: widget.otherPhotoUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        widget.otherName.isNotEmpty
                            ? widget.otherName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            // Nome e status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (chatState.isOtherTyping)
                    Text(
                      'digitando...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: const [],
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

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chatState.messages.length + (chatState.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator no topo
        if (index == chatState.messages.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final message = chatState.messages[index];
        final isMine = message.senderProfileId == currentProfileId;

        // Verificar se deve mostrar avatar
        final showAvatar = !isMine &&
            (index == chatState.messages.length - 1 ||
                chatState.messages[index + 1].senderProfileId !=
                    message.senderProfileId);

        return GestureDetector(
          onLongPressStart: (details) {
            _showMessageActions(message, details.globalPosition);
          },
          child: MessageNewBubble(
            message: message,
            isMine: isMine,
            currentProfileId: currentProfileId,
            showAvatar: showAvatar,
            senderName: isMine ? null : widget.otherName,
            senderPhotoUrl: isMine ? null : widget.otherPhotoUrl,
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
    
    showModalBottomSheet(
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
