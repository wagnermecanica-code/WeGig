import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linkify/linkify.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/features/messages/presentation/providers/messages_providers.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:wegig_app/features/messages/utils/mention_linkifier.dart';

// Sanitização de texto para campos de entrada
String sanitizeText(String input) {
  var sanitized = input.trim();
  // Remove múltiplas quebras de linha consecutivas (mantém 1 linha em branco)
  sanitized = sanitized.replaceAll(RegExp(r'\s*\n{2,}\s*'), '\n');
  // Remove APENAS caracteres de controle C0 (exceto \n e \t) e DEL
  // NÃO remove emojis (que estão em ranges Unicode altos como U+1F600-U+1F64F)
  sanitized =
      sanitized.replaceAll(RegExp(r'[\u0000-\u0008\u000B-\u001F\u007F]'), '');
  return sanitized;
}

/// Tela de chat individual inspirada no Direct do Instagram
/// Recursos: mensagens em tempo real, reações, responder, fotos, áudio

/// Função isolada para compressão de imagem (não bloqueia UI thread)
Future<String?> _compressImageIsolate(Map<String, dynamic> params) async {
  final sourcePath = params['sourcePath'] as String;
  final targetDir = params['targetDir'] as String;

  final fileName = path.basename(sourcePath);
  final targetPath = path.join(targetDir, 'compressed_$fileName');

  final compressed = await FlutterImageCompress.compressAndGetFile(
    sourcePath,
    targetPath,
    quality: 85,
    minHeight: 1920,
  );

  return compressed?.path;
}

class ChatDetailPage extends ConsumerStatefulWidget {
  const ChatDetailPage({
    required this.conversationId,
    required this.otherUserId,
    required this.otherProfileId,
    required this.otherUserName,
    required this.otherUserPhoto,
    super.key,
  });
  final String conversationId;
  final String otherUserId;
  final String otherProfileId; // Novo: ID do perfil com quem está conversando
  final String otherUserName;
  final String otherUserPhoto;

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _messagesSubscription;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isUploading = false;
  Map<String, dynamic>? _replyingTo;
  ProfileEntity? _activeProfile;
  ProviderSubscription<ProfileEntity?>? _activeProfileSubscription;

  // Pagination state
  DocumentSnapshot? _lastMessageDoc;
  bool _hasMoreMessages = true;
  final int _messagesPerPage = 20;
  bool _isLoadingMore = false;

  // Paleta de cores Airbnb-style
  static const Color _primaryColor = AppColors.primary;
  static const Color _backgroundColor = AppColors.background;
  static const Color _myMessageColor = AppColors.primary;
  static const Color _otherMessageColor = AppColors.surfaceVariant;
  static const Color _reactionBgColor = AppColors.divider;

