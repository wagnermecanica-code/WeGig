import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:wegig_app/features/post/domain/repositories/post_repository.dart';

/// UseCase: Criar um novo post
/// Valida campos obrigatórios antes de criar
class CreatePost {
  /// Cria uma instância de CreatePost
  CreatePost(this._repository);
  final PostRepository _repository;

  /// Executa a criação do post com validações
  Future<PostEntity> call(PostEntity post) async {
    // Validações
    if (post.content.trim().isEmpty) {
      throw Exception('Conteúdo é obrigatório');
    }

    if (post.content.length > 500) {
      throw Exception('Conteúdo deve ter no máximo 500 caracteres');
    }

    if (post.city.trim().isEmpty) {
      throw Exception('Cidade é obrigatória');
    }

    if (post.location.latitude == 0 && post.location.longitude == 0) {
      throw Exception('Localização é obrigatória');
    }

    if (post.instruments.isEmpty && post.type == 'musician') {
      throw Exception('Selecione pelo menos um instrumento');
    }

    if (post.genres.isEmpty) {
      throw Exception('Selecione pelo menos um gênero musical');
    }

    if (post.level.trim().isEmpty) {
      throw Exception('Selecione o nível de experiência');
    }

    // YouTube validation (if provided)
    if (post.youtubeLink != null && post.youtubeLink!.isNotEmpty) {
      final link = post.youtubeLink!;
      if (!link.contains('youtube.com') && !link.contains('youtu.be')) {
        throw Exception('Link do YouTube inválido');
      }
    }

    return _repository.createPost(post);
  }
}
