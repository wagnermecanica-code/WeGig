import 'dart:async';

import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/utils/debouncer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/entities.dart';
import 'mensagens_new_providers.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

part 'chat_new_controller.freezed.dart';
part 'chat_new_controller.g.dart';

/// Estado do Chat
@freezed
class ChatNewState with _$ChatNewState {
  const factory ChatNewState({
    /// Lista de mensagens carregadas
    @Default([]) List<MessageNewEntity> messages,

    /// Se está carregando mais mensagens
    @Default(false) bool isLoadingMore,

    /// Se há mais mensagens para carregar
    @Default(true) bool hasMore,

    /// Se está carregando inicialmente (antes da primeira emissão do stream)
    @Default(true) bool isInitialLoading,

    /// Mensagem sendo respondida (reply)
    MessageNewEntity? replyingTo,

    /// Mensagem sendo editada
    MessageNewEntity? editingMessage,

    /// Se o outro participante está digitando
    @Default(false) bool isOtherTyping,

    /// ProfileId de quem está digitando
    String? typingProfileId,

    /// Erro, se houver
    String? error,

    /// Se está enviando mensagem
    @Default(false) bool isSending,
  }) = _ChatNewState;
}

/// Controller para o Chat individual
///
/// Gerencia:
/// - Stream de mensagens em tempo real
/// - Envio de mensagens (texto e imagem)
/// - Reações e edições
/// - Indicador de digitação
/// - Paginação (load more)
/// - Filtro de histórico (clearHistoryTimestamp)
@riverpod
class ChatNewController extends _$ChatNewController {
  StreamSubscription<List<MessageNewEntity>>? _messagesSubscription;
  StreamSubscription<Map<String, DateTime>>? _typingSubscription;
  final Debouncer _typingDebouncer = Debouncer(milliseconds: 2000);
  Timer? _typingTimer;
  bool _isTyping = false;
  String? _currentProfileId;
  int _initVersion = 0;
  bool _isGroup = false;
  
  /// Timestamp para filtrar histórico de mensagens
  /// Se o usuário deletou a conversa anteriormente, não mostra mensagens antigas
  DateTime? _clearHistoryAfter;

  @override
  ChatNewState build(String conversationId) {
    // Cleanup ao dispose
    ref.onDispose(() {
      _messagesSubscription?.cancel();
      _typingSubscription?.cancel();
      _typingDebouncer.dispose();
      _typingTimer?.cancel();
    });

    // Reagir a troca de perfil: re-inicializa streams e filtros de histórico.
    ref.listen<ProfileEntity?>(activeProfileProvider, (previous, next) {
      final nextProfileId = next?.profileId;
      if (nextProfileId == _currentProfileId) return;

      debugPrint(
          '🔄 ChatNewController: Perfil ativo mudou (${_currentProfileId ?? "null"} -> ${nextProfileId ?? "null"}), reinicializando chat');
      _currentProfileId = nextProfileId;
      _restartForProfileChange();
    });

    // Setup inicial
    _currentProfileId = ref.read(activeProfileProvider)?.profileId;

    // Iniciar carregamento com busca de clearHistoryTimestamp
    _initializeChat();

    return const ChatNewState();
  }

