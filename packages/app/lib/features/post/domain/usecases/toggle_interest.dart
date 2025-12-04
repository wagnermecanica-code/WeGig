import 'package:wegig_app/features/post/domain/repositories/post_repository.dart';

/// UseCase: Toggle interest em um post (Instagram-style interested users)
/// Adiciona ou remove interesse de um perfil em um post
class ToggleInterest {
  /// Cria uma instância de ToggleInterest
  ToggleInterest(this._repository);
  final PostRepository _repository;

  /// Executa o toggle de interesse (adiciona ou remove)
  /// Retorna true se interesse foi adicionado, false se foi removido
  Future<bool> call(String postId, String profileId) async {
    if (postId.isEmpty) {
      throw ArgumentError('ID do post é obrigatório');
    }
    if (profileId.isEmpty) {
      throw ArgumentError('ID do perfil é obrigatório');
    }

    final post = await _repository.getPostById(postId);
    if (post == null) {
      throw StateError('Post não encontrado');
    }

    if (post.authorProfileId == profileId) {
      throw StateError(
        'Você não pode demonstrar interesse no seu próprio post',
      );
    }

    final hasInterest = await _repository.hasInterest(postId, profileId);

    if (hasInterest) {
      await _repository.removeInterest(postId, profileId);
      return false; // Interest removed
    } else {
      await _repository.addInterest(postId, profileId);
      return true; // Interest added (notification sent by Cloud Function)
    }
  }
}
