import 'package:core_ui/features/messages/domain/entities/message_entity.dart';
import 'package:wegig_app/features/messages/domain/repositories/messages_repository.dart';

class SendImage {
  SendImage(this._repository);
  final MessagesRepository _repository;

  Future<MessageEntity> call({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String imageUrl,
    String text = '',
    MessageReplyEntity? replyTo,
  }) async {
    if (imageUrl.trim().isEmpty) {
      throw Exception('URL da imagem é obrigatória');
    }

    return _repository.sendImageMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderProfileId: senderProfileId,
      imageUrl: imageUrl,
      text: text,
      replyTo: replyTo,
    );
  }
}
