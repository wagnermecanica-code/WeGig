import 'package:core_ui/features/post/domain/entities/post_entity.dart';

/// Repository interface para Posts (domain layer)
/// Define o contrato para operações de posts
abstract class PostRepository {
  /// Lista todos os posts ativos disponíveis no feed
  /// Ordena por createdAt descendente
  Future<List<PostEntity>> getAllPosts(String uid);

  /// Lista posts de um perfil específico
  Future<List<PostEntity>> getPostsByProfile(String profileId);

  /// Busca um post por ID
  Future<PostEntity?> getPostById(String postId);

  /// Cria um novo post
  /// Valida campos obrigatórios e limites
  Future<PostEntity> createPost(PostEntity post);

  /// Atualiza um post existente
  /// Valida ownership (authorProfileId == activeProfileId)
  Future<PostEntity> updatePost(PostEntity post);

  /// Deleta um post
  /// Valida ownership antes de deletar
  Future<void> deletePost(String postId, String profileId);

  /// Verifica se um perfil é dono de um post
  Future<bool> isPostOwner(String postId, String profileId);

  /// Verifica se um perfil demonstrou interesse em um post
  Future<bool> hasInterest(String postId, String profileId);

  /// Adiciona interesse de um perfil em um post
  /// Cria documento em interests/ e envia notificação
  Future<void> addInterest(String postId, String profileId);

  /// Remove interesse de um perfil em um post
  Future<void> removeInterest(String postId, String profileId);

  /// Lista perfis que demonstraram interesse em um post
  /// Retorna lista de profileIds
  Future<List<String>> getInterestedProfiles(String postId);

  /// Busca posts próximos baseado em localização
  /// Usa geosearch com raio em km
  Future<List<PostEntity>> getNearbyPosts({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 50,
  });

  /// Stream de posts (para updates em tempo real)
  Stream<List<PostEntity>> watchPosts(String uid);

  /// Stream de posts de um perfil
  Stream<List<PostEntity>> watchPostsByProfile(String profileId);
}
