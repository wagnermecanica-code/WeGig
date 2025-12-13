import 'dart:async';

import 'package:core_ui/features/messages/domain/entities/message_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/features/messages/presentation/providers/messages_providers.dart';

part 'chat_controller.g.dart';

@riverpod
class ChatController extends _$ChatController {
  StreamSubscription<List<MessageEntity>>? _subscription;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  FutureOr<List<MessageEntity>> build(String conversationId) async {
    // Load initial history
    final loadMessages = ref.read(loadMessagesUseCaseProvider);
    final initialMessages = await loadMessages(conversationId: conversationId);
    
    if (initialMessages.length < 20) {
      _hasMore = false;
    }

    // Setup real-time listener
    _setupRealtimeListener();

    // Dispose subscription when provider is destroyed
    ref.onDispose(() {
      _subscription?.cancel();
    });

    return initialMessages;
  }

  void _setupRealtimeListener() {
    final watchMessages = ref.read(watchMessagesUseCaseProvider);
    _subscription = watchMessages(conversationId).listen((newMessages) {
      // If state is not available yet, we don't merge
      if (state.value == null) return;
      
      state = AsyncValue.data(_mergeMessages(state.value!, newMessages));
    });
  }

  List<MessageEntity> _mergeMessages(List<MessageEntity> current, List<MessageEntity> incoming) {
    // Merge logic:
    // 1. Create a map of existing messages by ID
    final Map<String, MessageEntity> messageMap = {
      for (var m in current) m.messageId: m
    };

    // 2. Update/Add incoming messages
    for (var m in incoming) {
      messageMap[m.messageId] = m;
    }

    // 3. Convert back to list and sort
    final merged = messageMap.values.toList();
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Descending

    return merged;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state.value == null) return;

    _isLoadingMore = true;
    final currentMessages = state.value!;
    final lastMessage = currentMessages.last;

    try {
      final loadMessages = ref.read(loadMessagesUseCaseProvider);
      final olderMessages = await loadMessages(
        conversationId: conversationId,
        startAfter: lastMessage,
      );

      if (olderMessages.length < 20) {
        _hasMore = false;
      }

      if (olderMessages.isNotEmpty) {
        state = AsyncValue.data([...currentMessages, ...olderMessages]);
      }
    } catch (e, st) {
      // We don't want to replace the state with error, just maybe show a snackbar or log
      // But here we are inside a controller, so we can't show snackbar easily.
      // We could set a separate error state if needed, but for now let's just log.
      print('Error loading more messages: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> sendMessage(String text, String senderId, String senderProfileId, {MessageReplyEntity? replyTo}) async {
    final sendMessage = ref.read(sendMessageUseCaseProvider);
    // Optimistic update could be added here
    await sendMessage(
      conversationId: conversationId,
      text: text,
      senderId: senderId,
      senderProfileId: senderProfileId,
      replyTo: replyTo,
    );
  }

  Future<void> sendImageMessage(String imageUrl, String senderId, String senderProfileId, {String text = '', MessageReplyEntity? replyTo}) async {
    final sendImage = ref.read(sendImageUseCaseProvider);
    await sendImage(
      conversationId: conversationId,
      imageUrl: imageUrl,
      senderId: senderId,
      senderProfileId: senderProfileId,
      text: text,
      replyTo: replyTo,
    );
  }

  Future<void> addReaction(String messageId, String userId, String reaction) async {
    final addReaction = ref.read(addReactionUseCaseProvider);
    await addReaction(
      conversationId: conversationId,
      messageId: messageId,
      userId: userId,
      reaction: reaction,
    );
  }

  Future<void> removeReaction(String messageId, String userId) async {
    final removeReaction = ref.read(removeReactionUseCaseProvider);
    await removeReaction(
      conversationId: conversationId,
      messageId: messageId,
      userId: userId,
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final deleteMessage = ref.read(deleteMessageUseCaseProvider);
    await deleteMessage(
      conversationId: conversationId,
      messageId: messageId,
    );
    
    // Optimistically remove from state
    if (state.value != null) {
      final current = state.value!;
      state = AsyncValue.data(current.where((m) => m.messageId != messageId).toList());
    }
  }
}
