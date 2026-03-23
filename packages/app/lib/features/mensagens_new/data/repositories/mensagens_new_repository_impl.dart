import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wegig_app/core/firebase/blocked_profiles.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/mensagens_new_repository.dart';
import '../datasources/mensagens_new_remote_datasource.dart';

/// Implementação do MensagensNewRepository
///
/// Faz ponte entre domain layer e data layer, delegando operações
/// para o datasource remoto (Firebase Firestore).
class MensagensNewRepositoryImpl implements MensagensNewRepository {
  /// Construtor com injeção de dependência do datasource
  MensagensNewRepositoryImpl({
    required IMensagensNewRemoteDataSource remoteDataSource,
    required FirebaseFirestore firestore,
  })  : _remoteDataSource = remoteDataSource,
        _firestore = firestore;

  final IMensagensNewRemoteDataSource _remoteDataSource;
  final FirebaseFirestore _firestore;

  // ============================================
  // CONVERSAS - CRUD
  // ============================================

  @override
  Future<List<ConversationNewEntity>> getConversations({
    required String profileId,
    required String profileUid,
    int limit = 20,
    bool includeArchived = false,
  }) async {
    final excluded = await BlockedRelations.getExcludedProfileIds(
      firestore: _firestore,
      profileId: profileId,
      uid: profileUid,
    );
    final excludedSet = excluded.toSet();

    final conversations = await _remoteDataSource.getConversations(
      profileId: profileId,
      profileUid: profileUid,
      limit: limit,
      includeArchived: includeArchived,
    );

    // Filtra conversas onde o outro participante está excluído (por profileId).
    return conversations
        .where((c) {
          final otherProfileId = c.getOtherProfileId(profileId);
          if (otherProfileId == null || otherProfileId.isEmpty) return true;
          return !excludedSet.contains(otherProfileId);
        })
        .toList(growable: false);
  }

  @override
  Future<ConversationNewEntity?> getConversationById(String conversationId) {
    return _remoteDataSource.getConversationById(conversationId);
  }

  @override
  Future<ConversationNewEntity> getOrCreateConversation({
    required String currentProfileId,
    required String currentUid,
    required String otherProfileId,
    required String otherUid,
    Map<String, dynamic>? currentProfileData,
    Map<String, dynamic>? otherProfileData,
  }) {
    return _getOrCreateConversationGuarded(
      currentProfileId: currentProfileId,
      currentUid: currentUid,
      otherProfileId: otherProfileId,
      otherUid: otherUid,
      currentProfileData: currentProfileData,
      otherProfileData: otherProfileData,
    );
  }

  Future<ConversationNewEntity> _getOrCreateConversationGuarded({
    required String currentProfileId,
    required String currentUid,
    required String otherProfileId,
    required String otherUid,
    Map<String, dynamic>? currentProfileData,
    Map<String, dynamic>? otherProfileData,
  }) async {
    final excluded = await BlockedRelations.getExcludedProfileIds(
      firestore: _firestore,
      profileId: currentProfileId,
      uid: currentUid,
    );
    if (excluded.contains(otherProfileId)) {
      throw StateError('Conversa indisponível');
    }

    return _remoteDataSource.getOrCreateConversation(
      currentProfileId: currentProfileId,
      currentUid: currentUid,
      otherProfileId: otherProfileId,
      otherUid: otherUid,
      currentProfileData: currentProfileData,
      otherProfileData: otherProfileData,
    );
  }

  @override
  Future<void> archiveConversation({
    required String conversationId,
    required String profileId,
  }) {
    return _remoteDataSource.archiveConversation(conversationId, profileId);
  }

  @override
  Future<void> unarchiveConversation({
    required String conversationId,
    required String profileId,
  }) {
    return _remoteDataSource.unarchiveConversation(conversationId, profileId);
  }

  @override
  Future<void> deleteConversation({
    required String conversationId,
    required String profileId,
  }) {
    return _remoteDataSource.deleteConversation(conversationId, profileId);
  }

