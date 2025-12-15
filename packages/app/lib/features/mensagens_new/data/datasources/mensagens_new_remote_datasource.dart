import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/entities.dart';

/// Interface para MensagensNewRemoteDataSource
///
/// Define operações de baixo nível com Firebase Firestore para mensagens.
abstract class IMensagensNewRemoteDataSource {
  // Conversas
  Future<List<ConversationNewEntity>> getConversations({
    required String profileId,
    required String profileUid,
    int limit = 20,
    bool includeArchived = false,
  });
  Future<ConversationNewEntity?> getConversationById(String conversationId);
  Future<ConversationNewEntity> getOrCreateConversation({
    required String currentProfileId,
    required String currentUid,
    required String otherProfileId,
    required String otherUid,
    Map<String, dynamic>? currentProfileData,
    Map<String, dynamic>? otherProfileData,
  });
  Future<void> archiveConversation(String conversationId, String profileId);
  Future<void> unarchiveConversation(String conversationId, String profileId);
  Future<void> deleteConversation(String conversationId, String profileId);
  Future<void> togglePinConversation(String conversationId, String profileId, bool isPinned);
  Future<void> toggleMuteConversation(String conversationId, String profileId, bool isMuted);

  // Mensagens
  Future<List<MessageNewEntity>> getMessages({
    required String conversationId,
    int limit = 50,
    MessageNewEntity? startAfter,
    DateTime? clearHistoryAfter,
  });
  Future<MessageNewEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String text,
    String? senderName,
    String? senderPhotoUrl,
    MessageReplyData? replyTo,
  });
  Future<MessageNewEntity> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String imageUrl,
    String text = '',
    String? senderName,
    String? senderPhotoUrl,
    MessageReplyData? replyTo,
  });
  Future<void> editMessage(String conversationId, String messageId, String newText);
  Future<void> deleteMessageForMe(String conversationId, String messageId, String profileId);
  Future<void> deleteMessageForEveryone(String conversationId, String messageId);

  // Reações
  Future<void> addReaction(String conversationId, String messageId, String profileId, String emoji);
  Future<void> removeReaction(String conversationId, String messageId, String profileId);

  // Status
  Future<void> markAsRead(String conversationId, String profileId);
  Future<void> markAsUnread(String conversationId, String profileId);
  Future<void> updateMessageStatus(String conversationId, String messageId, MessageDeliveryStatus status);
  Future<void> updateTypingIndicator(String conversationId, String profileId, bool isTyping);
  Future<int> getUnreadCount(String profileId, String profileUid);

  // Streams
  Stream<List<ConversationNewEntity>> watchConversations({
    required String profileId,
    required String profileUid,
    int limit = 20,
    bool includeArchived = false,
  });
  Stream<List<MessageNewEntity>> watchMessages(String conversationId, {int limit = 50, DateTime? clearHistoryAfter});
  Stream<int> watchUnreadCount(String profileId, String profileUid);
  Stream<Map<String, DateTime>> watchTypingIndicators(String conversationId);
  Stream<ConversationNewEntity?> watchConversation(String conversationId);
}

/// DataSource para MensagensNew - Firebase Firestore operations
///
/// Implementação completa de operações de chat com Firestore:
/// - CRUD de conversas e mensagens
/// - Reações e edições
/// - Streams em tempo real
/// - Indicadores de digitação
/// - Batch writes para atomicidade
class MensagensNewRemoteDataSource implements IMensagensNewRemoteDataSource {
  /// Construtor com injeção opcional de FirebaseFirestore (para testes)
  MensagensNewRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Referência para coleção de conversas
  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection('conversations');

  /// Referência para coleção de mensagens de uma conversa
  CollectionReference<Map<String, dynamic>> _messagesRef(String conversationId) =>
      _conversationsRef.doc(conversationId).collection('messages');

  // ============================================
  // CONVERSAS
  // ============================================

