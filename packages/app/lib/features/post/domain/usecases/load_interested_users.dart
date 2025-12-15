import 'package:wegig_app/features/post/domain/repositories/post_repository.dart';

/// UseCase: Carregar perfis interessados em um post
/// Retorna lista de profileIds que demonstraram interesse
class LoadInterestedUsers {
  /// Cria uma instância de LoadInterestedUsers
  LoadInterestedUsers(this._repository);
  final PostRepository _repository;

  /// Executa o carregamento dos profileIds interessados
  Future<List<String>> call(String postId) async {
    if (postId.isEmpty) {
      throw ArgumentError('ID do post é obrigatório');
    }
    return _repository.getInterestedProfiles(postId);
  }
}
