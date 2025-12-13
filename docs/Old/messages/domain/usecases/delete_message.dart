import 'package:wegig_app/features/messages/domain/repositories/messages_repository.dart';

class DeleteMessage {
  final MessagesRepository repository;

  DeleteMessage(this.repository);

  Future<void> call({
    required String conversationId,
    required String messageId,
  }) {
    return repository.deleteMessage(
      conversationId: conversationId,
      messageId: messageId,
    );
  }
}
