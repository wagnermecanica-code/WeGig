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
    String? profileUid,
  });
  Future<ConversationEntity?> getConversationById(String conversationId);
  Future<ConversationEntity> getOrCreateConversation({
    required String currentProfileId,
    required String otherProfileId,
    required String currentUid,
    required String otherUid,
    String? profileUid,
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
  Future<void> addReaction(String conversationId, String messageId, String userId, String reaction);
  Future<void> removeReaction(String conversationId, String messageId, String userId);
  Future<void> deleteMessage(String conversationId, String messageId);
  Future<void> markAsRead(String conversationId, String profileId);
  Future<void> markAsUnread(String conversationId, String profileId);
  Future<void> deleteConversation(String conversationId, String profileId);
  Future<int> getUnreadMessageCount(String profileId, {String? profileUid});
  Stream<List<ConversationEntity>> watchConversations(String profileId,
      {String? profileUid, int limit = 20});
  Stream<List<MessageEntity>> watchMessages(String conversationId);
  Stream<int> watchUnreadCount(String profileId, {String? profileUid});
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
    String? profileUid,
  }) async {
    try {
      debugPrint(
          '🔍 MessagesDataSource: getConversations - profileId=$profileId');

      // ✅ FIX: Não usar dois array-contains - filtrar profileUid no client-side
      var query = _firestore
          .collection('conversations')
          .where('participantProfiles', arrayContains: profileId)
          .limit(limit * 2); // Aumentar limite para compensar filtro client-side

      if (startAfter != null) {
        query = query
            .startAfter([startAfter.id]);
      }

      final snapshot = await query.get();
      
      // ✅ Filtro client-side: archived + profileUid
      final conversations = snapshot.docs
          .where((doc) {
            // Filtro 1: profileUid (client-side)
            if (profileUid != null && profileUid.isNotEmpty) {
              final data = doc.data();
              final profileUids = (data['profileUid'] as List?)?.cast<String>() ?? [];
              if (!profileUids.contains(profileUid)) return false;
            }
            return true;
          })
          .map(ConversationEntity.fromFirestore)
          .where(
            (conversation) =>
              !conversation.archivedProfileIds.contains(profileId),
          )
          .take(limit) // Aplicar limite original após filtros
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
    String? profileUid,
  }) async {
    try {
      debugPrint('🔍 MessagesDataSource: getOrCreateConversation');

      // Busca conversa existente
      final snapshot = await _firestore.collection('conversations').where(
          'participantProfiles',
          arrayContainsAny: [currentProfileId, otherProfileId]).get();

      for (final doc in snapshot.docs) {
        final conv = ConversationEntity.fromFirestore(doc);
        // Backfill profileUid array when ausente para suportar filtros por owner UID
        if (!doc.data().containsKey('profileUid')) {
          await doc.reference.update({
            'profileUid': FieldValue.arrayUnion([currentUid, otherUid]),
          });
        }
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
      await newConvRef.update({
        // Array com donos de cada perfil participante (uids)
        'profileUid': FieldValue.arrayUnion([currentUid, otherUid]),
      });
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

      final batch = _firestore.batch(); // ✅ FIX: Atomicidade

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

      batch.set(messageRef, {
        ...message.toFirestore(),
        'profileUid': senderId,
      });

      // Update conversation lastMessage
      final conversationRef = _firestore.collection('conversations').doc(conversationId);
      batch.update(conversationRef, {
        'lastMessage': message.preview,
        'lastMessageTimestamp': Timestamp.fromDate(message.timestamp),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit(); // ✅ FIX: Commit atômico

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

      final batch = _firestore.batch(); // ✅ FIX: Atomicidade

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

      batch.set(messageRef, {
        ...message.toFirestore(),
        'profileUid': senderId,
      });

      // Update conversation lastMessage
      final conversationRef = _firestore.collection('conversations').doc(conversationId);
      batch.update(conversationRef, {
        'lastMessage': message.preview,
        'lastMessageTimestamp': Timestamp.fromDate(message.timestamp),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit(); // ✅ FIX: Commit atômico

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
  Future<int> getUnreadMessageCount(String profileId,
      {String? profileUid}) async {
    try {
      // ✅ FIX: Remover segundo array-contains e filtrar no client-side
      var query = _firestore
          .collection('conversations')
          .where('participantProfiles', arrayContains: profileId);

      final snapshot = await query.get();

      var total = 0;
      for (final doc in snapshot.docs) {
        // Filtro 1: profileUid (client-side)
        if (profileUid != null && profileUid.isNotEmpty) {
          final data = doc.data();
          final profileUids = (data['profileUid'] as List?)?.cast<String>() ?? [];
          if (!profileUids.contains(profileUid)) continue;
        }
        
        final conv = ConversationEntity.fromFirestore(doc);
        
        // Filtro 2: archived
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
  Stream<List<ConversationEntity>> watchConversations(String profileId,
      {String? profileUid, int limit = 20}) {
    final userUid = profileUid ?? '';
    
    if (userUid.isEmpty) {
      debugPrint('⚠️ watchConversations: profileUid vazio, retornando stream vazio');
      return Stream.value([]);
    }
    
    debugPrint('🔍 watchConversations: Query por profileUid=$userUid, filtrar por profileId=$profileId');
    
    var query = _firestore
        .collection('conversations')
        .where('profileUid', arrayContains: userUid)
        .orderBy('lastMessageTimestamp', descending: true)
        .limit(limit); // Ordenação importante

    return query.snapshots().asyncMap((snapshot) async {
      debugPrint('📦 watchConversations: ${snapshot.docs.length} conversas retornadas');
      
      // 1. Parse inicial e filtros
      final conversations = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final participantProfiles = (data['participantProfiles'] as List?)?.cast<String>() ?? [];
            return participantProfiles.contains(profileId);
          })
          .map(ConversationEntity.fromFirestore)
          .where((c) => !c.archivedProfileIds.contains(profileId))
          .toList();

      if (conversations.isEmpty) return [];

      // 2. Coletar IDs únicos para busca em lote
      final profileIdsToFetch = <String>{};
      final userIdsToFetch = <String>{};

      for (final conv in conversations) {
        profileIdsToFetch.addAll(conv.participantProfiles);
        userIdsToFetch.addAll(conv.participants);
      }
      
      // Remover ID do próprio usuário se desejar, mas manter para consistência
      // profileIdsToFetch.remove(profileId); 

      // 3. Buscar Perfis (Profiles) em lotes de 10
      final profilesDataMap = <String, Map<String, dynamic>>{};
      final profileIdsList = profileIdsToFetch.toList();
      
      for (var i = 0; i < profileIdsList.length; i += 10) {
        final end = (i + 10 < profileIdsList.length) ? i + 10 : profileIdsList.length;
        final chunk = profileIdsList.sublist(i, end);
        if (chunk.isEmpty) continue;

        try {
          final profilesSnap = await _firestore
              .collection('profiles')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          
          for (final doc in profilesSnap.docs) {
            profilesDataMap[doc.id] = {
              'profileId': doc.id,
              ...doc.data(),
            };
          }
        } catch (e) {
          debugPrint('❌ Erro ao buscar perfis em lote: $e');
        }
      }

      // 4. Buscar Usuários (Users) em lotes de 10 (para isOnline)
      final usersDataMap = <String, Map<String, dynamic>>{};
      final userIdsList = userIdsToFetch.toList();

      for (var i = 0; i < userIdsList.length; i += 10) {
        final end = (i + 10 < userIdsList.length) ? i + 10 : userIdsList.length;
        final chunk = userIdsList.sublist(i, end);
        if (chunk.isEmpty) continue;

        try {
          final usersSnap = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          
          for (final doc in usersSnap.docs) {
            usersDataMap[doc.id] = doc.data();
          }
        } catch (e) {
          debugPrint('❌ Erro ao buscar usuários em lote: $e');
        }
      }

      // 5. Enriquecer Conversas
      return conversations.map((c) {
        final enrichedProfiles = c.participantProfiles.map((pid) {
          final profileData = profilesDataMap[pid] ?? {};
          
          // Tentar encontrar o UID associado a este perfil para pegar dados do usuário
          // O profileData tem 'uid'? Sim, geralmente.
          final uid = profileData['uid'] as String?;
          final userData = (uid != null) ? usersDataMap[uid] : null;

          if (userData != null) {
            profileData['isOnline'] = userData['isOnline'] ?? false;
          }
          
          return profileData;
        }).toList();

        return c.copyWith(participantProfilesData: enrichedProfiles);
      }).toList();
    });
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
  Stream<int> watchUnreadCount(String profileId, {String? profileUid}) {
    // ✅ FIX: Query por profileUid (UIDs) para match com Security Rules
    final userUid = profileUid ?? '';
    
    if (userUid.isEmpty) {
      return Stream.value(0);
    }
    
    var query = _firestore
        .collection('conversations')
        .where('profileUid', arrayContains: userUid);

    return query.snapshots().map((snapshot) {
      var total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Filtro client-side: apenas conversas onde o profileId participa
        final participantProfiles = (data['participantProfiles'] as List?)?.cast<String>() ?? [];
        if (!participantProfiles.contains(profileId)) continue;
        
        final conv = ConversationEntity.fromFirestore(doc);
        
        // Filtro 2: archived
        if (conv.archivedProfileIds.contains(profileId)) {
          continue;
        }
        
        total += conv.getUnreadCountForProfile(profileId);
      }
      return total;
    });
  }

  @override
  Future<void> addReaction(String conversationId, String messageId, String userId, String reaction) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$userId': reaction,
      });
    } catch (e) {
      debugPrint('❌ MessagesDataSource: Erro em addReaction - $e');
      rethrow;
    }
  }

  @override
  Future<void> removeReaction(String conversationId, String messageId, String userId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$userId': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('❌ MessagesDataSource: Erro em removeReaction - $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      debugPrint('❌ MessagesDataSource: Erro em deleteMessage - $e');
      rethrow;
    }
  }
}
