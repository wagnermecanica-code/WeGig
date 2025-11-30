import 'dart:async';

import 'package:core_ui/features/messages/domain/entities/conversation_entity.dart';
import 'package:core_ui/features/messages/domain/entities/message_entity.dart';
import 'package:wegig_app/features/messages/domain/repositories/messages_repository.dart';

/// Mock implementation of MessagesRepository for testing
class MockMessagesRepository implements MessagesRepository {
  // Test data storage
  final Map<String, ConversationEntity> _conversations = {};
  final Map<String, List<MessageEntity>> _messages = {};
  final Map<String, int> _unreadCounts = {};

  // Setup responses
  String? _sendMessageFailure;
  String? _sendImageFailure;
  String? _markAsReadFailure;
  String? _deleteConversationFailure;
  String? _getConversationsFailure;
  String? _getMessagesFailure;
  String? _getOrCreateConversationFailure;

  // Call tracking
  bool sendMessageCalled = false;
  bool sendImageMessageCalled = false;
  bool markAsReadCalled = false;
  bool markAsUnreadCalled = false;
  bool deleteConversationCalled = false;
  bool getConversationsCalled = false;
  bool getMessagesCalled = false;
  bool getOrCreateConversationCalled = false;

  String? lastSendMessageConversationId;
  String? lastSendMessageText;
  String? lastMarkAsReadConversationId;
  String? lastDeletedConversationId;

  // Setup methods
  void setupConversations(
      String profileId, List<ConversationEntity> conversations) {
    // Store all conversations for this profile
    for (final conv in conversations) {
      _conversations[conv.id] = conv;
    }
  }

  void setupConversationById(
      String conversationId, ConversationEntity? conversation) {
    if (conversation != null) {
      _conversations[conversationId] = conversation;
    }
  }

  void setupMessages(String conversationId, List<MessageEntity> messages) {
    _messages[conversationId] = messages;
  }

  void setupUnreadCount(String profileId, int count) {
    _unreadCounts[profileId] = count;
  }

  void setupSendMessageFailure(String errorMessage) {
    _sendMessageFailure = errorMessage;
  }

  void setupSendImageFailure(String errorMessage) {
    _sendImageFailure = errorMessage;
  }

  void setupMarkAsReadFailure(String errorMessage) {
    _markAsReadFailure = errorMessage;
  }

  void setupDeleteConversationFailure(String errorMessage) {
    _deleteConversationFailure = errorMessage;
  }

  void setupGetConversationsFailure(String errorMessage) {
    _getConversationsFailure = errorMessage;
  }

  void setupGetMessagesFailure(String errorMessage) {
    _getMessagesFailure = errorMessage;
  }

  void setupGetOrCreateConversationFailure(String errorMessage) {
    _getOrCreateConversationFailure = errorMessage;
  }

  @override
  Future<List<ConversationEntity>> getConversations({
    required String profileId,
    int limit = 20,
    ConversationEntity? startAfter,
  }) async {
    getConversationsCalled = true;

    if (_getConversationsFailure != null) {
      throw Exception(_getConversationsFailure);
    }

    // Return all conversations for this profile
    return _conversations.values
        .where((conv) => conv.participantProfiles.contains(profileId))
        .toList();
  }

  @override
  Future<ConversationEntity?> getConversationById(String conversationId) async {
    return _conversations[conversationId];
  }

  @override
  Future<ConversationEntity> getOrCreateConversation({
    required String currentProfileId,
    required String otherProfileId,
    required String currentUid,
    required String otherUid,
  }) async {
    getOrCreateConversationCalled = true;

    if (_getOrCreateConversationFailure != null) {
      throw Exception(_getOrCreateConversationFailure);
    }

    // Find existing conversation
    final existing =
        _conversations.values.cast<ConversationEntity?>().firstWhere(
              (conv) =>
                  conv != null &&
                  conv.participantProfiles.contains(currentProfileId) &&
                  conv.participantProfiles.contains(otherProfileId),
              orElse: () => null,
            );

    if (existing != null) {
      return existing;
    }

    // Create new conversation
    final newConv = ConversationEntity(
      id: 'conv-${DateTime.now().millisecondsSinceEpoch}',
      participants: [currentUid, otherUid],
      participantProfiles: [currentProfileId, otherProfileId],
      lastMessage: '',
      lastMessageTimestamp: DateTime.now(),
      unreadCount: {currentProfileId: 0, otherProfileId: 0},
      createdAt: DateTime.now(),
    );

    _conversations[newConv.id] = newConv;
    return newConv;
  }

