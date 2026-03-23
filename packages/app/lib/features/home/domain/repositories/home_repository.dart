import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';

/// Repository interface para Home (domain layer)
/// Define o contrato para operações de feed e busca
abstract class HomeRepository {
  /// Busca posts próximos baseado em geolocalização
  /// Usa raio em km e retorna posts dentro da área
  Future<List<PostEntity>> loadNearbyPosts({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 50,
    String? lastPostId,
  });

  /// Busca posts filtrados por gênero musical
  /// Retorna posts que contêm pelo menos um dos gêneros especificados
  Future<List<PostEntity>> loadPostsByGenres({
    required List<String> genres,
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 50,
    String? lastPostId,
  });

  /// Busca perfis por nome, instrumento ou cidade
  /// Retorna lista de perfis que correspondem aos critérios
  Future<List<ProfileEntity>> searchProfiles({
    String? name,
    String? instrument,
    String? city,
    int limit = 20,
    String? currentProfileId,
  });

  /// Stream de posts próximos (tempo real)
  /// Atualiza automaticamente quando há novos posts na área
  Stream<List<PostEntity>> watchNearbyPosts({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? currentProfileId,
    String? currentUid,
  });
}
