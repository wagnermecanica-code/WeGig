import 'package:core_ui/features/messages/domain/entities/message_entity.dart';
import 'package:wegig_app/features/messages/domain/repositories/messages_repository.dart';

class WatchMessages {
  final MessagesRepository repository;

  WatchMessages(this.repository);

  Stream<List<MessageEntity>> call(String conversationId) {
    return repository.watchMessages(conversationId);
  }
}