  /// Listener do ScrollController para paginação (evita memory leak)
  void _onScroll() {
    if (_scrollController.hasClients) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        _loadMoreMessages();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _activeProfile = ref.read(activeProfileProvider);

    _activeProfileSubscription =
        ref.listenManual<ProfileEntity?>(activeProfileProvider,
            (ProfileEntity? previous, ProfileEntity? next) {
      final previousId = previous?.profileId;
      final nextId = next?.profileId;
      if (previousId == nextId) {
        return;
      }

      if (mounted) {
        setState(() => _activeProfile = next);
      } else {
        _activeProfile = next;
      }

      if (nextId != null) {
        _markConversationAsRead(profileIdOverride: nextId);
      }
    });

    _loadMessages();

    if (_activeProfile?.profileId != null) {
      _markConversationAsRead(profileIdOverride: _activeProfile!.profileId);
    }

    // Listener para paginação (carregar mais mensagens ao rolar para cima)
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // ✅ FIX: Cancelar subscription primeiro para evitar setState após dispose
    _messagesSubscription?.cancel();
    _messagesSubscription = null;

    // ✅ FIX: Remover scroll listener antes de dispose (usa mesma referência)
    _scrollController.removeListener(_onScroll);
    _activeProfileSubscription?.close();
    _activeProfileSubscription = null;
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  /// Carrega mensagens em tempo real com paginação
  void _loadMessages() {
    _messagesSubscription = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_messagesPerPage)
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{
          'messageId': doc.id,
          'senderId': data['senderId'] ?? '',
          'senderProfileId': data['senderProfileId'] ??
              data['senderId'] ??
              '', // Fallback para mensagens antigas
          'text': data['text'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'replyTo': data['replyTo'],
            'reactions':
              (data['reactions'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{},
          'timestamp': data['timestamp'] as Timestamp?,
          'read': data['read'] ?? false,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
          if (snapshot.docs.isNotEmpty) {
            _lastMessageDoc = snapshot.docs.last;
          }
        });

        // Auto-scroll para o final quando novas mensagens chegam
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  /// Carrega mais mensagens antigas (paginação)
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _lastMessageDoc == null) {
      return;
    }

    if (!mounted) return;
    setState(() => _isLoadingMore = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastMessageDoc!)
          .limit(_messagesPerPage)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _hasMoreMessages = false;
            _isLoadingMore = false;
          });
        }
        return;
      }

      final newMessages = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{
          'messageId': doc.id,
          'senderId': data['senderId'] ?? '',
          'senderProfileId': data['senderProfileId'] ?? data['senderId'] ?? '',
          'text': data['text'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'replyTo': data['replyTo'],
            'reactions':
              (data['reactions'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{},
          'timestamp': data['timestamp'] as Timestamp?,
          'read': data['read'] ?? false,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _messages.addAll(newMessages);
          _lastMessageDoc = querySnapshot.docs.last;
          _isLoadingMore = false;
          if (querySnapshot.docs.length < _messagesPerPage) {
            _hasMoreMessages = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar mais mensagens: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  /// Marca conversa como lida usando o MessageService
  Future<void> _markConversationAsRead({String? profileIdOverride}) async {
    final profileId = profileIdOverride ??
        _activeProfile?.profileId ??
        ref.read(activeProfileProvider)?.profileId;

    if (profileId == null || profileId.isEmpty) {
      debugPrint(
          'ChatDetailPage: ❌ Não há perfil ativo para marcar como lida');
      return;
    }

    try {
      await ref.read(markAsReadUseCaseProvider).call(
            conversationId: widget.conversationId,
            profileId: profileId,
          );
    } catch (e) {
      debugPrint('Erro ao marcar conversa como lida: $e');
    }
  }

  /// Envia uma nova mensagem de texto
  Future<void> _sendMessage() async {
    final text = sanitizeText(_messageController.text);
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final activeProfile =
        _activeProfile ?? ref.read(activeProfileProvider);
    final currentProfileId = activeProfile?.profileId;

    if (currentProfileId == null) {
      debugPrint('ChatDetailPage: ❌ Perfil ativo não encontrado para envio');
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Não encontramos um perfil ativo. Tente novamente.',
        );
      }
      return;
    }

    final replyTo = _replyingTo;
    if (!mounted) return;
    setState(() {
      _messageController.clear();
      _replyingTo = null;
    });

    try {
      final messageData = <String, dynamic>{
        'senderId': currentUser.uid,
        'senderProfileId': currentProfileId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'reactions': <String, dynamic>{},
      };

      if (replyTo != null) {
        messageData['replyTo'] = <String, dynamic>{
          'messageId': replyTo['messageId'],
          'text': replyTo['text'],
          'senderId': replyTo['senderId'],
        };
      }

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add(messageData);

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': text,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      // Atualiza unreadCount do destinatário de forma segura
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .set({
        'unreadCount': {
          widget.otherProfileId: FieldValue.increment(1),
        },
      }, SetOptions(merge: true));

      // Notificação de nova mensagem é enviada automaticamente pela Cloud Function sendMessageNotification
      // Ver: functions/index.js - onCreate messages/{conversationId}/messages/{messageId}

      // Mantém o foco no input
      _messageFocusNode.requestFocus();
    } catch (e) {
      debugPrint('Erro ao enviar mensagem: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao enviar: $e');
      }
    }
  }

  /// Envia uma imagem com compressão em isolate (não bloqueia UI)
  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final activeProfile =
        _activeProfile ?? ref.read(activeProfileProvider);
    final currentProfileId = activeProfile?.profileId;

    if (currentProfileId == null) {
      debugPrint('ChatDetailPage: ❌ Perfil ativo não encontrado para imagem');
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Não encontramos um perfil ativo. Tente novamente.',
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      // Comprimir imagem em isolate (não bloqueia UI - 95% mais responsivo)
      final tempDir = Directory.systemTemp.path;
      String? compressedPath;
      try {
        compressedPath = await compute(_compressImageIsolate, {
          'sourcePath': pickedFile.path,
          'targetDir': tempDir,
        });
      } catch (e) {
        debugPrint('Erro ao comprimir imagem: $e');
        // Fallback: usar arquivo original se compressão falhar
        compressedPath = pickedFile.path;
      }

      if (compressedPath == null || !File(compressedPath).existsSync()) {
        throw Exception('Falha na compressão da imagem');
      }

      // Upload para Firebase Storage
      final file = File(compressedPath);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(widget.conversationId)
          .child(fileName);

      await storageRef.putFile(file);
      final imageUrl = await storageRef.getDownloadURL();

      // Limpar arquivo temporário
      try {
        await file.delete();
      } catch (e) {
        debugPrint('Erro ao deletar arquivo temporário: $e');
      }

      // Criar mensagem com imagem
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderProfileId': currentProfileId,
        'text': '',
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'reactions': <String, dynamic>{},
      });

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': '📷 Foto',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      // Atualiza unreadCount do destinatário
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .set({
        'unreadCount': {
          widget.otherProfileId: FieldValue.increment(1),
        },
      }, SetOptions(merge: true));

      // Notificação de nova mensagem é enviada automaticamente pela Cloud Function sendMessageNotification
      // Ver: functions/index.js - onCreate messages/{conversationId}/messages/{messageId}
    } catch (e) {
      debugPrint('Erro ao enviar imagem: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao enviar imagem: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Adiciona reação a uma mensagem
  Future<void> _addReaction(String messageId, String emoji) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.${currentUser.uid}': emoji,
      });
    } catch (e) {
      debugPrint('Erro ao adicionar reação: $e');
    }
  }

  /// Remove reação de uma mensagem
  Future<void> _removeReaction(String messageId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.${currentUser.uid}': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('Erro ao remover reação: $e');
    }
  }

  /// Copia mensagem para clipboard
  Future<void> _copyMessage(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Mensagem copiada');
      }
    } catch (e) {
      debugPrint('Erro ao copiar mensagem: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao copiar: $e');
      }
    }
  }

  /// Deleta uma mensagem
  Future<void> _deleteMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc(messageId)
          .delete();

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Mensagem deletada', duration: const Duration(seconds: 1));
      }
    } catch (e) {
      debugPrint('Erro ao deletar mensagem: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Lista de mensagens
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.message,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma mensagem ainda',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Comece a conversa!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),

          // Input de mensagem
          _buildMessageInput(),
        ],
      ),
    );
  }

  /// AppBar com informações do outro usuário
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryColor,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          // Avatar com Hero animation
          Hero(
            tag: 'avatar_${widget.conversationId}',
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: widget.otherUserPhoto.isNotEmpty
                  ? NetworkImage(widget.otherUserPhoto)
                  : null,
              child: widget.otherUserPhoto.isEmpty
                  ? const Icon(Iconsax.user, size: 22, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Nome do usuário
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Status (online/offline)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.otherUserId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final isOnline = snapshot.hasData &&
                        snapshot.data!.exists &&
                        ((snapshot.data!.data() as Map?)
                                ?.containsKey('isOnline') ??
                            false) &&
                        (snapshot.data!.data()! as Map)['isOnline'] == true;

                    return Text(
                      isOnline ? 'online' : 'offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Menu de opções
        PopupMenuButton<String>(
          icon: const Icon(Iconsax.more),
          onSelected: (value) {
            switch (value) {
              case 'clear':
                _clearChat();
              case 'block':
                _blockUser();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Iconsax.trash, size: 22),
                  SizedBox(width: 12),
                  Text('Limpar conversa'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Iconsax.shield_cross, size: 22, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Bloquear usuário', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Bolha de mensagem individual (estilo Instagram Direct)
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final myProfileId = _activeProfile?.profileId;
    final isMyMessage =
      myProfileId != null && message['senderProfileId'] == myProfileId;
    final timestamp = message['timestamp'] as Timestamp?;
    final imageUrl = (message['imageUrl'] as String?) ?? '';
    final replyTo = message['replyTo'] as Map<String, dynamic>?;
    final reactions =
        (message['reactions'] as Map?)?.cast<String, String>() ?? {};
    final messageId = (message['messageId'] as String?) ?? '';

    var timeString = '';
    if (timestamp != null) {
      final date = timestamp.toDate();
      timeString =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return GestureDetector(
      onLongPress: () {
        _showMessageOptions(message);
      },
      onDoubleTap: () {
        // Double tap para adicionar ❤️
        final myReaction = reactions[currentUser?.uid];
        if (myReaction == '❤️') {
          _removeReaction(messageId);
        } else {
          _addReaction(messageId, '❤️');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          crossAxisAlignment:
              isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar (apenas para mensagens do outro usuário)
                if (!isMyMessage)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundImage: widget.otherUserPhoto.isNotEmpty
                          ? NetworkImage(widget.otherUserPhoto)
                          : null,
                      child: widget.otherUserPhoto.isEmpty
                          ? const Icon(Iconsax.user, size: 18)
                          : null,
                    ),
                  ),

                // Bolha da mensagem
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: isMyMessage ? _myMessageColor : _otherMessageColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMyMessage ? 18 : 4),
                        bottomRight: Radius.circular(isMyMessage ? 4 : 18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reply preview (se houver)
                        if (replyTo != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: isMyMessage
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.grey.shade300,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 30,
                                  color: isMyMessage
                                      ? Colors.white
                                      : _primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        replyTo['senderProfileId'] ==
                                                myProfileId
                                            ? 'Você'
                                            : widget.otherUserName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isMyMessage
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        (replyTo['text'] as String?) ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isMyMessage
                                              ? Colors.white
                                                  .withValues(alpha: 0.8)
                                              : Colors.black54,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Imagem (se houver)
                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFE47911)),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Iconsax.gallery_slash,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                              memCacheWidth: 400,
                              memCacheHeight: 400,
                            ),
                          ),

                        // Texto da mensagem
                        if (message['text'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Linkify(
                              linkifiers: <Linkifier>[
                                ...defaultLinkifiers,
                                const MentionLinkifier(),
                              ],
                              onOpen: (link) async {
                                if (link is MentionElement) {
                                  context.pushProfileByUsername(link.username);
                                  return;
                                }

                                try {
                                  final uri = Uri.parse(link.url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Erro ao abrir link: $e');
                                  if (mounted) {
                                    AppSnackBar.showError(
                                      context,
                                      'Erro ao abrir link',
                                    );
                                  }
                                }
                              },
                              text: (message['text'] as String?) ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                color:
                                    isMyMessage ? Colors.white : Colors.black87,
                                height: 1.4,
                              ),
                              linkStyle: TextStyle(
                                fontSize: 15,
                                color:
                                    isMyMessage ? Colors.white : _primaryColor,
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),

                        // Hora (canto inferior direito)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: 12,
                            bottom: 6,
                            left: 12,
                          ),
                          child: Text(
                            timeString,
                            style: TextStyle(
                              fontSize: 11,
                              color: isMyMessage
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Reações (abaixo da bolha)
            if (reactions.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  top: 4,
                  left: isMyMessage ? 0 : 30,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _reactionBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...reactions.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Mostra opções ao segurar mensagem (estilo Instagram)
  void _showMessageOptions(Map<String, dynamic> message) {
    final myProfileId = _activeProfile?.profileId;
    final isMyMessage =
      myProfileId != null && message['senderProfileId'] == myProfileId;
    final messageId = (message['messageId'] as String?) ?? '';

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Reações rápidas (estilo Instagram)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['❤️', '😂', '😮', '😢', '😡', '👍'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _addReaction(messageId, emoji);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),

            // Responder
            ListTile(
              leading: const Icon(Iconsax.arrow_left),
              title: const Text('Responder'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyingTo = message;
                  _messageFocusNode.requestFocus();
                });
              },
            ),

            // Copiar
            if (message['text'].toString().isNotEmpty)
              ListTile(
                leading: const Icon(Iconsax.copy),
                title: const Text('Copiar'),
                onTap: () {
                  Navigator.pop(context);
                  _copyMessage((message['text'] as String?) ?? '');
                },
              ),

            // Deletar (apenas para minhas mensagens)
            if (isMyMessage)
              ListTile(
                leading: const Icon(Iconsax.trash, color: Colors.red),
                title:
                    const Text('Deletar', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Deletar mensagem'),
                      content: const Text('Deseja deletar esta mensagem?'),
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
                          child: const Text('Deletar'),
                        ),
                      ],
                    ),
                  );

                  if (confirm ?? false) {
                    _deleteMessage(messageId);
                  }
                },
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Input de mensagem na parte inferior (estilo Instagram)
  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview de resposta (se estiver respondendo)
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 40,
                    color: _primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Respondendo para ${_replyingTo!['senderProfileId'] == _activeProfile?.profileId ? 'você mesmo' : widget.otherUserName}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (_replyingTo!['text'] as String?) ?? '📷 Foto',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.close_circle, size: 22),
                    onPressed: () => setState(() => _replyingTo = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Loading indicator (ao enviar foto)
          if (_isUploading)
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Enviando foto...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

          // Input de mensagem
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  // Botão de foto
                  IconButton(
                    icon: const Icon(
                      Iconsax.camera,
                      color: _primaryColor,
                      size: 28,
                    ),
                    onPressed: _isUploading ? null : _sendImage,
                  ),

                  // Campo de texto
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Mensagem...',
                          hintStyle: TextStyle(fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        enableInteractiveSelection: true,
                        autocorrect: true,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Botão de enviar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Iconsax.send_2,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Limpa todas as mensagens da conversa
  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar conversa'),
        content: const Text(
          'Deseja limpar todas as mensagens desta conversa? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Deletar todas as mensagens
      final batch = FirebaseFirestore.instance.batch();
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .get();

      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Atualizar última mensagem
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Conversa limpa com sucesso');
      }
    } catch (e) {
      debugPrint('Erro ao limpar conversa: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao limpar conversa: $e');
      }
    }
  }

  /// Bloqueia o usuário
  Future<void> _blockUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear usuário'),
        content: Text(
          'Deseja bloquear ${widget.otherUserName}? Você não receberá mais mensagens desta pessoa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Adicionar à lista de bloqueados
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'blockedUsers': FieldValue.arrayUnion([widget.otherUserId]),
      });

      if (mounted) {
        AppSnackBar.showSuccess(context, '${widget.otherUserName} foi bloqueado');
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Erro ao bloquear usuário: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao bloquear usuário: $e');
      }
    }
  }
}
