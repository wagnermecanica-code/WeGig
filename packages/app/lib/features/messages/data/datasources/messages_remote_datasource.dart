import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/messages/domain/entities/conversation_entity.dart';
import 'package:core_ui/features/messages/domain/entities/message_entity.dart';
import 'package:flutter/foundation.dart';

/// Interface para MessagesRemoteDataSource
abstract class IMessagesRemoteDataSource {
  Future<List<ConversationEntity>> getConversations({
    required String profileId,
    int limit = 20,
    ConversationEntity? startAfter,
  });
  Future<ConversationEntity?> getConversationById(String conversationId);
  Future<ConversationEntity> getOrCreateConversation({
    required String currentProfileId,
    required String otherProfileId,
    required String currentUid,
    required String otherUid,
  });
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 20,
    MessageEntity? startAfter,
  });
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String text,
    MessageReplyEntity? replyTo,
  });
  Future<MessageEntity> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String imageUrl,
    String text = '',
    MessageReplyEntity? replyTo,
  });
  Future<void> markAsRead(String conversationId, String profileId);
  Future<void> markAsUnread(String conversationId, String profileId);
  Future<void> deleteConversation(String conversationId, String profileId);
  Future<int> getUnreadMessageCount(String profileId);
  Stream<List<ConversationEntity>> watchConversations(String profileId);
  Stream<List<MessageEntity>> watchMessages(String conversationId);
  Stream<int> watchUnreadCount(String profileId);
}

/// DataSource para Messages - Firebase Firestore operations
class MessagesRemoteDataSource implements IMessagesRemoteDataSource {
  MessagesRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Future<List<ConversationEntity>> getConversations({
    required String profileId,
    int limit = 20,
    ConversationEntity? startAfter,
  }) async {
    try {
      debugPrint(
          '🔍 MessagesDataSource: getConversations - profileId=$profileId');

      var query = _firestore
          .collection('conversations')
          .where('participantProfiles', arrayContains: profileId)
          .limit(limit);

      if (startAfter != null) {
        query = query
            .startAfter([startAfter.id]);
      }

      final snapshot = await query.get();
        final conversations = snapshot.docs
          .map(ConversationEntity.fromFirestore)
          .where(
          (conversation) =>
            !conversation.archivedProfileIds.contains(profileId),
          )
          .toList();

      debugPrint(
          '✅ MessagesDataSource: ${conversations.length} conversas carregadas');
      return conversations;
    } catch (e) {
      debugPrint('❌ MessagesDataSource: Erro em getConversations - $e');
      rethrow;
    }
  }