  /// Inicializa o chat buscando o clearHistoryTimestamp antes de iniciar streams
  Future<void> _initializeChat() async {
    final localVersion = ++_initVersion;
    try {
      // Obter profileId do perfil ativo
      final activeProfile = ref.read(activeProfileProvider);
      final currentProfileId = activeProfile?.profileId;
      
      if (currentProfileId == null) {
        debugPrint('⚠️ ChatNewController: Perfil ativo não encontrado');
        if (localVersion == _initVersion) {
          _startMessagesStream();
          _startTypingStream();
        }
        return;
      }

      // Buscar conversa para obter clearHistoryTimestamp do perfil atual
      final repository = ref.read(mensagensNewRepositoryProvider);
      final conversation = await repository.getConversationById(conversationId);

      if (localVersion != _initVersion) return;
      
      if (conversation != null) {
        final participantProfiles = conversation.participantProfiles;
        if (!participantProfiles.contains(currentProfileId)) {
          debugPrint(
            '🚫 ChatNewController: Perfil $currentProfileId não pertence à '
            'conversa $conversationId',
          );
          if (localVersion == _initVersion) {
            state = state.copyWith(
              isInitialLoading: false,
              hasMore: false,
              error:
                  'Esta conversa não pertence ao perfil ativo. Troque de perfil para acessar.',
            );
          }
          return;
        }

        // Obter clearHistoryTimestamp específico do perfil atual
        _clearHistoryAfter = conversation.getClearHistoryTimestampForProfile(currentProfileId);
        _isGroup = conversation.isGroup || conversation.participantProfiles.length > 2;
        
        if (_clearHistoryAfter != null) {
          debugPrint('📅 ChatNewController: clearHistoryAfter para $currentProfileId = $_clearHistoryAfter');
        }
      }
    } catch (e) {
      debugPrint('⚠️ ChatNewController: Erro ao buscar conversa - $e');
    }

    // Iniciar streams (mesmo se falhar buscar conversa)
    if (localVersion == _initVersion) {
      _startMessagesStream();
      _startTypingStream();
    }
  }

  void _restartForProfileChange() {
    // Cancela streams anteriores para evitar vazamento entre perfis.
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _messagesSubscription = null;
    _typingSubscription = null;

    // Limpa estado e reinicializa.
    state = const ChatNewState();
    _clearHistoryAfter = null;
    _initializeChat();
  }

  /// Inicia stream de mensagens (com filtro de clearHistoryAfter e deletedForProfiles)
  void _startMessagesStream() {
    final useCase = ref.read(watchMessagesNewUseCaseProvider);
    final messagesStream = useCase(
      conversationId: conversationId,
      clearHistoryAfter: _clearHistoryAfter,
    );

    _messagesSubscription = messagesStream.listen(
      (messages) {
        debugPrint('📥 ChatNewController: Stream emitiu ${messages.length} mensagens');
        
        // Log dos status das primeiras 3 mensagens para debug
        for (var i = 0; i < messages.length && i < 3; i++) {
          final msg = messages[i];
          debugPrint('   📨 msg[${msg.id.substring(0, 8)}...] status=${msg.status}');
        }
        
        // Obter profileId atual para filtrar mensagens deletadas (pode mudar após troca de perfil)
        final currentProfileId = ref.read(activeProfileProvider)?.profileId;

        // Filtrar mensagens que foram deletadas para o perfil atual
        final filteredMessages = currentProfileId != null
            ? messages
                .where((msg) => !msg.deletedForProfiles.contains(currentProfileId))
                .toList()
            : messages;

        state = state.copyWith(
          messages: filteredMessages,
          isInitialLoading: false, // ✅ PRIMEIRA EMISSÃO: Não está mais carregando inicialmente
          error: null,
        );

        // ✅ Marcar como lidas mensagens novas recebidas enquanto o chat está aberto (apenas 1:1)
        if (!_isGroup && currentProfileId != null) {
          final hasUnreadIncoming = filteredMessages.any(
            (msg) =>
                msg.senderProfileId != currentProfileId &&
                msg.status != MessageDeliveryStatus.read,
          );

          if (hasUnreadIncoming) {
            unawaited(
              ref.read(markAsReadNewUseCaseProvider).call(
                    conversationId: conversationId,
                    profileId: currentProfileId,
                  )
                  .catchError((e, _) => debugPrint('⚠️ ChatNewController: markAsRead dentro do stream falhou - $e')),
            );
          }
        }
      },
      onError: (error) {
        debugPrint('❌ ChatNewController: Erro no stream - $error');
        state = state.copyWith(
          error: error.toString(),
          isInitialLoading: false, // ✅ Mesmo em erro, não está carregando inicialmente
        );
      },
    );
  }

