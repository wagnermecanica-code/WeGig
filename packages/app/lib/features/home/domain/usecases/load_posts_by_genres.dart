import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:wegig_app/features/home/domain/repositories/home_repository.dart';

/// UseCase para carregar posts filtrados por gênero
/// Combina busca geoespacial com filtro de gêneros musicais
class LoadPostsByGenresUseCase {
  LoadPostsByGenresUseCase(this._repository);
  final HomeRepository _repository;

  /// Executa busca de posts por gêneros
  Future<List<PostEntity>> call({
    required List<String> genres,
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 50,
    String? lastPostId,
  }) async {
    return _repository.loadPostsByGenres(
      genres: genres,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      limit: limit,
      lastPostId: lastPostId,
    );
  }
}
