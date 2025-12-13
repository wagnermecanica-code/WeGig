import '../entities/entities.dart';

/// Repository abstrato para operações de mensagens - Nova implementação
///
/// Define contratos para todas as operações de chat:
/// - CRUD de conversas
/// - CRUD de mensagens
/// - Reações e edições
/// - Streams em tempo real
/// - Indicador de digitação
abstract class MensagensNewRepository {
  // ============================================
  // CONVERSAS - CRUD
  // ============================================

  /// Obtém lista de conversas do perfil
  ///
  /// [profileId] ID do perfil ativo
  /// [profileUid] UID do usuário (para security rules)
  /// [limit] Limite de conversas por página
  /// [includeArchived] Se deve incluir conversas arquivadas
  Future<List<ConversationNewEntity>> getConversations({
    required String profileId,
    required String profileUid,
    int limit = 20,
    bool includeArchived = false,
  });

  /// Obtém uma conversa específica por ID
  Future<ConversationNewEntity?> getConversationById(String conversationId);

  /// Obtém ou cria conversa entre dois perfis
  ///
  /// Se já existe conversa entre os perfis, retorna a existente.
  /// Caso contrário, cria uma nova.
  Future<ConversationNewEntity> getOrCreateConversation({
    required String currentProfileId,
    required String currentUid,
    required String otherProfileId,
    required String otherUid,
    Map<String, dynamic>? currentProfileData,
    Map<String, dynamic>? otherProfileData,
  });

  /// Arquiva uma conversa para o perfil
  Future<void> archiveConversation({
    required String conversationId,
    required String profileId,
  });

  /// Desarquiva uma conversa para o perfil
  Future<void> unarchiveConversation({
    required String conversationId,
    required String profileId,
  });

  /// Deleta (oculta) uma conversa para o perfil
  Future<void> deleteConversation({
    required String conversationId,
    required String profileId,
  });

  /// Fixa/desfixa uma conversa para o perfil
  Future<void> togglePinConversation({
    required String conversationId,
    required String profileId,
    required bool isPinned,
  });

  /// Silencia/dessilencia notificações de uma conversa
  Future<void> toggleMuteConversation({
    required String conversationId,
    required String profileId,
    required bool isMuted,
  });

  // ============================================
  // MENSAGENS - CRUD
  // ============================================

  /// Obtém mensagens de uma conversa com paginação
  /// 
  /// [clearHistoryAfter] Se definido, filtra mensagens para mostrar apenas
  /// as que foram criadas APÓS este timestamp (usado quando usuário deletou conversa)
  Future<List<MessageNewEntity>> getMessages({
    required String conversationId,
    int limit = 50,
    MessageNewEntity? startAfter,
    DateTime? clearHistoryAfter,
  });

  /// Envia uma mensagem de texto
  Future<MessageNewEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String text,
    String? senderName,
    String? senderPhotoUrl,
    MessageReplyData? replyTo,
  });

  /// Envia uma mensagem com imagem
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

  /// Edita uma mensagem existente
  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String newText,
  });

  /// Deleta mensagem "para mim" (soft delete)
  Future<void> deleteMessageForMe({
    required String conversationId,
    required String messageId,
    required String profileId,
  });

  /// Deleta mensagem "para todos"
  Future<void> deleteMessageForEveryone({
    required String conversationId,
    required String messageId,
  });

  // ============================================
  // REAÇÕES
  // ============================================

  /// Adiciona ou atualiza reação em uma mensagem
  Future<void> addReaction({
    required String conversationId,
    required String messageId,
    required String profileId,
    required String emoji,
  });

  /// Remove reação de uma mensagem
  Future<void> removeReaction({
    required String conversationId,
    required String messageId,
    required String profileId,
  });

  // ============================================
  // STATUS DE LEITURA
  // ============================================

  /// Marca conversa como lida para o perfil
  Future<void> markAsRead({
    required String conversationId,
    required String profileId,
  });

  /// Marca conversa como não lida para o perfil
  Future<void> markAsUnread({
    required String conversationId,
    required String profileId,
  });

  /// Atualiza status de entrega de uma mensagem
  Future<void> updateMessageStatus({
    required String conversationId,
    required String messageId,
    required MessageDeliveryStatus status,
  });

  // ============================================
  // INDICADOR DE DIGITAÇÃO
  // ============================================

  /// Atualiza indicador de digitação
  Future<void> updateTypingIndicator({
    required String conversationId,
    required String profileId,
    required bool isTyping,
  });

  // ============================================
  // CONTADORES
  // ============================================

  /// Obtém contagem total de mensagens não lidas
  Future<int> getUnreadCount({
    required String profileId,
    required String profileUid,
  });

  // ============================================
  // STREAMS EM TEMPO REAL
  // ============================================

  /// Stream de conversas em tempo real
  Stream<List<ConversationNewEntity>> watchConversations({
    required String profileId,
    required String profileUid,
    int limit = 20,
    bool includeArchived = false,
  });

  /// Stream de mensagens em tempo real
  /// 
  /// [clearHistoryAfter] Se definido, filtra mensagens para mostrar apenas
  /// as que foram criadas APÓS este timestamp (usado quando usuário deletou conversa)
  Stream<List<MessageNewEntity>> watchMessages({
    required String conversationId,
    int limit = 50,
    DateTime? clearHistoryAfter,
  });

  /// Stream de contagem de não lidas
  Stream<int> watchUnreadCount({
    required String profileId,
    required String profileUid,
  });

  /// Stream de indicador de digitação
  Stream<Map<String, DateTime>> watchTypingIndicators({
    required String conversationId,
  });

  /// Stream de uma conversa específica (para updates de typing, etc)
  Stream<ConversationNewEntity?> watchConversation({
    required String conversationId,
  });
}
