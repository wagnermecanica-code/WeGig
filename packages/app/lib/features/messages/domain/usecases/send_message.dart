import 'package:core_ui/features/messages/domain/entities/message_entity.dart';
import 'package:wegig_app/features/messages/domain/repositories/messages_repository.dart';

class SendMessage {
  SendMessage(this._repository);
  final MessagesRepository _repository;

  Future<MessageEntity> call({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String text,
    MessageReplyEntity? replyTo,
  }) async {
    if (conversationId.isEmpty) {
      throw ArgumentError('ID da conversa é obrigatório');
    }
    if (senderId.isEmpty) {
      throw ArgumentError('ID do remetente é obrigatório');
    }
    if (senderProfileId.isEmpty) {
      throw ArgumentError('ID do perfil remetente é obrigatório');
    }

    final sanitizedText = text.trim();
    if (sanitizedText.isEmpty) {
      throw ArgumentError('Mensagem não pode ser vazia');
    }
    if (sanitizedText.length > 1000) {
      throw ArgumentError('Mensagem deve ter no máximo 1000 caracteres');
    }

    return _repository.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderProfileId: senderProfileId,
      text: sanitizedText,
      replyTo: replyTo,
    );
  }
}
