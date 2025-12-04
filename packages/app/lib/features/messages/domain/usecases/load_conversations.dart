import 'package:core_ui/features/messages/domain/entities/conversation_entity.dart';
import 'package:wegig_app/features/messages/domain/repositories/messages_repository.dart';

class LoadConversations {
  LoadConversations(this._repository);
  final MessagesRepository _repository;

  Future<List<ConversationEntity>> call({
    required String profileId,
    int limit = 20,
    ConversationEntity? startAfter,
  }) async {
    if (profileId.isEmpty) {
      throw ArgumentError('ID do perfil é obrigatório');
    }
    if (limit <= 0) {
      throw ArgumentError('Limite deve ser maior que zero');
    }

    return _repository.getConversations(
      profileId: profileId,
      limit: limit,
      startAfter: startAfter,
    );
  }
}