  @override
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 20,
    MessageEntity? startAfter,
  }) async {
    getMessagesCalled = true;

    if (_getMessagesFailure != null) {
      throw Exception(_getMessagesFailure);
    }

    return _messages[conversationId] ?? [];
  }

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String text,
    MessageReplyEntity? replyTo,
  }) async {
    sendMessageCalled = true;
    lastSendMessageConversationId = conversationId;
    lastSendMessageText = text;

    if (_sendMessageFailure != null) {
      throw Exception(_sendMessageFailure);
    }

    final message = MessageEntity(
      messageId: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderProfileId: senderProfileId,
      text: text,
      timestamp: DateTime.now(),
      replyTo: replyTo,
    );

    if (_messages[conversationId] == null) {
      _messages[conversationId] = [];
    }
    _messages[conversationId]!.add(message);

    return message;
  }

  @override
  Future<MessageEntity> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String imageUrl,
    String text = '',
    MessageReplyEntity? replyTo,
  }) async {
    sendImageMessageCalled = true;
    lastSendMessageConversationId = conversationId;

    if (_sendImageFailure != null) {
      throw Exception(_sendImageFailure);
    }

    final message = MessageEntity(
      messageId: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderProfileId: senderProfileId,
      text: text,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      replyTo: replyTo,
    );

    if (_messages[conversationId] == null) {
      _messages[conversationId] = [];
    }
    _messages[conversationId]!.add(message);

    return message;
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String profileId,
  }) async {
    markAsReadCalled = true;
    lastMarkAsReadConversationId = conversationId;

    if (_markAsReadFailure != null) {
      throw Exception(_markAsReadFailure);
    }

    // Mark all messages as read
    if (_messages[conversationId] != null) {
      for (var i = 0; i < _messages[conversationId]!.length; i++) {
        final msg = _messages[conversationId]![i];
        if (msg.senderProfileId != profileId) {
          _messages[conversationId]![i] = MessageEntity(
            messageId: msg.messageId,
            senderId: msg.senderId,
            senderProfileId: msg.senderProfileId,
            text: msg.text,
            imageUrl: msg.imageUrl,
            timestamp: msg.timestamp,
            read: true,
            replyTo: msg.replyTo,
            reactions: msg.reactions,
          );
        }
      }
    }

    // Reset unread count
    if (_unreadCounts.containsKey(profileId)) {
      _unreadCounts[profileId] = 0;
    }
  }

  @override
  Future<void> markAsUnread({
    required String conversationId,
    required String profileId,
  }) async {
    markAsUnreadCalled = true;

    // Increment unread count
    _unreadCounts[profileId] = (_unreadCounts[profileId] ?? 0) + 1;
  }

  @override
  Future<void> deleteConversation({
    required String conversationId,
    required String profileId,
  }) async {
    deleteConversationCalled = true;
    lastDeletedConversationId = conversationId;

    if (_deleteConversationFailure != null) {
      throw Exception(_deleteConversationFailure);
    }

    _conversations.remove(conversationId);
    _messages.remove(conversationId);
  }

  @override
  Future<int> getUnreadMessageCount(String profileId) async {
    return _unreadCounts[profileId] ?? 0;
  }

  @override
  Stream<List<ConversationEntity>> watchConversations(String profileId) {
    return Stream.value(
      _conversations.values
          .where((conv) => conv.participantProfiles.contains(profileId))
          .toList(),
    );
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String conversationId) {
    return Stream.value(_messages[conversationId] ?? []);
  }

  @override
  Stream<int> watchUnreadCount(String profileId) {
    return Stream.value(_unreadCounts[profileId] ?? 0);
  }
}
