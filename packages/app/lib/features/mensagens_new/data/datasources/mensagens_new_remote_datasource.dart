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
  Future<MessageNewEntity> sendSharedPostMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required Map<String, dynamic> postData,
    String? senderName,
    String? senderPhotoUrl,
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

  // Status para grupos
  /// Marca mensagens como recebidas por um perfil em um grupo
  Future<void> markGroupMessagesAsReceived(String conversationId, String profileId);
  /// Marca mensagens como lidas por um perfil em um grupo
  Future<void> markGroupMessagesAsRead(String conversationId, String profileId);

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

  String _buildDirectConversationKey(String profileIdA, String profileIdB) {
    final sortedProfileIds = [profileIdA.trim(), profileIdB.trim()]..sort();
    return sortedProfileIds.join('__');
  }

  bool _isDirectConversation(
    Map<String, dynamic> data,
    List<String> participantProfiles,
  ) {
    final rawIsGroup = data['isGroup'] as bool?;
    final rawGroupName = data['groupName'];
    final conversationType = data['conversationType'] as String?;

    final inferredIsGroup = conversationType == 'group' ||
        (rawIsGroup ?? false) ||
        participantProfiles.length > 2 ||
        (rawGroupName is String && rawGroupName.trim().isNotEmpty);

    return !inferredIsGroup && participantProfiles.length == 2;
  }

  bool _shouldFallbackDirectLookup(FirebaseException error) {
    return error.code == 'failed-precondition' ||
        error.code == 'permission-denied';
  }

  Future<QuerySnapshot<Map<String, dynamic>>?> _queryDirectConversationByKey({
    required String membershipField,
    required String currentUid,
    required String directConversationKey,
  }) async {
    try {
      return await _conversationsRef
          .where(membershipField, arrayContains: currentUid)
          .where('directConversationKey', isEqualTo: directConversationKey)
          .limit(1)
          .get();
    } on FirebaseException catch (error) {
      if (!_shouldFallbackDirectLookup(error)) {
        rethrow;
      }

      debugPrint(
        '⚠️ MensagensNewDS: directConversationKey indisponível em '
        '$membershipField (${error.code}), usando fallback legado',
      );
      return null;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDirectConversationByKey({
    required String currentUid,
    required String directConversationKey,
  }) async {
    final participantsSnapshot = await _queryDirectConversationByKey(
      membershipField: 'participants',
      currentUid: currentUid,
      directConversationKey: directConversationKey,
    );
    if (participantsSnapshot != null && participantsSnapshot.docs.isNotEmpty) {
      return participantsSnapshot.docs.first;
    }

    final profileUidSnapshot = await _queryDirectConversationByKey(
      membershipField: 'profileUid',
      currentUid: currentUid,
      directConversationKey: directConversationKey,
    );
    if (profileUidSnapshot != null && profileUidSnapshot.docs.isNotEmpty) {
      return profileUidSnapshot.docs.first;
    }

    return null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      _findLegacyDirectConversationByMembershipField({
    required String membershipField,
    required String currentProfileId,
    required String currentUid,
    required String otherProfileId,
  }) async {
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;

    while (true) {
      Query<Map<String, dynamic>> query = _conversationsRef
          .where(membershipField, arrayContains: currentUid)
          .limit(50);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        return null;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participantProfiles =
            (data['participantProfiles'] as List<dynamic>?)?.cast<String>() ??
                [];

        if (_isDirectConversation(data, participantProfiles) &&
            participantProfiles.contains(currentProfileId) &&
            participantProfiles.contains(otherProfileId)) {
          return doc;
        }
      }

      if (snapshot.docs.length < 50) {
        return null;
      }

      lastDoc = snapshot.docs.last;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findLegacyDirectConversation({
    required String currentProfileId,
    required String currentUid,
    required String otherProfileId,
  }) async {
    final participantsMatch = await _findLegacyDirectConversationByMembershipField(
      membershipField: 'participants',
      currentProfileId: currentProfileId,
      currentUid: currentUid,
      otherProfileId: otherProfileId,
    );
    if (participantsMatch != null) {
      return participantsMatch;
    }

    return _findLegacyDirectConversationByMembershipField(
      membershipField: 'profileUid',
      currentProfileId: currentProfileId,
      currentUid: currentUid,
      otherProfileId: otherProfileId,
    );
  }

  // ============================================
  // CONVERSAS
  // ============================================

  /// Inferir e normalizar o tipo de conversa para dados legados.
  ///
  /// Regra canônica:
  /// - conversationType: 'group' | 'direct'
  ///
  /// Compatibilidade (legado):
  /// - Se isGroup=true OU participantProfiles.length>2 OU groupName preenchido => group
  /// - Caso contrário => direct
  String _inferConversationType(Map<String, dynamic> data) {
    final conversationType = data['conversationType'] as String?;
    if (conversationType == 'group' || conversationType == 'direct') {
      return conversationType!;
    }

    final participantProfiles =
        (data['participantProfiles'] as List<dynamic>?)?.cast<String>() ?? const <String>[];
    final explicitIsGroup = data['isGroup'] as bool?;
    final groupName = data['groupName'] as String?;

    final inferredIsGroup = (explicitIsGroup ?? false) ||
        participantProfiles.length > 2 ||
        (groupName != null && groupName.trim().isNotEmpty);

    return inferredIsGroup ? 'group' : 'direct';
  }

  /// Gera updates para normalizar conversa legada; retorna null se não precisa.
  Map<String, dynamic>? _getLegacyConversationNormalizationUpdates(
    Map<String, dynamic> data,
  ) {
    final desiredType = _inferConversationType(data);

    final currentType = data['conversationType'] as String?;
    final explicitIsGroup = data['isGroup'] as bool?;

    final updates = <String, dynamic>{};

    if (currentType != desiredType) {
      updates['conversationType'] = desiredType;
    }

    final desiredIsGroup = desiredType == 'group';
    if (explicitIsGroup != desiredIsGroup) {
      updates['isGroup'] = desiredIsGroup;
    }

    // Se for direct, limpar campos específicos de grupo que causam confusão
    if (!desiredIsGroup) {
      if (data['groupName'] != null) updates['groupName'] = FieldValue.delete();
      if (data['groupPhotoUrl'] != null) updates['groupPhotoUrl'] = FieldValue.delete();
    }

    return updates.isEmpty ? null : updates;
  }

  Future<void> _normalizeLegacyConversationsIfNeeded({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String profileId,
  }) async {
    // Atualiza apenas conversas do perfil atual (por participantProfiles)
    // para evitar writes desnecessários em conversas que não pertencem ao perfil.
    final batch = _firestore.batch();
    var updatesCount = 0;

    for (final doc in docs) {
      if (updatesCount >= 20) break; // Evita batch enorme em um único snapshot

      final data = doc.data();
      final participantProfiles =
          (data['participantProfiles'] as List<dynamic>?)?.cast<String>() ?? const <String>[];
      if (!participantProfiles.contains(profileId)) continue;

      final updates = _getLegacyConversationNormalizationUpdates(data);
      if (updates == null) continue;

      batch.update(doc.reference, {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      updatesCount++;
    }

    if (updatesCount == 0) return;

    try {
      await batch.commit();
      debugPrint('🧹 MensagensNewDS: Normalizadas $updatesCount conversas legadas');
    } catch (e) {
      // Best-effort: se falhar (rules/offline), não quebra a UI.
      debugPrint('⚠️ MensagensNewDS: Falha ao normalizar conversas legadas: $e');
    }
  }

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

      // Best-effort: normaliza conversas legadas para evitar confusão de tipo.
      await _normalizeLegacyConversationsIfNeeded(
        docs: snapshot.docs,
        profileId: profileId,
      );

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

      final directConversationKey =
          _buildDirectConversationKey(currentProfileId, otherProfileId);

      DocumentSnapshot<Map<String, dynamic>>? matchedDoc =
          await _findDirectConversationByKey(
        currentUid: currentUid,
        directConversationKey: directConversationKey,
      );

      matchedDoc ??= await _findLegacyDirectConversation(
        currentProfileId: currentProfileId,
        currentUid: currentUid,
        otherProfileId: otherProfileId,
      );

      if (matchedDoc != null) {
        final data = matchedDoc.data();
        if (data != null) {
          final participantProfiles =
              (data['participantProfiles'] as List<dynamic>?)?.cast<String>() ??
                  [];
          final participants =
              (data['participants'] as List<dynamic>?)?.cast<String>() ?? [];
          final profileUid =
              (data['profileUid'] as List<dynamic>?)?.cast<String>() ?? [];
          final rawIsGroup = data['isGroup'] as bool?;
          final rawGroupName = data['groupName'];

          if (_isDirectConversation(data, participantProfiles) &&
              participantProfiles.contains(currentProfileId) &&
              participantProfiles.contains(otherProfileId)) {
            debugPrint('✅ MensagensNewDS: Conversa 1:1 existente encontrada');

            final conv = ConversationNewEntity.fromFirestore(matchedDoc);
            if (conv.isArchivedForProfile(currentProfileId)) {
              await unarchiveConversation(conv.id, currentProfileId);
            }

            final updates = <String, dynamic>{};
            final existingConvType = data['conversationType'] as String?;
            final existingDirectKey = (data['directConversationKey'] as String?)?.trim();

            if (existingConvType != 'direct') {
              updates['conversationType'] = 'direct';
            }
            if (rawIsGroup != false) updates['isGroup'] = false;
            if (rawGroupName != null) updates['groupName'] = FieldValue.delete();
            if (data['groupPhotoUrl'] != null) {
              updates['groupPhotoUrl'] = FieldValue.delete();
            }
            if (!participants.contains(currentUid) ||
                !participants.contains(otherUid)) {
              updates['participants'] =
                  FieldValue.arrayUnion([currentUid, otherUid]);
            }
            if (!profileUid.contains(currentUid) ||
                !profileUid.contains(otherUid)) {
              updates['profileUid'] =
                  FieldValue.arrayUnion([currentUid, otherUid]);
            }
            if (existingDirectKey != directConversationKey) {
              updates['directConversationKey'] = directConversationKey;
            }

            if (updates.isNotEmpty) {
              debugPrint(
                  '🛡️ MensagensNewDS: Self-healing 1:1 (atualizando flags/participantes)');
              await matchedDoc.reference.update(updates);
            }

            return conv.copyWith(isGroup: false);
          }
        }
      }

      // Criar nova conversa
      // ------------------------------------------------------------------
      // DocId determinístico = directConversationKey.
      // Garante idempotência: duas criações simultâneas convergem para o
      // mesmo documento (impossível criar duplicatas por construção).
      // Conversas antigas com IDs aleatórios continuam sendo encontradas
      // pelos lookups acima (directConversationKey field + legacy scan).
      // ------------------------------------------------------------------
      debugPrint('📝 MensagensNewDS: Criando nova conversa');
      final newConvRef = _conversationsRef.doc(directConversationKey);

      // Race-safe re-check: outro dispositivo/chamada pode ter criado o doc
      // nesta chave entre o lookup inicial e agora. Se existir, reaproveitamos.
      //
      // ⚠️ Firestore rules: ler um doc INEXISTENTE com a regra
      // `allow read: if resource.data.participants != null ...` retorna
      // `permission-denied` porque `resource` é null. Tratamos esse caso
      // como "doc não existe" e seguimos para a criação.
      DocumentSnapshot<Map<String, dynamic>>? existingByKey;
      try {
        existingByKey = await newConvRef.get();
      } on FirebaseException catch (error) {
        if (error.code == 'permission-denied') {
          debugPrint(
              'ℹ️ MensagensNewDS: get() determinístico negado (doc provavelmente inexistente), prosseguindo para create');
          existingByKey = null;
        } else {
          rethrow;
        }
      }

      if (existingByKey != null && existingByKey.exists) {
        debugPrint(
            '✅ MensagensNewDS: Conversa já existe em docId determinístico, reusando');
        final conv = ConversationNewEntity.fromFirestore(existingByKey);
        if (conv.isArchivedForProfile(currentProfileId)) {
          await unarchiveConversation(conv.id, currentProfileId);
        }
        return conv;
      }

      final now = DateTime.now();

      final newConv = ConversationNewEntity(
        id: newConvRef.id,
        participants: [currentUid, otherUid],
        participantProfiles: [currentProfileId, otherProfileId],
        lastMessage: '',
        lastMessageTimestamp: now,
        unreadCount: {currentProfileId: 0, otherProfileId: 0},
        createdAt: now,
        isGroup: false, // Explicitamente marcar como conversa 1:1
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

      // SetOptions(merge:true) torna o set idempotente: se duas chamadas
      // simultâneas passarem pelo re-check acima e criarem ao mesmo tempo,
      // ambas convergem para os mesmos dados base sem sobrescrita destrutiva.
      await newConvRef.set(
        {
          ...newConv.toFirestore(),
          // Adicionar profileUid para security rules
          'profileUid': [currentUid, otherUid],
          'directConversationKey': directConversationKey,
        },
        SetOptions(merge: true),
      );

      debugPrint(
          '✅ MensagensNewDS: Nova conversa criada - id=${newConvRef.id} (determinístico)');
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
        'lastMessageStatus': MessageDeliveryStatus.sent.name,
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
        'lastMessageStatus': MessageDeliveryStatus.sent.name,
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
  Future<MessageNewEntity> sendSharedPostMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required Map<String, dynamic> postData,
    String? senderName,
    String? senderPhotoUrl,
  }) async {
    try {
      debugPrint('📤 MensagensNewDS: sendSharedPostMessage - conv=$conversationId');

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
        text: '📌 Compartilhou um post',
        type: MessageType.sharedPost,
        status: MessageDeliveryStatus.sent,
        createdAt: now,
        metadata: postData,
      );

      batch.set(messageRef, message.toFirestore());

      // Atualizar conversa
      final convRef = _conversationsRef.doc(conversationId);
      final convDoc = await convRef.get();
      final participantProfiles =
          (convDoc.data()?['participantProfiles'] as List<dynamic>?)
                  ?.cast<String>() ??
              [];

      final updates = <String, dynamic>{
        'lastMessage': message.preview,
        'lastMessageTimestamp': Timestamp.fromDate(now),
        'lastMessageSenderId': senderProfileId,
        'lastMessageStatus': MessageDeliveryStatus.sent.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'deletedByProfiles': <String>[],
        'archivedByProfiles': <String>[],
      };

      for (final profileId in participantProfiles) {
        if (profileId != senderProfileId) {
          updates['unreadCount.$profileId'] = FieldValue.increment(1);
        }
      }

      batch.update(convRef, updates);

      // Incrementar forwardCount no post original
      final postId = postData['postId'] as String?;
      if (postId != null && postId.isNotEmpty) {
        final postRef = _firestore.collection('posts').doc(postId);
        batch.update(postRef, {'forwardCount': FieldValue.increment(1)});
      }

      await batch.commit();

      debugPrint('✅ MensagensNewDS: Post compartilhado enviado - id=${messageRef.id}');
      return message;
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em sendSharedPostMessage - $e');
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
      final convRef = _conversationsRef.doc(conversationId);
      final convSnapshot = await convRef.get();
      final convData = convSnapshot.data();
      final isGroup = (convData?['isGroup'] as bool?) ?? false;
      final lastSenderId = convData?['lastMessageSenderId'] as String?;

      final updates = <String, dynamic>{
        'unreadCount.$profileId': 0,
      };

      // Atualiza indicador de leitura da última mensagem (para o remetente ver o check azul)
      if (!isGroup && lastSenderId != null && lastSenderId != profileId) {
        updates['lastMessageStatus'] = MessageDeliveryStatus.read.name;
      }

      await convRef.update(updates);

      // Mantém consistência com o badge do ícone do app:
      // A Cloud Function agrega notificações `newMessage` por conversa, então ao
      // ler a conversa precisamos marcar esse doc como `read: true`.
      // Best-effort (non-critical): se falhar, o app ainda funciona.
      try {
        // 🔒 IMPORTANT (Firestore Rules): queries em `notifications` precisam filtrar por
        // `recipientUid == auth.uid`. Como este método recebe só `profileId`, resolvemos
        // o UID via `profiles/{profileId}` (leitura pública permitida).
        final profileSnap = await _firestore.collection('profiles').doc(profileId).get();
        final recipientUid = (profileSnap.data()?['uid'] as String?)?.trim();

        if (recipientUid == null || recipientUid.isEmpty) {
          debugPrint(
            '⚠️ MensagensNewDS: Não foi possível resolver recipientUid para profileId=$profileId; skip marcar notificação newMessage como lida',
          );
        } else {
          // Evita query com múltiplos filtros (índice composto). Fazemos uma query "barata"
          // compatível com rules e filtramos client-side.
          QuerySnapshot<Map<String, dynamic>> unreadSnap;
          try {
            unreadSnap = await _firestore
                .collection('notifications')
                .where('recipientUid', isEqualTo: recipientUid)
                .where('read', isEqualTo: false)
                .limit(100)
                .get(const GetOptions(source: Source.server));
          } catch (e) {
            debugPrint(
              '⚠️ MensagensNewDS: Falha ao buscar notificações no server; usando cache: $e',
            );
            unreadSnap = await _firestore
                .collection('notifications')
                .where('recipientUid', isEqualTo: recipientUid)
                .where('read', isEqualTo: false)
                .limit(100)
                .get(const GetOptions(source: Source.cache));
          }

          final toMarkRead = unreadSnap.docs.where((doc) {
            final data = doc.data();
            if ((data['recipientProfileId'] as String?) != profileId) return false;
            if ((data['type'] as String?) != 'newMessage') return false;

            final payload = data['data'];
            if (payload is! Map<String, dynamic>) return false;
            if ((payload['conversationId'] as String?) != conversationId) return false;

            return true;
          }).toList(growable: false);

          if (toMarkRead.isNotEmpty) {
            final batch = _firestore.batch();
            for (final doc in toMarkRead) {
              batch.update(doc.reference, {'read': true});
            }
            await batch.commit();
            debugPrint(
              '✅ MensagensNewDS: ${toMarkRead.length} notificação(ões) newMessage marcada(s) como lida (conv=$conversationId)',
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ MensagensNewDS: Falha ao marcar notificação newMessage como lida (non-critical): $e');
      }

      if (isGroup) {
        debugPrint('ℹ️ MensagensNewDS: markAsRead ignorou batch (grupo)');
        return;
      }

      // Marcar as últimas mensagens recebidas como lidas (para read receipts nos bubbles)
      final messagesSnapshot = await _messagesRef(conversationId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      debugPrint('📨 MensagensNewDS: Encontradas ${messagesSnapshot.docs.length} mensagens para analisar');

      final batch = _firestore.batch();
      var updatedCount = 0;

      for (final doc in messagesSnapshot.docs) {
        final data = doc.data();
        final senderProfileId =
            (data['senderProfileId'] as String?) ?? (data['senderId'] as String?) ?? '';
        final statusStr = (data['status'] as String?) ?? MessageDeliveryStatus.sent.name;
        final status = MessageDeliveryStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () => MessageDeliveryStatus.sent,
        );

        debugPrint('📝 MensagensNewDS: msg=${doc.id}, sender=$senderProfileId, currentStatus=$status, myProfileId=$profileId');

        // Apenas mensagens do outro participante precisam ser marcadas como lidas
        if (senderProfileId == profileId) {
          debugPrint('   ⏭️ Pulando: sou o remetente');
          continue;
        }
        if (status == MessageDeliveryStatus.read) {
          debugPrint('   ⏭️ Pulando: já está read');
          continue;
        }

        debugPrint('   ✏️ Marcando como read');
        batch.update(doc.reference, {
          'status': MessageDeliveryStatus.read.name,
        });

        updatedCount++;
        if (updatedCount >= 20) break; // evitar batches muito grandes
      }

      if (updatedCount > 0) {
        try {
          await batch.commit();
          debugPrint('✅ MensagensNewDS: $updatedCount mensagens marcadas como lidas (status=read)');
        } catch (batchError) {
          debugPrint('❌ MensagensNewDS: Erro ao commit batch de status read - $batchError');
          // Não propagar - atualização de read receipt não é crítica
        }
      } else {
        debugPrint('ℹ️ MensagensNewDS: Nenhuma mensagem precisou ser marcada como lida');
      }

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
  Future<void> markGroupMessagesAsReceived(String conversationId, String profileId) async {
    try {
      debugPrint('📥 MensagensNewDS: markGroupMessagesAsReceived - conv=$conversationId, profile=$profileId');

      // Buscar últimas mensagens que não são do próprio usuário
      final messagesSnapshot = await _messagesRef(conversationId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final batch = _firestore.batch();
      var updatedCount = 0;

      for (final doc in messagesSnapshot.docs) {
        final data = doc.data();
        final senderProfileId = (data['senderProfileId'] as String?) ?? '';
        
        // Pular mensagens próprias
        if (senderProfileId == profileId) continue;
        
        // Verificar se já está na lista de receivedBy
        final receivedBy = (data['receivedBy'] as List<dynamic>?)?.cast<String>() ?? [];
        if (receivedBy.contains(profileId)) continue;

        // Adicionar profileId à lista receivedBy
        batch.update(doc.reference, {
          'receivedBy': FieldValue.arrayUnion([profileId]),
        });
        updatedCount++;
        
        if (updatedCount >= 20) break; // Limitar batch
      }

      if (updatedCount > 0) {
        await batch.commit();
        debugPrint('✅ MensagensNewDS: $updatedCount mensagens marcadas como recebidas pelo perfil $profileId');
      } else {
        debugPrint('ℹ️ MensagensNewDS: Nenhuma mensagem precisou ser marcada como recebida');
      }
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em markGroupMessagesAsReceived - $e');
      // Não propagar - não é crítico
    }
  }

  @override
  Future<void> markGroupMessagesAsRead(String conversationId, String profileId) async {
    try {
      debugPrint('👁️ MensagensNewDS: markGroupMessagesAsRead - conv=$conversationId, profile=$profileId');

      // Primeiro atualiza o unreadCount
      await _conversationsRef.doc(conversationId).update({
        'unreadCount.$profileId': 0,
      });

      // Buscar últimas mensagens que não são do próprio usuário
      final messagesSnapshot = await _messagesRef(conversationId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final batch = _firestore.batch();
      var updatedCount = 0;

      for (final doc in messagesSnapshot.docs) {
        final data = doc.data();
        final senderProfileId = (data['senderProfileId'] as String?) ?? '';
        
        // Pular mensagens próprias
        if (senderProfileId == profileId) continue;
        
        // Verificar se já está na lista de readBy
        final readBy = (data['readBy'] as List<dynamic>?)?.cast<String>() ?? [];
        if (readBy.contains(profileId)) continue;

        // Adicionar profileId às listas receivedBy e readBy (read implica received)
        batch.update(doc.reference, {
          'receivedBy': FieldValue.arrayUnion([profileId]),
          'readBy': FieldValue.arrayUnion([profileId]),
        });
        updatedCount++;
        
        if (updatedCount >= 20) break; // Limitar batch
      }

      if (updatedCount > 0) {
        await batch.commit();
        debugPrint('✅ MensagensNewDS: $updatedCount mensagens marcadas como lidas pelo perfil $profileId');
        
        // Atualizar lastMessageStatus se todas as mensagens foram lidas
        // Busca a conversa para verificar se todos leram
        await _updateGroupLastMessageStatus(conversationId);
      } else {
        debugPrint('ℹ️ MensagensNewDS: Nenhuma mensagem precisou ser marcada como lida no grupo');
      }
    } catch (e) {
      debugPrint('❌ MensagensNewDS: Erro em markGroupMessagesAsRead - $e');
      // Não propagar - não é crítico
    }
  }

  /// Atualiza o lastMessageStatus da conversa de grupo baseado em quem leu/recebeu
  Future<void> _updateGroupLastMessageStatus(String conversationId) async {
    try {
      final convSnapshot = await _conversationsRef.doc(conversationId).get();
      final convData = convSnapshot.data();
      if (convData == null) return;

      final participantProfiles = (convData['participantProfiles'] as List<dynamic>?)?.cast<String>() ?? [];
      final lastSenderId = convData['lastMessageSenderId'] as String?;
      
      if (lastSenderId == null || participantProfiles.length < 2) return;

      // IDs dos outros participantes (exceto o remetente)
      final otherParticipants = participantProfiles.where((id) => id != lastSenderId).toList();
      if (otherParticipants.isEmpty) return;

      // Buscar última mensagem
      final lastMessageSnapshot = await _messagesRef(conversationId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (lastMessageSnapshot.docs.isEmpty) return;

      final lastMessageData = lastMessageSnapshot.docs.first.data();
      final readBy = (lastMessageData['readBy'] as List<dynamic>?)?.cast<String>() ?? [];
      final receivedBy = (lastMessageData['receivedBy'] as List<dynamic>?)?.cast<String>() ?? [];

      // Verifica se TODOS os outros participantes leram
      final allRead = otherParticipants.every((id) => readBy.contains(id));
      if (allRead) {
        await _conversationsRef.doc(conversationId).update({
          'lastMessageStatus': MessageDeliveryStatus.read.name,
        });
        debugPrint('✅ MensagensNewDS: lastMessageStatus atualizado para read (todos leram)');
        return;
      }

      // Verifica se TODOS os outros participantes receberam
      final allReceived = otherParticipants.every((id) => receivedBy.contains(id));
      if (allReceived) {
        await _conversationsRef.doc(conversationId).update({
          'lastMessageStatus': MessageDeliveryStatus.delivered.name,
        });
        debugPrint('✅ MensagensNewDS: lastMessageStatus atualizado para delivered (todos receberam)');
        return;
      }

      // Se nem todos receberam, mantém como sent
      await _conversationsRef.doc(conversationId).update({
        'lastMessageStatus': MessageDeliveryStatus.sent.name,
      });
    } catch (e) {
      debugPrint('⚠️ MensagensNewDS: Erro ao atualizar lastMessageStatus do grupo - $e');
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
    // Buscamos mais resultados que o limite para evitar perda de 1:1
    // após filtros client-side (arquivadas/deletadas/bloqueios).
    final fetchLimit = limit * 5;

    return _conversationsRef
      .where('participants', arrayContains: profileUid)
      .orderBy('lastMessageTimestamp', descending: true)
      .limit(fetchLimit)
        .snapshots()
        .asyncMap((snapshot) async {
      debugPrint('📨 MensagensNewDS: watchConversations snapshot com ${snapshot.docs.length} docs');

      // Best-effort: normaliza conversas legadas para reduzir conflitos grupo vs 1:1.
      // Isso roda uma vez por conversa (após normalizar, não haverá novo update).
      await _normalizeLegacyConversationsIfNeeded(
        docs: snapshot.docs,
        profileId: profileId,
      );
      
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
          .toList();

      // Ordenar: fixadas primeiro, depois por timestamp
      conversations.sort((a, b) {
        final aPinned = a.isPinnedForProfile(profileId);
        final bPinned = b.isPinnedForProfile(profileId);
        if (aPinned && !bPinned) return -1;
        if (!aPinned && bPinned) return 1;
        return b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp);
      });

      // Aplicar limite final após todos os filtros/ordenação
      if (conversations.length > limit) {
        conversations = conversations.take(limit).toList(growable: false);
      }

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
  /// 
  /// Para conversas 1:1: busca apenas o outro participante
  /// Para grupos: busca TODOS os participantes (exceto o atual)
  Future<List<ConversationNewEntity>> _enrichConversationsWithParticipants(
    List<ConversationNewEntity> conversations,
    String currentProfileId,
  ) async {
    if (conversations.isEmpty) return conversations;

    // Coletar todos os profileIds únicos de TODOS os participantes (exceto o atual)
    final allProfileIds = <String>{};
    for (final conv in conversations) {
      for (final profileId in conv.participantProfiles) {
        if (profileId != currentProfileId) {
          allProfileIds.add(profileId);
        }
      }
    }

    if (allProfileIds.isEmpty) return conversations;

    // Buscar dados dos perfis em batch
    final profilesData = <String, ParticipantData>{};
    
    // Firestore permite no máximo 10 IDs por whereIn
    final chunks = _chunkList(allProfileIds.toList(), 10);
    
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

    // Enriquecer conversas com dados de TODOS os participantes
    return conversations.map((conv) {
      final isGroup = conv.isGroup || conv.participantProfiles.length > 2;
      
      if (isGroup) {
        // Para grupos: incluir dados de TODOS os outros participantes
        final participants = <ParticipantData>[];
        for (final profileId in conv.participantProfiles) {
          if (profileId == currentProfileId) continue;
          final data = profilesData[profileId];
          if (data != null) {
            participants.add(data);
          }
        }
        return conv.copyWith(participantsData: participants);
      } else {
        // Para 1:1: apenas o outro participante
        final otherProfileId = conv.getOtherProfileId(currentProfileId);
        if (otherProfileId == null) return conv;

        final otherData = profilesData[otherProfileId];
        if (otherData == null) return conv;

        return conv.copyWith(participantsData: [otherData]);
      }
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
