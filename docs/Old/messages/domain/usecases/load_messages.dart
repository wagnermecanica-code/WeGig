import 'package:core_ui/features/messages/domain/entities/message_entity.dart';
import 'package:wegig_app/features/messages/domain/repositories/messages_repository.dart';

class LoadMessages {
  LoadMessages(this._repository);
  final MessagesRepository _repository;

  Future<List<MessageEntity>> call({
    required String conversationId,
    int limit = 20,
    MessageEntity? startAfter,
  }) async {
    return _repository.getMessages(
      conversationId: conversationId,
      limit: limit,
      startAfter: startAfter,
    );
  }
}