  /// Inicia stream de typing indicators
  void _startTypingStream() {
    final useCase = ref.read(watchTypingIndicatorsNewUseCaseProvider);
    final typingStream = useCase(conversationId: conversationId);

    _typingSubscription = typingStream.listen(
      (indicators) {
        // Obter profileId atual para filtrar (pode mudar após troca de perfil)
        final currentProfileId = ref.read(activeProfileProvider)?.profileId;

        // Verificar se alguém está digitando (exceto o próprio usuário)
        final now = DateTime.now();
        String? typingProfile;
        var isTyping = false;

        for (final entry in indicators.entries) {
          // ✅ FILTRAR: Ignorar se é o próprio usuário digitando
          if (entry.key == currentProfileId) continue;

          // Typing válido por 5 segundos
          if (now.difference(entry.value).inSeconds < 5) {
            typingProfile = entry.key;
            isTyping = true;
            break;
          }
        }

        state = state.copyWith(
          isOtherTyping: isTyping,
          typingProfileId: typingProfile,
        );
      },
    );
  }

  /// Envia uma mensagem de texto
  Future<void> sendMessage({
    required String senderId,
    required String senderProfileId,
    required String text,
    String? senderName,
    String? senderPhotoUrl,
  }) async {
    if (text.trim().isEmpty) return;

    // Verificar se é uma resposta
    MessageReplyData? replyTo;
    if (state.replyingTo != null) {
      final reply = state.replyingTo!;
      replyTo = MessageReplyData(
        messageId: reply.id,
        text: reply.preview,
        senderProfileId: reply.senderProfileId,
        senderName: reply.senderName,
        imageUrl: reply.imageUrl,
      );
    }

    // 🚀 OPTIMISTIC UPDATE: Adiciona mensagem na UI imediatamente
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = MessageNewEntity(
      id: tempId,
      conversationId: conversationId,
      senderId: senderId,
      senderProfileId: senderProfileId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      text: MessageNewEntity.sanitize(text),
      type: MessageType.text,
      status: MessageDeliveryStatus.sending,
      createdAt: DateTime.now(),
      replyTo: replyTo,
    );

    // Adiciona a mensagem otimista no início da lista (lista é ordenada DESC)
    state = state.copyWith(
      isSending: true,
      error: null,
      messages: [optimisticMessage, ...state.messages],
      replyingTo: null,
    );

    try {
      final useCase = ref.read(sendMessageNewUseCaseProvider);

      await useCase(
        conversationId: conversationId,
        senderId: senderId,
        senderProfileId: senderProfileId,
        text: text,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        replyTo: replyTo,
      );

      // Limpar isSending - a mensagem real virá pelo stream
      state = state.copyWith(
        isSending: false,
      );

      // Parar typing
      await _stopTyping(senderProfileId);
    } catch (e) {
      debugPrint('❌ ChatNewController: Erro ao enviar - $e');
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
    }
  }

  /// Envia uma mensagem com imagem
  Future<void> sendImageMessage({
    required String senderId,
    required String senderProfileId,
    required String imageUrl,
    String text = '',
    String? senderName,
    String? senderPhotoUrl,
  }) async {
    state = state.copyWith(isSending: true, error: null);

    try {
      final useCase = ref.read(sendImageMessageNewUseCaseProvider);

      MessageReplyData? replyTo;
      if (state.replyingTo != null) {
        final reply = state.replyingTo!;
        replyTo = MessageReplyData(
          messageId: reply.id,
          text: reply.preview,
          senderProfileId: reply.senderProfileId,
          senderName: reply.senderName,
          imageUrl: reply.imageUrl,
        );
      }

      await useCase(
        conversationId: conversationId,
        senderId: senderId,
        senderProfileId: senderProfileId,
        imageUrl: imageUrl,
        text: text,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        replyTo: replyTo,
      );

      state = state.copyWith(
        isSending: false,
        replyingTo: null,
      );
    } catch (e) {
      debugPrint('❌ ChatNewController: Erro ao enviar imagem - $e');
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
    }
  }

