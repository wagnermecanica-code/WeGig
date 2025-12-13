import 'package:wegig_app/features/messages/domain/repositories/messages_repository.dart';

class RemoveReaction {
  final MessagesRepository repository;

  RemoveReaction(this.repository);

  Future<void> call({
    required String conversationId,
    required String messageId,
    required String userId,
  }) {
    return repository.removeReaction(
      conversationId: conversationId,
      messageId: messageId,
      userId: userId,
    );
  }
}
