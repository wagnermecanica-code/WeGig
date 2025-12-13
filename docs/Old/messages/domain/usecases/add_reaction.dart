import 'package:wegig_app/features/messages/domain/repositories/messages_repository.dart';

class AddReaction {
  final MessagesRepository repository;

  AddReaction(this.repository);

  Future<void> call({
    required String conversationId,
    required String messageId,
    required String userId,
    required String reaction,
  }) {
    return repository.addReaction(
      conversationId: conversationId,
      messageId: messageId,
      userId: userId,
      reaction: reaction,
    );
  }
}
