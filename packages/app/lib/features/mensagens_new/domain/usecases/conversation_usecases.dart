import '../entities/entities.dart';
import '../repositories/mensagens_new_repository.dart';

/// Use Case: Carregar conversas
///
/// Carrega lista de conversas do perfil ativo com paginação.
class LoadConversationsNewUseCase {
  LoadConversationsNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<List<ConversationNewEntity>> call({
    required String profileId,
    required String profileUid,
    int limit = 20,
    bool includeArchived = false,
  }) {
    return _repository.getConversations(
      profileId: profileId,
      profileUid: profileUid,
      limit: limit,
      includeArchived: includeArchived,
    );
  }
}

/// Use Case: Obter ou criar conversa
///
/// Obtém uma conversa existente entre dois perfis ou cria uma nova.
/// Útil para iniciar chat a partir de um perfil/post.
class GetOrCreateConversationNewUseCase {
  GetOrCreateConversationNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<ConversationNewEntity> call({
    required String currentProfileId,
    required String currentUid,
    required String otherProfileId,
    required String otherUid,
    Map<String, dynamic>? currentProfileData,
    Map<String, dynamic>? otherProfileData,
  }) {
    return _repository.getOrCreateConversation(
      currentProfileId: currentProfileId,
      currentUid: currentUid,
      otherProfileId: otherProfileId,
      otherUid: otherUid,
      currentProfileData: currentProfileData,
      otherProfileData: otherProfileData,
    );
  }
}

/// Use Case: Arquivar conversa
///
/// Arquiva uma conversa para o perfil. A conversa não aparecerá
/// mais na lista principal, mas pode ser acessada na lista de arquivadas.
class ArchiveConversationNewUseCase {
  ArchiveConversationNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<void> call({
    required String conversationId,
    required String profileId,
  }) {
    return _repository.archiveConversation(
      conversationId: conversationId,
      profileId: profileId,
    );
  }
}

/// Use Case: Desarquivar conversa
///
/// Remove a conversa da lista de arquivadas, voltando para a lista principal.
class UnarchiveConversationNewUseCase {
  UnarchiveConversationNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<void> call({
    required String conversationId,
    required String profileId,
  }) {
    return _repository.unarchiveConversation(
      conversationId: conversationId,
      profileId: profileId,
    );
  }
}

/// Use Case: Deletar conversa
///
/// Deleta (oculta) uma conversa para o perfil.
/// Na prática, arquiva a conversa e zera o contador de não lidas.
class DeleteConversationNewUseCase {
  DeleteConversationNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<void> call({
    required String conversationId,
    required String profileId,
  }) {
    return _repository.deleteConversation(
      conversationId: conversationId,
      profileId: profileId,
    );
  }
}

/// Use Case: Fixar/desficar conversa
///
/// Fixa uma conversa no topo da lista ou remove a fixação.
class TogglePinConversationNewUseCase {
  TogglePinConversationNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<void> call({
    required String conversationId,
    required String profileId,
    required bool isPinned,
  }) {
    return _repository.togglePinConversation(
      conversationId: conversationId,
      profileId: profileId,
      isPinned: isPinned,
    );
  }
}

/// Use Case: Silenciar/dessilenciar conversa
///
/// Silencia notificações de uma conversa ou reativa.
class ToggleMuteConversationNewUseCase {
  ToggleMuteConversationNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<void> call({
    required String conversationId,
    required String profileId,
    required bool isMuted,
  }) {
    return _repository.toggleMuteConversation(
      conversationId: conversationId,
      profileId: profileId,
      isMuted: isMuted,
    );
  }
}

/// Use Case: Marcar conversa como lida
///
/// Zera o contador de não lidas para o perfil.
class MarkAsReadNewUseCase {
  MarkAsReadNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<void> call({
    required String conversationId,
    required String profileId,
  }) {
    return _repository.markAsRead(
      conversationId: conversationId,
      profileId: profileId,
    );
  }
}

/// Use Case: Marcar conversa como não lida
///
/// Define o contador de não lidas como 1 para o perfil.
class MarkAsUnreadNewUseCase {
  MarkAsUnreadNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<void> call({
    required String conversationId,
    required String profileId,
  }) {
    return _repository.markAsUnread(
      conversationId: conversationId,
      profileId: profileId,
    );
  }
}

/// Use Case: Atualizar indicador de digitação
///
/// Atualiza o status de "digitando..." na conversa.
class UpdateTypingIndicatorNewUseCase {
  UpdateTypingIndicatorNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<void> call({
    required String conversationId,
    required String profileId,
    required bool isTyping,
  }) {
    return _repository.updateTypingIndicator(
      conversationId: conversationId,
      profileId: profileId,
      isTyping: isTyping,
    );
  }
}

/// Use Case: Watch conversas em tempo real
///
/// Retorna um Stream de conversas para updates em tempo real.
class WatchConversationsNewUseCase {
  WatchConversationsNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Stream<List<ConversationNewEntity>> call({
    required String profileId,
    required String profileUid,
    int limit = 20,
    bool includeArchived = false,
  }) {
    return _repository.watchConversations(
      profileId: profileId,
      profileUid: profileUid,
      limit: limit,
      includeArchived: includeArchived,
    );
  }
}

/// Use Case: Watch contagem de não lidas
///
/// Retorna um Stream com a contagem total de mensagens não lidas.
class WatchUnreadCountNewUseCase {
  WatchUnreadCountNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Stream<int> call({
    required String profileId,
    required String profileUid,
  }) {
    return _repository.watchUnreadCount(
      profileId: profileId,
      profileUid: profileUid,
    );
  }
}

/// Use Case: Watch indicadores de digitação
///
/// Retorna um Stream com os indicadores de digitação da conversa.
class WatchTypingIndicatorsNewUseCase {
  WatchTypingIndicatorsNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Stream<Map<String, DateTime>> call({
    required String conversationId,
  }) {
    return _repository.watchTypingIndicators(
      conversationId: conversationId,
    );
  }
}
