import 'package:wegig_app/features/messages/domain/repositories/messages_repository.dart';

class MarkAsUnread {
  MarkAsUnread(this._repository);
  final MessagesRepository _repository;

  Future<void> call({
    required String conversationId,
    required String profileId,
  }) async {
    await _repository.markAsUnread(
      conversationId: conversationId,
      profileId: profileId,
    );
  }
}