  @override
  Future<void> togglePinConversation({
    required String conversationId,
    required String profileId,
    required bool isPinned,
  }) {
    return _remoteDataSource.togglePinConversation(
        conversationId, profileId, isPinned);
  }

  @override
  Future<void> toggleMuteConversation({
    required String conversationId,
    required String profileId,
    required bool isMuted,
  }) {
    return _remoteDataSource.toggleMuteConversation(
        conversationId, profileId, isMuted);
  }

  // ============================================
  // MENSAGENS - CRUD
  // ============================================

  @override
  Future<List<MessageNewEntity>> getMessages({
    required String conversationId,
    int limit = 50,
    MessageNewEntity? startAfter,
    DateTime? clearHistoryAfter,
  }) {
    return _remoteDataSource.getMessages(
      conversationId: conversationId,
      limit: limit,
      startAfter: startAfter,
      clearHistoryAfter: clearHistoryAfter,
    );
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
  }) {
    return _remoteDataSource.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderProfileId: senderProfileId,
      text: text,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      replyTo: replyTo,
    );
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
  }) {
    return _remoteDataSource.sendImageMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderProfileId: senderProfileId,
      imageUrl: imageUrl,
      text: text,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      replyTo: replyTo,
    );
  }

  @override
  Future<MessageNewEntity> sendSharedPostMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required Map<String, dynamic> postData,
    String? senderName,
    String? senderPhotoUrl,
  }) {
    return _remoteDataSource.sendSharedPostMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderProfileId: senderProfileId,
      postData: postData,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
    );
  }

  @override
  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String newText,
  }) {
    return _remoteDataSource.editMessage(conversationId, messageId, newText);
  }

  @override
  Future<void> deleteMessageForMe({
    required String conversationId,
    required String messageId,
    required String profileId,
  }) {
    return _remoteDataSource.deleteMessageForMe(
        conversationId, messageId, profileId);
  }

  @override
  Future<void> deleteMessageForEveryone({
    required String conversationId,
    required String messageId,
  }) {
    return _remoteDataSource.deleteMessageForEveryone(conversationId, messageId);
  }

  // ============================================
  // REAÇÕES
  // ============================================

  @override
  Future<void> addReaction({
    required String conversationId,
    required String messageId,
    required String profileId,
    required String emoji,
  }) {
    return _remoteDataSource.addReaction(
        conversationId, messageId, profileId, emoji);
  }

  @override
  Future<void> removeReaction({
    required String conversationId,
    required String messageId,
    required String profileId,
  }) {
    return _remoteDataSource.removeReaction(conversationId, messageId, profileId);
  }

  // ============================================
  // STATUS DE LEITURA
  // ============================================

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String profileId,
  }) {
    return _remoteDataSource.markAsRead(conversationId, profileId);
  }

  @override
  Future<void> markAsUnread({
    required String conversationId,
    required String profileId,
  }) {
    return _remoteDataSource.markAsUnread(conversationId, profileId);
  }

  @override
  Future<void> updateMessageStatus({
    required String conversationId,
    required String messageId,
    required MessageDeliveryStatus status,
  }) {
    return _remoteDataSource.updateMessageStatus(
        conversationId, messageId, status);
  }

  // ============================================
  // STATUS PARA GRUPOS
  // ============================================

  @override
  Future<void> markGroupMessagesAsReceived({
    required String conversationId,
    required String profileId,
  }) {
    return _remoteDataSource.markGroupMessagesAsReceived(conversationId, profileId);
  }

  @override
  Future<void> markGroupMessagesAsRead({
    required String conversationId,
    required String profileId,
  }) {
    return _remoteDataSource.markGroupMessagesAsRead(conversationId, profileId);
  }

  // ============================================
  // INDICADOR DE DIGITAÇÃO
  // ============================================

  @override
  Future<void> updateTypingIndicator({
    required String conversationId,
    required String profileId,
    required bool isTyping,
  }) {
    return _remoteDataSource.updateTypingIndicator(
        conversationId, profileId, isTyping);
  }

  // ============================================
  // CONTADORES
  // ============================================

  @override
  Future<int> getUnreadCount({
    required String profileId,
    required String profileUid,
  }) async {
    // Mantém semântica de contagem por conversa (não total de mensagens),
    // mas filtrando relações excluídas (bloqueios em ambos os sentidos por profileId).
    final excluded = await BlockedRelations.getExcludedProfileIds(
      firestore: _firestore,
      profileId: profileId,
      uid: profileUid,
    );
    final excludedSet = excluded.toSet();

    final snapshot = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: profileUid)
        .get();

    var unreadConversations = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();

      final participantProfiles =
          (data['participantProfiles'] as List<dynamic>?)?.cast<String>() ?? [];
      if (!participantProfiles.contains(profileId)) continue;

      final deletedBy =
          (data['deletedByProfiles'] as List<dynamic>?)?.cast<String>() ?? [];
      if (deletedBy.contains(profileId)) continue;

      final archivedBy =
          (data['archivedByProfiles'] as List<dynamic>?)?.cast<String>() ?? [];
      if (archivedBy.contains(profileId)) continue;

      // Filter by otherProfileId instead of otherUid
      final otherProfileId = participantProfiles.firstWhere(
        (p) => p != profileId,
        orElse: () => '',
      );
      if (otherProfileId.isNotEmpty && excludedSet.contains(otherProfileId)) continue;

      final unreadCount = (data['unreadCount'] as Map<String, dynamic>?) ?? {};
      final countForProfile = (unreadCount[profileId] as num?)?.toInt() ?? 0;
      if (countForProfile > 0) unreadConversations++;
    }

    return unreadConversations;
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
    final conversations$ = _remoteDataSource.watchConversations(
      profileId: profileId,
      profileUid: profileUid,
      limit: limit,
      includeArchived: includeArchived,
    );
    final excluded$ = BlockedRelations.watchExcludedProfileIds(
      firestore: _firestore,
      profileId: profileId,
      uid: profileUid,
    ).onErrorReturn(const <String>[]);

    return Rx.combineLatest2<List<ConversationNewEntity>, List<String>, List<ConversationNewEntity>>(
      conversations$,
      excluded$,
      (conversations, excluded) {
        final excludedSet = excluded.toSet();
        return conversations
            .where((c) {
              // Bloqueio só faz sentido para 1:1. Em grupo, não filtra pela presença de um bloqueado.
              if (c.isGroup || c.participantProfiles.length > 2) return true;

              final otherProfileId = c.getOtherProfileId(profileId);
              if (otherProfileId == null || otherProfileId.isEmpty) return true;
              return !excludedSet.contains(otherProfileId);
            })
            .toList(growable: false);
      },
    ).distinct(listEquals);
  }

  @override
  Stream<List<MessageNewEntity>> watchMessages({
    required String conversationId,
    int limit = 50,
    DateTime? clearHistoryAfter,
  }) {
    return _remoteDataSource.watchMessages(
      conversationId,
      limit: limit,
      clearHistoryAfter: clearHistoryAfter,
    );
  }

  @override
  Stream<int> watchUnreadCount({
    required String profileId,
    required String profileUid,
  }) {
    // Deriva a contagem a partir da lista de conversas já filtrada,
    // para garantir que bloqueios em ambos os sentidos sejam respeitados.
    return watchConversations(
      profileId: profileId,
      profileUid: profileUid,
      limit: 200,
      includeArchived: false,
    )
        .map((conversations) => conversations.where((c) => c.hasUnreadMessages(profileId)).length)
        .distinct();
  }

  @override
  Stream<Map<String, DateTime>> watchTypingIndicators({
    required String conversationId,
  }) {
    return _remoteDataSource.watchTypingIndicators(conversationId);
  }

  @override
  Stream<ConversationNewEntity?> watchConversation({
    required String conversationId,
  }) {
    return _remoteDataSource.watchConversation(conversationId);
  }
}
