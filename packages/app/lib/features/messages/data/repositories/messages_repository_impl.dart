import 'package:core_ui/features/messages/domain/entities/conversation_entity.dart';
import 'package:core_ui/features/messages/domain/entities/message_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:wegig_app/features/messages/data/datasources/messages_remote_datasource.dart';
import 'package:wegig_app/features/messages/domain/repositories/messages_repository.dart';

/// Implementação do MessagesRepository
class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl({required IMessagesRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;
  final IMessagesRemoteDataSource _remoteDataSource;

  @override
  Future<List<ConversationEntity>> getConversations({
    required String profileId,
    int limit = 20,
    ConversationEntity? startAfter,
    String? profileUid,
  }) async {
    try {
      debugPrint('📝 MessagesRepository: getConversations');
      return await _remoteDataSource.getConversations(
        profileId: profileId,
        limit: limit,
        startAfter: startAfter,
        profileUid: profileUid,
      );
    } catch (e) {
      debugPrint('❌ MessagesRepository: Erro em getConversations - $e');
      rethrow;
    }
  }

  @override
  Future<ConversationEntity?> getConversationById(String conversationId) async {
    try {
      return await _remoteDataSource.getConversationById(conversationId);
    } catch (e) {
      debugPrint('❌ MessagesRepository: Erro em getConversationById - $e');
      rethrow;
    }
  }

  @override
  Future<ConversationEntity> getOrCreateConversation({
    required String currentProfileId,
    required String otherProfileId,
    required String currentUid,
    required String otherUid,
  }) async {
    try {
      debugPrint('📝 MessagesRepository: getOrCreateConversation');
      return await _remoteDataSource.getOrCreateConversation(
        currentProfileId: currentProfileId,
        otherProfileId: otherProfileId,
        currentUid: currentUid,
        otherUid: otherUid,
      );
    } catch (e) {
      debugPrint('❌ MessagesRepository: Erro em getOrCreateConversation - $e');
      rethrow;
    }
  }

  @override
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 20,
    MessageEntity? startAfter,
  }) async {
    try {
      debugPrint('📝 MessagesRepository: getMessages');
      return await _remoteDataSource.getMessages(
        conversationId: conversationId,
        limit: limit,
        startAfter: startAfter,
      );
    } catch (e) {
      debugPrint('❌ MessagesRepository: Erro em getMessages - $e');
      rethrow;
    }
  }

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String text,
    MessageReplyEntity? replyTo,
  }) async {
    try {
      debugPrint('📝 MessagesRepository: sendMessage');

      // Validação
      final error = MessageEntity.validate(text, null);
      if (error != null) throw Exception(error);

      return await _remoteDataSource.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        senderProfileId: senderProfileId,
        text: text,
        replyTo: replyTo,
      );
    } catch (e) {
      debugPrint('❌ MessagesRepository: Erro em sendMessage - $e');
      rethrow;
    }
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
    try {
      debugPrint('📝 MessagesRepository: sendImageMessage');
      return await _remoteDataSource.sendImageMessage(
        conversationId: conversationId,
        senderId: senderId,
        senderProfileId: senderProfileId,
        imageUrl: imageUrl,
        text: text,
        replyTo: replyTo,
      );
    } catch (e) {
      debugPrint('❌ MessagesRepository: Erro em sendImageMessage - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String profileId,
  }) async {
    try {
      debugPrint('📝 MessagesRepository: markAsRead');
      await _remoteDataSource.markAsRead(conversationId, profileId);
    } catch (e) {
      debugPrint('❌ MessagesRepository: Erro em markAsRead - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsUnread({
    required String conversationId,
    required String profileId,
  }) async {
    try {
      debugPrint('📝 MessagesRepository: markAsUnread');
      await _remoteDataSource.markAsUnread(conversationId, profileId);
    } catch (e) {
      debugPrint('❌ MessagesRepository: Erro em markAsUnread - $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteConversation({
    required String conversationId,
    required String profileId,
  }) async {
    try {
      debugPrint('📝 MessagesRepository: deleteConversation');
      await _remoteDataSource.deleteConversation(conversationId, profileId);
    } catch (e) {
      debugPrint('❌ MessagesRepository: Erro em deleteConversation - $e');
      rethrow;
    }
  }

  @override
  Future<int> getUnreadMessageCount(String profileId,
      {String? profileUid}) async {
    try {
      return await _remoteDataSource.getUnreadMessageCount(
        profileId,
        profileUid: profileUid,
      );
    } catch (e) {
      debugPrint('❌ MessagesRepository: Erro em getUnreadMessageCount - $e');
      return 0;
    }
  }

  @override
  Stream<List<ConversationEntity>> watchConversations(String profileId,
      {String? profileUid}) {
    return _remoteDataSource.watchConversations(
      profileId,
      profileUid: profileUid,
    );
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String conversationId) {
    return _remoteDataSource.watchMessages(conversationId);
  }

  @override
  Stream<int> watchUnreadCount(String profileId, {String? profileUid}) {
    return _remoteDataSource.watchUnreadCount(
      profileId,
      profileUid: profileUid,
    );
  }
}