  /// Edita uma mensagem
  Future<void> editMessage({
    required String messageId,
    required String newText,
  }) async {
    if (newText.trim().isEmpty) return;

    try {
      final useCase = ref.read(editMessageNewUseCaseProvider);
      await useCase(
        conversationId: conversationId,
        messageId: messageId,
        newText: newText,
      );

      // Limpar estado de edição
      state = state.copyWith(editingMessage: null);
    } catch (e) {
      debugPrint('❌ ChatNewController: Erro ao editar - $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Deleta mensagem para mim
  Future<void> deleteMessageForMe({
    required String messageId,
    required String profileId,
  }) async {
    try {
      final useCase = ref.read(deleteMessageForMeNewUseCaseProvider);
      await useCase(
        conversationId: conversationId,
        messageId: messageId,
        profileId: profileId,
      );
    } catch (e) {
      debugPrint('❌ ChatNewController: Erro ao deletar para mim - $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Deleta mensagem para todos
  Future<void> deleteMessageForEveryone({
    required String messageId,
  }) async {
    try {
      final useCase = ref.read(deleteMessageForEveryoneNewUseCaseProvider);
      await useCase(
        conversationId: conversationId,
        messageId: messageId,
      );
    } catch (e) {
      debugPrint('❌ ChatNewController: Erro ao deletar para todos - $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Adiciona reação a uma mensagem
  Future<void> addReaction({
    required String messageId,
    required String profileId,
    required String emoji,
  }) async {
    try {
      final useCase = ref.read(addReactionNewUseCaseProvider);
      await useCase(
        conversationId: conversationId,
        messageId: messageId,
        profileId: profileId,
        emoji: emoji,
      );
    } catch (e) {
      debugPrint('❌ ChatNewController: Erro ao adicionar reação - $e');
    }
  }

  /// Remove reação de uma mensagem
  Future<void> removeReaction({
    required String messageId,
    required String profileId,
  }) async {
    try {
      final useCase = ref.read(removeReactionNewUseCaseProvider);
      await useCase(
        conversationId: conversationId,
        messageId: messageId,
        profileId: profileId,
      );
    } catch (e) {
      debugPrint('❌ ChatNewController: Erro ao remover reação - $e');
    }
  }

  /// Define mensagem para responder
  void setReplyingTo(MessageNewEntity? message) {
    state = state.copyWith(replyingTo: message);
  }

  /// Define mensagem para editar
  void setEditingMessage(MessageNewEntity? message) {
    state = state.copyWith(editingMessage: message);
  }

  /// Cancela reply ou edição
  void cancelReplyOrEdit() {
    state = state.copyWith(
      replyingTo: null,
      editingMessage: null,
    );
  }

  /// Atualiza indicador de digitação
  void onTyping(String profileId) {
    if (!_isTyping) {
      _isTyping = true;
      _sendTypingIndicator(profileId, true);
    }

    // Reset timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _stopTyping(profileId);
    });
  }

  Future<void> _sendTypingIndicator(String profileId, bool isTyping) async {
    try {
      final useCase = ref.read(updateTypingIndicatorNewUseCaseProvider);
      await useCase(
        conversationId: conversationId,
        profileId: profileId,
        isTyping: isTyping,
      );
    } catch (e) {
      // Ignorar erros de typing
    }
  }

  Future<void> _stopTyping(String profileId) async {
    _isTyping = false;
    _typingTimer?.cancel();
    await _sendTypingIndicator(profileId, false);
  }

  /// Carrega mais mensagens (paginação)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final useCase = ref.read(loadMessagesNewUseCaseProvider);
      final lastMessage = state.messages.isNotEmpty ? state.messages.last : null;

      final moreMessages = await useCase(
        conversationId: conversationId,
        limit: 50,
        startAfter: lastMessage,
        clearHistoryAfter: _clearHistoryAfter,
      );

      state = state.copyWith(
        messages: [...state.messages, ...moreMessages],
        isLoadingMore: false,
        hasMore: moreMessages.length >= 50,
      );
    } catch (e) {
      debugPrint('❌ ChatNewController: Erro ao carregar mais - $e');
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Limpa erro
  void clearError() {
    state = state.copyWith(error: null);
  }
}
