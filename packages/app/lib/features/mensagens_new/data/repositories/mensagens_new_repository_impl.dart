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
  }) : _remoteDataSource = remoteDataSource;

  final IMensagensNewRemoteDataSource _remoteDataSource;

  // ============================================
  // CONVERSAS - CRUD
  // ============================================

  @override
  Future<List<ConversationNewEntity>> getConversations({
    required String profileId,
    required String profileUid,
    int limit = 20,
    bool includeArchived = false,
  }) {
    return _remoteDataSource.getConversations(
      profileId: profileId,
      profileUid: profileUid,
      limit: limit,
      includeArchived: includeArchived,
    );
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
  }) {
    return _remoteDataSource.getUnreadCount(profileId, profileUid);
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
    return _remoteDataSource.watchConversations(
      profileId: profileId,
      profileUid: profileUid,
      limit: limit,
      includeArchived: includeArchived,
    );
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
    return _remoteDataSource.watchUnreadCount(profileId, profileUid);
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
