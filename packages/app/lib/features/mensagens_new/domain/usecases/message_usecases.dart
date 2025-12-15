import '../entities/entities.dart';
import '../repositories/mensagens_new_repository.dart';

/// Use Case: Enviar mensagem de texto
///
/// Envia uma nova mensagem de texto para uma conversa existente.
/// Atualiza automaticamente o lastMessage da conversa e incrementa
/// o contador de não lidas para os outros participantes.
class SendMessageNewUseCase {
  SendMessageNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  /// Executa o use case
  ///
  /// [conversationId] ID da conversa
  /// [senderId] UID do remetente (Firebase Auth)
  /// [senderProfileId] ProfileId do remetente
  /// [text] Conteúdo da mensagem
  /// [senderName] Nome do remetente (desnormalizado)
  /// [senderPhotoUrl] Foto do remetente (desnormalizado)
  /// [replyTo] Dados da mensagem sendo respondida (opcional)
  Future<MessageNewEntity> call({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String text,
    String? senderName,
    String? senderPhotoUrl,
    MessageReplyData? replyTo,
  }) async {
    // Validar texto
    final validationError = MessageNewEntity.validate(text, null);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    return _repository.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderProfileId: senderProfileId,
      text: text,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      replyTo: replyTo,
    );
  }
}

/// Use Case: Enviar mensagem com imagem
///
/// Envia uma nova mensagem com imagem para uma conversa.
/// A imagem deve ser previamente uploadada para o Storage.
class SendImageMessageNewUseCase {
  SendImageMessageNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<MessageNewEntity> call({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String imageUrl,
    String text = '',
    String? senderName,
    String? senderPhotoUrl,
    MessageReplyData? replyTo,
  }) async {
    if (imageUrl.isEmpty) {
      throw ArgumentError('URL da imagem não pode ser vazia');
    }

    return _repository.sendImageMessage(
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
}

/// Use Case: Editar mensagem
///
/// Edita o conteúdo de uma mensagem existente.
/// Marca a mensagem como editada.
class EditMessageNewUseCase {
  EditMessageNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<void> call({
    required String conversationId,
    required String messageId,
    required String newText,
  }) async {
    final validationError = MessageNewEntity.validate(newText, null);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    return _repository.editMessage(
      conversationId: conversationId,
      messageId: messageId,
      newText: newText,
    );
  }
}

/// Use Case: Deletar mensagem para mim
///
/// Remove a mensagem apenas para o perfil atual.
/// Outros participantes ainda veem a mensagem.
class DeleteMessageForMeNewUseCase {
  DeleteMessageForMeNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<void> call({
    required String conversationId,
    required String messageId,
    required String profileId,
  }) {
    return _repository.deleteMessageForMe(
      conversationId: conversationId,
      messageId: messageId,
      profileId: profileId,
    );
  }
}

/// Use Case: Deletar mensagem para todos
///
/// Remove a mensagem para todos os participantes.
/// O texto original é preservado internamente para auditoria.
class DeleteMessageForEveryoneNewUseCase {
  DeleteMessageForEveryoneNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<void> call({
    required String conversationId,
    required String messageId,
  }) {
    return _repository.deleteMessageForEveryone(
      conversationId: conversationId,
      messageId: messageId,
    );
  }
}

/// Use Case: Adicionar reação
///
/// Adiciona ou atualiza a reação de um perfil em uma mensagem.
/// Cada perfil pode ter apenas uma reação por mensagem.
class AddReactionNewUseCase {
  AddReactionNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<void> call({
    required String conversationId,
    required String messageId,
    required String profileId,
    required String emoji,
  }) {
    if (emoji.isEmpty) {
      throw ArgumentError('Emoji não pode ser vazio');
    }

    return _repository.addReaction(
      conversationId: conversationId,
      messageId: messageId,
      profileId: profileId,
      emoji: emoji,
    );
  }
}

/// Use Case: Remover reação
///
/// Remove a reação do perfil em uma mensagem.
class RemoveReactionNewUseCase {
  RemoveReactionNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<void> call({
    required String conversationId,
    required String messageId,
    required String profileId,
  }) {
    return _repository.removeReaction(
      conversationId: conversationId,
      messageId: messageId,
      profileId: profileId,
    );
  }
}

/// Use Case: Carregar mensagens
///
/// Carrega mensagens de uma conversa com paginação.
/// [clearHistoryAfter] Se definido, filtra mensagens para não mostrar histórico antigo.
class LoadMessagesNewUseCase {
  LoadMessagesNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Future<List<MessageNewEntity>> call({
    required String conversationId,
    int limit = 50,
    MessageNewEntity? startAfter,
    DateTime? clearHistoryAfter,
  }) {
    return _repository.getMessages(
      conversationId: conversationId,
      limit: limit,
      startAfter: startAfter,
      clearHistoryAfter: clearHistoryAfter,
    );
  }
}

/// Use Case: Watch mensagens em tempo real
///
/// Retorna um Stream de mensagens para updates em tempo real.
/// [clearHistoryAfter] Se definido, filtra mensagens para não mostrar histórico antigo.
class WatchMessagesNewUseCase {
  WatchMessagesNewUseCase(this._repository);

  final MensagensNewRepository _repository;

  Stream<List<MessageNewEntity>> call({
    required String conversationId,
    int limit = 50,
    DateTime? clearHistoryAfter,
  }) {
    return _repository.watchMessages(
      conversationId: conversationId,
      limit: limit,
      clearHistoryAfter: clearHistoryAfter,
    );
  }
}