  @override
  Future<List<ConversationNewEntity>> getConversations({
    required String profileId,
    required String profileUid,
    int limit = 20,
    bool includeArchived = false,
  }) async {
    try {
      debugPrint('🔍 MensagensNewDS: getConversations - profileId=$profileId');

      // Query base: conversas onde o perfil participa (via UID para security rules)
      var query = _conversationsRef
          .where('participants', arrayContains: profileUid)
          .orderBy('lastMessageTimestamp', descending: true)
          .limit(limit * 2); // Aumentar para compensar filtro client-side

      final snapshot = await query.get();

      // Filtro client-side para garantir que é o perfil correto
      var conversations = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final profiles = (data['participantProfiles'] as List<dynamic>?)?.cast<String>() ?? [];
            return profiles.contains(profileId);
          })
          .map((doc) => ConversationNewEntity.fromFirestore(doc))
          .where((conv) {
            // ✅ Filtro de deletadas (soft delete) - SEMPRE aplicado
            if (conv.isDeletedForProfile(profileId)) {
              return false;
            }
            // ✅ Filtro de arquivadas: se includeArchived=true, mostrar APENAS arquivadas; senão, APENAS ativas
            if (includeArchived) {
              return conv.isArchivedForProfile(profileId);
            } else {
              return !conv.isArchivedForProfile(profileId);
            }
          })
          .take(limit)
          .toList();

      // Enriquecer com dados dos participantes
      conversations = await _enrichConversationsWithParticipants(
        conversations,
        profileId,
      );

