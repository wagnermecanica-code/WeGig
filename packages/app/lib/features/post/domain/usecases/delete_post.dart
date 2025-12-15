import 'package:wegig_app/features/post/domain/repositories/post_repository.dart';

/// UseCase: Deletar um post
/// Valida ownership antes de deletar
class DeletePost {
  /// Cria uma instância de DeletePost
  DeletePost(this._repository);
  final PostRepository _repository;

  /// Executa a deleção do post verificando ownership
  Future<void> call(String postId, String profileId) async {
    if (postId.isEmpty) {
      throw ArgumentError('ID do post é obrigatório');
    }
    if (profileId.isEmpty) {
      throw ArgumentError('ID do usuário é obrigatório');
    }

    final isOwner = await _repository.isPostOwner(postId, profileId);
    if (!isOwner) {
      throw StateError('Você não tem permissão para excluir este post');
    }

    await _repository.deletePost(postId, profileId);
  }
}
