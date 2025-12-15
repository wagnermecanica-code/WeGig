import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:wegig_app/features/post/domain/repositories/post_repository.dart';

/// UseCase: Atualizar um post existente
/// Valida ownership e campos obrigatórios
class UpdatePost {
  /// Cria uma instância de UpdatePost
  UpdatePost(this._repository);
  final PostRepository _repository;

  /// Executa a atualização do post com validações e verificação de ownership
  Future<PostEntity> call(PostEntity post, String currentProfileId) async {
    // Verify ownership
    if (post.authorProfileId != currentProfileId) {
      throw Exception('Você não tem permissão para editar este post');
    }

    // Validações comuns
    if (post.content.trim().isEmpty) {
      throw Exception('Conteúdo é obrigatório');
    }

    if (post.content.length > 600) {
      throw Exception('Conteúdo deve ter no máximo 600 caracteres');
    }

    if (post.city.trim().isEmpty) {
      throw Exception('Cidade é obrigatória');
    }

    if (post.location.latitude == 0 && post.location.longitude == 0) {
      throw Exception('Localização é obrigatória');
    }

    // Validações específicas por tipo
    if (post.type == 'sales') {
      // Sales: validar campos específicos (SEM gêneros/instrumentos/nível)
      if (post.title == null || post.title!.trim().isEmpty) {
        throw Exception('Título é obrigatório para anúncios');
      }
      if (post.price == null || post.price! <= 0) {
        throw Exception('Preço deve ser maior que zero');
      }
    } else {
      // Musician/Band: validar gêneros, instrumentos e nível
      if (post.instruments.isEmpty && post.type == 'musician') {
        throw Exception('Selecione pelo menos um instrumento');
      }

      if (post.genres.isEmpty) {
        throw Exception('Selecione pelo menos um gênero musical');
      }

      if (post.level.trim().isEmpty) {
        throw Exception('Selecione o nível de experiência');
      }
    }

    // YouTube validation (opcional para todos)
    if (post.youtubeLink != null && post.youtubeLink!.isNotEmpty) {
      final link = post.youtubeLink!;
      if (!link.contains('youtube.com') && !link.contains('youtu.be')) {
        throw Exception('Link do YouTube inválido');
      }
    }

    return _repository.updatePost(post);
  }
}