      debugPrint(
          '✅ MensagensNewDS: ${conversations.length} conversas carregadas');
      return conversations;
    } catch (e, stack) {
      debugPrint('❌ MensagensNewDS: Erro em getConversations - $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<ConversationNewEntity?> getConversationById(
      String conversationId) async {
    try {
      debugPrint(
          '🔍 MensagensNewDS: getConversationById - id=$conversationId');

      final doc = await _conversationsRef.doc(conversationId).get();
      if (!doc.exists) {
        debugPrint('⚠️ MensagensNewDS: Conversa não encontrada');
        return null;
      }

      return ConversationNewEntity.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em getConversationById - $e');
      rethrow;
    }
  }

  @override
  Future<ConversationNewEntity> getOrCreateConversation({
    required String currentProfileId,
    required String currentUid,
    required String otherProfileId,
    required String otherUid,
    Map<String, dynamic>? currentProfileData,
    Map<String, dynamic>? otherProfileData,
  }) async {
    try {
      debugPrint(
          '🔍 MensagensNewDS: getOrCreateConversation - current=$currentProfileId, other=$otherProfileId');

      // Buscar conversa existente entre os dois perfis
      // Query otimizada: usa limit para economizar bandwidth
      final snapshot = await _conversationsRef
          .where('participants', arrayContains: currentUid)
          .limit(20) // Limita busca inicial
          .get();

      for (final doc in snapshot.docs) {
        final conv = ConversationNewEntity.fromFirestore(doc);
        // Verificar se é a conversa correta entre os dois perfis
        if (conv.participantProfiles.contains(currentProfileId) && 
            conv.participantProfiles.contains(otherProfileId)) {
          debugPrint('✅ MensagensNewDS: Conversa existente encontrada');
          
          // Desarquivar se estava arquivada
          if (conv.isArchivedForProfile(currentProfileId)) {
            await unarchiveConversation(conv.id, currentProfileId);
          }

          // 🛡️ SECURITY FIX: Garantir que participants e profileUid estão corretos
          // Isso corrige conversas antigas que podem ter dados inconsistentes
          final participants = (doc.data()['participants'] as List<dynamic>?)?.cast<String>() ?? [];
          final profileUid = (doc.data()['profileUid'] as List<dynamic>?)?.cast<String>() ?? [];
          
          final needsUpdate = !participants.contains(currentUid) || 
                            !participants.contains(otherUid) ||
                            !profileUid.contains(currentUid) ||
                            !profileUid.contains(otherUid);

          if (needsUpdate) {
             debugPrint('🛡️ MensagensNewDS: Atualizando permissões da conversa (Self-Healing)');
             await doc.reference.update({
               'participants': FieldValue.arrayUnion([currentUid, otherUid]),
               'profileUid': FieldValue.arrayUnion([currentUid, otherUid]),
             });
          }
          
          return conv;
        }
      }

      // Criar nova conversa
      debugPrint('📝 MensagensNewDS: Criando nova conversa');
      final newConvRef = _conversationsRef.doc();
      final now = DateTime.now();

      final newConv = ConversationNewEntity(
        id: newConvRef.id,
        participants: [currentUid, otherUid],
        participantProfiles: [currentProfileId, otherProfileId],
        lastMessage: '',
        lastMessageTimestamp: now,
        unreadCount: {currentProfileId: 0, otherProfileId: 0},
        createdAt: now,
        participantsData: [
          if (currentProfileData != null)
            ParticipantData.fromMap({
              ...currentProfileData,
              'profileId': currentProfileId,
              'uid': currentUid,
            }),
          if (otherProfileData != null)
            ParticipantData.fromMap({
              ...otherProfileData,
              'profileId': otherProfileId,
              'uid': otherUid,
            }),
        ],
      );

      await newConvRef.set({
        ...newConv.toFirestore(),
        // Adicionar profileUid para security rules
        'profileUid': [currentUid, otherUid],
      });

      debugPrint('✅ MensagensNewDS: Nova conversa criada - id=${newConvRef.id}');
      return newConv;
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em getOrCreateConversation - $e');
      rethrow;
    }
  }

  @override
  Future<void> archiveConversation(
      String conversationId, String profileId) async {
    try {
      debugPrint(
          '📦 MensagensNewDS: archiveConversation - id=$conversationId');

      await _conversationsRef.doc(conversationId).update({
        'archivedByProfiles': FieldValue.arrayUnion([profileId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ MensagensNewDS: Conversa arquivada');
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em archiveConversation - $e');
      rethrow;
    }
  }

  @override
  Future<void> unarchiveConversation(
      String conversationId, String profileId) async {
    try {
      debugPrint(
          '📤 MensagensNewDS: unarchiveConversation - id=$conversationId');

      await _conversationsRef.doc(conversationId).update({
        'archivedByProfiles': FieldValue.arrayRemove([profileId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ MensagensNewDS: Conversa desarquivada');
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em unarchiveConversation - $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteConversation(
      String conversationId, String profileId) async {
    try {
      debugPrint('🗑️ MensagensNewDS: deleteConversation - id=$conversationId, profileId=$profileId');

      // ✅ SOFT DELETE com CLEAR HISTORY:
      // 1. Marca como deletada para o perfil
      // 2. Salva timestamp para filtrar mensagens antigas quando a conversa reaparecer
      // Isso garante que se o outro participante enviar uma nova mensagem,
      // o histórico antigo não será exibido para quem deletou.
      await _conversationsRef.doc(conversationId).update({
        'deletedByProfiles': FieldValue.arrayUnion([profileId]),
        'clearHistoryTimestamp.$profileId': FieldValue.serverTimestamp(),
        'unreadCount.$profileId': 0, // Zera contador de não lidas
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ MensagensNewDS: Conversa marcada como deletada para profileId=$profileId com clearHistoryTimestamp');
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em deleteConversation - $e');
      rethrow;
    }
  }

  @override
  Future<void> togglePinConversation(
      String conversationId, String profileId, bool isPinned) async {
    try {
      debugPrint(
          '📌 MensagensNewDS: togglePinConversation - id=$conversationId, pin=$isPinned');

      await _conversationsRef.doc(conversationId).update({
        'pinnedByProfiles': isPinned
            ? FieldValue.arrayUnion([profileId])
            : FieldValue.arrayRemove([profileId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ MensagensNewDS: Conversa ${isPinned ? "fixada" : "desfixada"}');
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em togglePinConversation - $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleMuteConversation(
      String conversationId, String profileId, bool isMuted) async {
    try {
      debugPrint(
          '🔇 MensagensNewDS: toggleMuteConversation - id=$conversationId, mute=$isMuted');

      await _conversationsRef.doc(conversationId).update({
        'mutedByProfiles': isMuted
            ? FieldValue.arrayUnion([profileId])
            : FieldValue.arrayRemove([profileId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
          '✅ MensagensNewDS: Conversa ${isMuted ? "silenciada" : "com notificações"}');
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em toggleMuteConversation - $e');
      rethrow;
    }
  }

  // ============================================
  // MENSAGENS
  // ============================================

  @override
  Future<List<MessageNewEntity>> getMessages({
    required String conversationId,
    int limit = 50,
    MessageNewEntity? startAfter,
    DateTime? clearHistoryAfter,
  }) async {
    try {
      debugPrint(
          '🔍 MensagensNewDS: getMessages - conversationId=$conversationId');

      var query = _messagesRef(conversationId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // ✅ Filtrar mensagens após clearHistoryTimestamp (para não mostrar histórico antigo)
      if (clearHistoryAfter != null) {
        query = query.where(
          'createdAt',
          isGreaterThan: Timestamp.fromDate(clearHistoryAfter),
        );
        debugPrint('🔍 MensagensNewDS: Filtrando mensagens após $clearHistoryAfter');
      }

      if (startAfter != null) {
        query = query.startAfter([Timestamp.fromDate(startAfter.createdAt)]);
      }

      final snapshot = await query.get();
      final messages = snapshot.docs
          .map((doc) =>
              MessageNewEntity.fromFirestore(doc, conversationId: conversationId))
          .toList();

      debugPrint('✅ MensagensNewDS: ${messages.length} mensagens carregadas');
      return messages;
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em getMessages - $e');
      rethrow;
    }
  }

  @override
  Future<MessageNewEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String text,
    String? senderName,
    String? senderPhotoUrl,
    MessageReplyData? replyTo,
  }) async {
    try {
      debugPrint('📤 MensagensNewDS: sendMessage - conv=$conversationId');

      final batch = _firestore.batch();
      final messageRef = _messagesRef(conversationId).doc();
      final now = DateTime.now();

      final message = MessageNewEntity(
        id: messageRef.id,
        conversationId: conversationId,
        senderId: senderId,
        senderProfileId: senderProfileId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        text: MessageNewEntity.sanitize(text),
        type: MessageType.text,
        status: MessageDeliveryStatus.sent,
        createdAt: now,
        replyTo: replyTo,
      );

      // Criar mensagem
      batch.set(messageRef, message.toFirestore());

      // Atualizar conversa
      final convRef = _conversationsRef.doc(conversationId);
      
      // Buscar outros participantes para incrementar unread
      final convDoc = await convRef.get();
      final participantProfiles = (convDoc.data()?['participantProfiles'] as List<dynamic>?)
          ?.cast<String>() ?? [];

      final updates = <String, dynamic>{
        'lastMessage': message.preview,
        'lastMessageTimestamp': Timestamp.fromDate(now),
        'lastMessageSenderId': senderProfileId,
        'updatedAt': FieldValue.serverTimestamp(),
        // ✅ Restaurar conversa para TODOS os participantes ao enviar mensagem
        // Remove do deletedByProfiles para que a conversa "reapareça" como nova
        'deletedByProfiles': <String>[],
        // Desarquivar conversa para TODOS os participantes ao enviar mensagem
        'archivedByProfiles': <String>[],
      };

      // Incrementar unread para outros participantes
      for (final profileId in participantProfiles) {
        if (profileId != senderProfileId) {
          updates['unreadCount.$profileId'] = FieldValue.increment(1);
        }
      }

      batch.update(convRef, updates);

      await batch.commit();

      debugPrint('✅ MensagensNewDS: Mensagem enviada - id=${messageRef.id}');
      return message;
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em sendMessage - $e');
      rethrow;
    }
  }

  @override
  Future<MessageNewEntity> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String imageUrl,
    String text = '',
    String? senderName,
    String? senderPhotoUrl,
    MessageReplyData? replyTo,
  }) async {
    try {
      debugPrint('📤 MensagensNewDS: sendImageMessage - conv=$conversationId');

      final batch = _firestore.batch();
      final messageRef = _messagesRef(conversationId).doc();
      final now = DateTime.now();

      final message = MessageNewEntity(
        id: messageRef.id,
        conversationId: conversationId,
        senderId: senderId,
        senderProfileId: senderProfileId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        text: text.isNotEmpty ? MessageNewEntity.sanitize(text) : '',
        imageUrl: imageUrl,
        type: MessageType.image,
        status: MessageDeliveryStatus.sent,
        createdAt: now,
        replyTo: replyTo,
      );

      batch.set(messageRef, message.toFirestore());

      // Atualizar conversa
      final convRef = _conversationsRef.doc(conversationId);
      final convDoc = await convRef.get();
      final participantProfiles = (convDoc.data()?['participantProfiles'] as List<dynamic>?)
          ?.cast<String>() ?? [];

      final updates = <String, dynamic>{
        'lastMessage': message.preview,
        'lastMessageTimestamp': Timestamp.fromDate(now),
        'lastMessageSenderId': senderProfileId,
        'updatedAt': FieldValue.serverTimestamp(),
        // ✅ Restaurar conversa para TODOS os participantes ao enviar imagem
        // Remove do deletedByProfiles para que a conversa "reapareça" como nova
        'deletedByProfiles': <String>[],
        // Desarquivar conversa para TODOS os participantes ao enviar imagem
        'archivedByProfiles': <String>[],
      };

      for (final profileId in participantProfiles) {
        if (profileId != senderProfileId) {
          updates['unreadCount.$profileId'] = FieldValue.increment(1);
        }
      }

      batch.update(convRef, updates);
      await batch.commit();

      debugPrint('✅ MensagensNewDS: Imagem enviada - id=${messageRef.id}');
      return message;
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em sendImageMessage - $e');
      rethrow;
    }
  }

  @override
  Future<void> editMessage(
      String conversationId, String messageId, String newText) async {
    try {
      debugPrint('✏️ MensagensNewDS: editMessage - id=$messageId');

      await _messagesRef(conversationId).doc(messageId).update({
        'text': MessageNewEntity.sanitize(newText),
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ MensagensNewDS: Mensagem editada');
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em editMessage - $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMessageForMe(
      String conversationId, String messageId, String profileId) async {
    try {
      debugPrint('🗑️ MensagensNewDS: deleteMessageForMe - id=$messageId');

      await _messagesRef(conversationId).doc(messageId).update({
        'deletedForProfiles': FieldValue.arrayUnion([profileId]),
      });

      debugPrint('✅ MensagensNewDS: Mensagem deletada para o perfil');
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em deleteMessageForMe - $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMessageForEveryone(
      String conversationId, String messageId) async {
    try {
      debugPrint('🗑️ MensagensNewDS: deleteMessageForEveryone - id=$messageId');

      // Buscar mensagem original para salvar
      final msgDoc = await _messagesRef(conversationId).doc(messageId).get();
      final originalText = msgDoc.data()?['text'] as String?;

      await _messagesRef(conversationId).doc(messageId).update({
        'deletedForEveryone': true,
        'type': MessageType.deleted.name,
        'text': '',
        if (originalText != null) 'originalText': originalText,
      });

      debugPrint('✅ MensagensNewDS: Mensagem deletada para todos');
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em deleteMessageForEveryone - $e');
      rethrow;
    }
  }

  // ============================================
  // REAÇÕES
  // ============================================

  @override
  Future<void> addReaction(String conversationId, String messageId,
      String profileId, String emoji) async {
    try {
      debugPrint('😀 MensagensNewDS: addReaction - msg=$messageId, emoji=$emoji');

      await _messagesRef(conversationId).doc(messageId).update({
        'reactions.$profileId': emoji,
      });

      debugPrint('✅ MensagensNewDS: Reação adicionada');
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em addReaction - $e');
      rethrow;
    }
  }

  @override
  Future<void> removeReaction(
      String conversationId, String messageId, String profileId) async {
    try {
      debugPrint('😶 MensagensNewDS: removeReaction - msg=$messageId');

      await _messagesRef(conversationId).doc(messageId).update({
        'reactions.$profileId': FieldValue.delete(),
      });

      debugPrint('✅ MensagensNewDS: Reação removida');
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em removeReaction - $e');
      rethrow;
    }
  }

  // ============================================
  // STATUS DE LEITURA
  // ============================================

  @override
  Future<void> markAsRead(String conversationId, String profileId) async {
    try {
      debugPrint('👁️ MensagensNewDS: markAsRead - conv=$conversationId');

      await _conversationsRef.doc(conversationId).update({
        'unreadCount.$profileId': 0,
      });

      debugPrint('✅ MensagensNewDS: Conversa marcada como lida');
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em markAsRead - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsUnread(String conversationId, String profileId) async {
    try {
      debugPrint('🔵 MensagensNewDS: markAsUnread - conv=$conversationId');

      await _conversationsRef.doc(conversationId).update({
        'unreadCount.$profileId': 1,
      });

      debugPrint('✅ MensagensNewDS: Conversa marcada como não lida');
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em markAsUnread - $e');
      rethrow;
    }
  }

  @override
  Future<void> updateMessageStatus(String conversationId, String messageId,
      MessageDeliveryStatus status) async {
    try {
      debugPrint(
          '📬 MensagensNewDS: updateMessageStatus - msg=$messageId, status=$status');

      await _messagesRef(conversationId).doc(messageId).update({
        'status': status.name,
      });

      debugPrint('✅ MensagensNewDS: Status da mensagem atualizado');
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em updateMessageStatus - $e');
      rethrow;
    }
  }

  @override
  Future<void> updateTypingIndicator(
      String conversationId, String profileId, bool isTyping) async {
    try {
      if (isTyping) {
        await _conversationsRef.doc(conversationId).update({
          'typingIndicators.$profileId': FieldValue.serverTimestamp(),
        });
      } else {
        await _conversationsRef.doc(conversationId).update({
          'typingIndicators.$profileId': FieldValue.delete(),
        });
      }
    } catch (e) {
      // Não propagar erro de typing - não é crítico
      debugPrint('⚠️ MensagensNewDS: Erro em updateTypingIndicator - $e');
    }
  }

  @override
  Future<int> getUnreadCount(String profileId, String profileUid) async {
    try {
      debugPrint('🔢 MensagensNewDS: getUnreadCount - profileId=$profileId, profileUid=$profileUid');

      // IMPORTANTE: Query por UID (participants) para satisfazer as security rules do Firestore
      final snapshot = await _conversationsRef
          .where('participants', arrayContains: profileUid)
          .get();

      var totalUnread = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Filtro client-side: verificar se o profileId está nos participantProfiles
        final participantProfiles =
            (data['participantProfiles'] as List<dynamic>?)?.cast<String>() ?? [];
        if (!participantProfiles.contains(profileId)) continue;

        // ✅ Ignorar conversas deletadas (soft delete)
        final deletedBy =
            (data['deletedByProfiles'] as List<dynamic>?)?.cast<String>() ?? [];
        if (deletedBy.contains(profileId)) continue;

        // Verificar se não está arquivada
        final archivedBy =
            (data['archivedByProfiles'] as List<dynamic>?)?.cast<String>() ??
                [];
        if (archivedBy.contains(profileId)) continue;

        final unreadCount = (data['unreadCount'] as Map<String, dynamic>?) ?? {};
        totalUnread += (unreadCount[profileId] as num?)?.toInt() ?? 0;
      }

      debugPrint('✅ MensagensNewDS: Total não lidas = $totalUnread');
      return totalUnread;
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em getUnreadCount - $e');
      rethrow;
    }
  }

  // ============================================
  // STREAMS EM TEMPO REAL
  // ============================================

  @override
  Stream<List<ConversationNewEntity>> watchConversations({
    required String profileId,
    required String profileUid,
    int limit = 20,
    bool includeArchived = false,
  }) {
    debugPrint('👀 MensagensNewDS: watchConversations - profileId=$profileId, profileUid=$profileUid');

    // IMPORTANTE: Query por UID (participants) para satisfazer as security rules do Firestore
    // As regras verificam: request.auth.uid in resource.data.participants
    return _conversationsRef
        .where('participants', arrayContains: profileUid)
        .orderBy('lastMessageTimestamp', descending: true)
        .limit(limit * 2)
        .snapshots()
        .asyncMap((snapshot) async {
      debugPrint('📨 MensagensNewDS: watchConversations snapshot com ${snapshot.docs.length} docs');
      
      var conversations = snapshot.docs
          .where((doc) {
            final data = doc.data();
            // Filtro client-side: verificar se o profileId está nos participantProfiles
            final profiles =
                (data['participantProfiles'] as List<dynamic>?)?.cast<String>() ?? [];
            return profiles.contains(profileId);
          })
          .map((doc) => ConversationNewEntity.fromFirestore(doc))
          .where((conv) {
            // ✅ Filtro de deletadas (soft delete) - SEMPRE aplicado
            if (conv.isDeletedForProfile(profileId)) {
              return false;
            }
            // ✅ Filtro de arquivadas: se includeArchived=true, mostrar APENAS arquivadas; senão, APENAS ativas
            if (includeArchived) {
              return conv.isArchivedForProfile(profileId);
            } else {
              return !conv.isArchivedForProfile(profileId);
            }
          })
          .take(limit)
          .toList();

      // Ordenar: fixadas primeiro, depois por timestamp
      conversations.sort((a, b) {
        final aPinned = a.isPinnedForProfile(profileId);
        final bPinned = b.isPinnedForProfile(profileId);
        if (aPinned && !bPinned) return -1;
        if (!aPinned && bPinned) return 1;
        return b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp);
      });

      debugPrint('✅ MensagensNewDS: watchConversations retornando ${conversations.length} conversas');
      
      // Enriquecer com dados dos participantes
      return _enrichConversationsWithParticipants(conversations, profileId);
    });
  }

  @override
  Stream<List<MessageNewEntity>> watchMessages(String conversationId,
      {int limit = 50, DateTime? clearHistoryAfter}) {
    debugPrint('👀 MensagensNewDS: watchMessages - conv=$conversationId');

    var query = _messagesRef(conversationId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    // ✅ Filtrar mensagens após clearHistoryTimestamp (para não mostrar histórico antigo)
    if (clearHistoryAfter != null) {
      query = query.where(
        'createdAt',
        isGreaterThan: Timestamp.fromDate(clearHistoryAfter),
      );
      debugPrint('👀 MensagensNewDS: Filtrando stream após $clearHistoryAfter');
    }

    return query
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                MessageNewEntity.fromFirestore(doc, conversationId: conversationId))
            .toList());
  }

  @override
  Stream<int> watchUnreadCount(String profileId, String profileUid) {
    debugPrint('👀 MensagensNewDS: watchUnreadCount - profileId=$profileId, profileUid=$profileUid');

    // IMPORTANTE: Query por UID (participants) para satisfazer as security rules do Firestore
    return _conversationsRef
        .where('participants', arrayContains: profileUid)
        .snapshots()
        .map((snapshot) {
      // Conta CONVERSAS não lidas (não total de mensagens)
      var unreadConversations = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Filtro client-side: verificar se o profileId está nos participantProfiles
        final participantProfiles =
            (data['participantProfiles'] as List<dynamic>?)?.cast<String>() ?? [];
        
        if (!participantProfiles.contains(profileId)) continue;

        // ✅ Ignorar conversas deletadas (soft delete)
        final deletedBy =
            (data['deletedByProfiles'] as List<dynamic>?)?.cast<String>() ?? [];
        if (deletedBy.contains(profileId)) continue;

        final archivedBy =
            (data['archivedByProfiles'] as List<dynamic>?)?.cast<String>() ?? [];
        if (archivedBy.contains(profileId)) continue;

        final unreadCount = (data['unreadCount'] as Map<String, dynamic>?) ?? {};
        final countForProfile = (unreadCount[profileId] as num?)?.toInt() ?? 0;
        
        // Conta como 1 conversa não lida se tiver qualquer mensagem não lida
        if (countForProfile > 0) {
          unreadConversations++;
        }
      }
      debugPrint('📊 MensagensNewDS: watchUnreadCount = $unreadConversations conversas não lidas');
      return unreadConversations;
    }).distinct(); // Evita emissões duplicadas quando o valor não muda
  }

  @override
  Stream<Map<String, DateTime>> watchTypingIndicators(String conversationId) {
    return _conversationsRef
        .doc(conversationId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) return <String, DateTime>{};
      
      final indicators = data['typingIndicators'] as Map<String, dynamic>?;
      if (indicators == null) return <String, DateTime>{};

      return Map<String, DateTime>.from(
        indicators.map((k, v) {
          final timestamp = v is Timestamp ? v.toDate() : DateTime.now();
          return MapEntry(k, timestamp);
        }),
      );
    });
  }

  @override
  Stream<ConversationNewEntity?> watchConversation(String conversationId) {
    return _conversationsRef
        .doc(conversationId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return ConversationNewEntity.fromFirestore(snapshot);
    });
  }

  // ============================================
  // HELPERS PRIVADOS
  // ============================================

  /// Enriquece conversas com dados completos dos participantes
  Future<List<ConversationNewEntity>> _enrichConversationsWithParticipants(
    List<ConversationNewEntity> conversations,
    String currentProfileId,
  ) async {
    if (conversations.isEmpty) return conversations;

    // Coletar todos os profileIds únicos dos outros participantes
    final otherProfileIds = <String>{};
    for (final conv in conversations) {
      final otherId = conv.getOtherProfileId(currentProfileId);
      if (otherId != null) otherProfileIds.add(otherId);
    }

    if (otherProfileIds.isEmpty) return conversations;

    // Buscar dados dos perfis em batch
    final profilesData = <String, ParticipantData>{};
    
    // Firestore permite no máximo 10 IDs por whereIn
    final chunks = _chunkList(otherProfileIds.toList(), 10);
    
    for (final chunk in chunks) {
      final profilesSnapshot = await _firestore
          .collection('profiles')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in profilesSnapshot.docs) {
        final data = doc.data();
        profilesData[doc.id] = ParticipantData(
          profileId: doc.id,
          uid: data['uid'] as String? ?? '',
          name: data['name'] as String? ?? 'Usuário',
          photoUrl: data['photoUrl'] as String?,
          profileType: data['type'] as String?,
        );
      }
    }

    // Enriquecer conversas com dados dos participantes
    return conversations.map((conv) {
      final otherProfileId = conv.getOtherProfileId(currentProfileId);
      if (otherProfileId == null) return conv;

      final otherData = profilesData[otherProfileId];
      if (otherData == null) return conv;

      return conv.copyWith(
        participantsData: [otherData],
      );
    }).toList();
  }

  /// Divide lista em chunks de tamanho máximo
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }
}
