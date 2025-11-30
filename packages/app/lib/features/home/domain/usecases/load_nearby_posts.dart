import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:wegig_app/features/home/domain/repositories/home_repository.dart';

/// UseCase para carregar posts próximos
/// Encapsula lógica de busca geoespacial
class LoadNearbyPostsUseCase {
  LoadNearbyPostsUseCase(this._repository);
  final HomeRepository _repository;

  /// Executa busca de posts próximos
  Future<List<PostEntity>> call({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 50,
    String? lastPostId,
  }) async {
    return _repository.loadNearbyPosts(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      limit: limit,
      lastPostId: lastPostId,
    );
  }
}