  @override
  Future<ConversationEntity?> getConversationById(String conversationId) async {
    try {
      final doc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();
      if (!doc.exists) return null;
      return ConversationEntity.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ MessagesDataSource: Erro em getConversationById - $e');
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
      debugPrint('🔍 MessagesDataSource: getOrCreateConversation');

      // Busca conversa existente
      final snapshot = await _firestore.collection('conversations').where(
          'participantProfiles',
          arrayContainsAny: [currentProfileId, otherProfileId]).get();

      for (final doc in snapshot.docs) {
        final conv = ConversationEntity.fromFirestore(doc);
        if (conv.participantProfiles.contains(currentProfileId) &&
            conv.participantProfiles.contains(otherProfileId)) {
          debugPrint('✅ MessagesDataSource: Conversa existente encontrada');
          return conv;
        }
      }

      // Cria nova conversa
      debugPrint('📝 MessagesDataSource: Criando nova conversa');
      final newConvRef = _firestore.collection('conversations').doc();
      final newConv = ConversationEntity(
        id: newConvRef.id,
        participants: [currentUid, otherUid],
        participantProfiles: [currentProfileId, otherProfileId],
        lastMessage: '',
        lastMessageTimestamp: DateTime.now(),
        unreadCount: {currentProfileId: 0, otherProfileId: 0},
        createdAt: DateTime.now(),
      );

      await newConvRef.set(newConv.toFirestore());
      debugPrint('✅ MessagesDataSource: Nova conversa criada');
      return newConv;
    } catch (e) {
      debugPrint('❌ MessagesDataSource: Erro em getOrCreateConversation - $e');
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
      debugPrint(
          '🔍 MessagesDataSource: getMessages - conversationId=$conversationId');

      var query = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfter([Timestamp.fromDate(startAfter.timestamp)]);
      }

      final snapshot = await query.get();
      final messages = snapshot.docs.map(MessageEntity.fromFirestore).toList();

      debugPrint(
          '✅ MessagesDataSource: ${messages.length} mensagens carregadas');
      return messages;
    } catch (e) {
      debugPrint('❌ MessagesDataSource: Erro em getMessages - $e');
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
      debugPrint('📤 MessagesDataSource: sendMessage');

      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      final message = MessageEntity(
        messageId: messageRef.id,
        senderId: senderId,
        senderProfileId: senderProfileId,
        text: MessageEntity.sanitize(text),
        replyTo: replyTo,
        timestamp: DateTime.now(),
      );

      await messageRef.set(message.toFirestore());

      // Update conversation lastMessage
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': message.preview,
        'lastMessageTimestamp': Timestamp.fromDate(message.timestamp),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ MessagesDataSource: Mensagem enviada');
      return message;
    } catch (e) {
      debugPrint('❌ MessagesDataSource: Erro em sendMessage - $e');
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
      debugPrint('📤 MessagesDataSource: sendImageMessage');

      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      final message = MessageEntity(
        messageId: messageRef.id,
        senderId: senderId,
        senderProfileId: senderProfileId,
        text: text.isNotEmpty ? MessageEntity.sanitize(text) : '',
        imageUrl: imageUrl,
        replyTo: replyTo,
        timestamp: DateTime.now(),
      );

      await messageRef.set(message.toFirestore());

      // Update conversation lastMessage
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': message.preview,
        'lastMessageTimestamp': Timestamp.fromDate(message.timestamp),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ MessagesDataSource: Mensagem com imagem enviada');
      return message;
    } catch (e) {
      debugPrint('❌ MessagesDataSource: Erro em sendImageMessage - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String conversationId, String profileId) async {
    try {
      debugPrint(
          '✅ MessagesDataSource: markAsRead - conversationId=$conversationId');
      await _firestore.collection('conversations').doc(conversationId).update({
        'unreadCount.$profileId': 0,
      });
    } catch (e) {
      debugPrint('❌ MessagesDataSource: Erro em markAsRead - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsUnread(String conversationId, String profileId) async {
    try {
      debugPrint(
          '📬 MessagesDataSource: markAsUnread - conversationId=$conversationId');
      await _firestore.collection('conversations').doc(conversationId).update({
        'unreadCount.$profileId': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('❌ MessagesDataSource: Erro em markAsUnread - $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteConversation(
      String conversationId, String profileId) async {
    try {
      debugPrint(
          '🗑️ MessagesDataSource: deleteConversation - conversationId=$conversationId');

      await _firestore.collection('conversations').doc(conversationId).update({
        'archivedProfileIds': FieldValue.arrayUnion([profileId]),
      });
    } catch (e) {
      debugPrint('❌ MessagesDataSource: Erro em deleteConversation - $e');
      rethrow;
    }
  }

  @override
  Future<int> getUnreadMessageCount(String profileId) async {
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .where('participantProfiles', arrayContains: profileId)
          .get();

      var total = 0;
      for (final doc in snapshot.docs) {
        final conv = ConversationEntity.fromFirestore(doc);
        if (conv.archivedProfileIds.contains(profileId)) {
          continue;
        }
        total += conv.getUnreadCountForProfile(profileId);
      }

      debugPrint('📊 MessagesDataSource: $total mensagens não lidas');
      return total;
    } catch (e) {
      debugPrint('❌ MessagesDataSource: Erro em getUnreadMessageCount - $e');
      return 0;
    }
  }

  @override
  Stream<List<ConversationEntity>> watchConversations(String profileId) {
    return _firestore
        .collection('conversations')
        .where('participantProfiles', arrayContains: profileId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ConversationEntity.fromFirestore)
              .where(
                (conversation) =>
                    !conversation.archivedProfileIds.contains(profileId),
              )
              .toList(),
        );
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(MessageEntity.fromFirestore).toList());
  }

  @override
  Stream<int> watchUnreadCount(String profileId) {
    return _firestore
        .collection('conversations')
        .where('participantProfiles', arrayContains: profileId)
        .snapshots()
        .map((snapshot) {
      var total = 0;
      for (final doc in snapshot.docs) {
        final conv = ConversationEntity.fromFirestore(doc);
        if (conv.archivedProfileIds.contains(profileId)) {
          continue;
        }
        total += conv.getUnreadCountForProfile(profileId);
      }
      return total;
    });
  }
}
