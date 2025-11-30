import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/utils/geo_utils.dart' as geo;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wegig_app/features/home/domain/repositories/home_repository.dart';
import 'package:wegig_app/features/post/domain/repositories/post_repository.dart';

/// Implementação do HomeRepository
/// Reutiliza PostRepository para operações de posts
/// Adiciona lógica específica de feed e busca
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    required PostRepository postRepository,
    FirebaseFirestore? firestore,
  })  : _postRepository = postRepository,
        _firestore = firestore ?? FirebaseFirestore.instance;
  final PostRepository _postRepository;
  final FirebaseFirestore _firestore;

  @override
  Future<List<PostEntity>> loadNearbyPosts({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 50,
    String? lastPostId,
  }) async {
    try {
      // Reutiliza getNearbyPosts do PostRepository
      final posts = await _postRepository.getNearbyPosts(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
      );

      // Calcula distância para cada post
      final postsWithDistance = posts.map((post) {
        final distance = geo.calculateDistance(
          LatLng(latitude, longitude),
          LatLng(post.latitude, post.longitude),
        );
        return post.copyWith(distanceKm: distance);
      }).toList();

      // Ordena por distância (mais próximos primeiro)
      postsWithDistance.sort((a, b) => (a.distanceKm ?? double.infinity)
          .compareTo(b.distanceKm ?? double.infinity));

      return postsWithDistance;
    } catch (e) {
      debugPrint('❌ HomeRepositoryImpl.loadNearbyPosts error: $e');
      rethrow;
    }
  }

  @override
  Future<List<PostEntity>> loadPostsByGenres({
    required List<String> genres,
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 50,
    String? lastPostId,
  }) async {
    try {
      // Primeiro busca posts próximos
      final nearbyPosts = await loadNearbyPosts(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit * 2, // Busca mais para ter margem para filtro
        lastPostId: lastPostId,
      );

      // Filtra posts que contêm pelo menos um dos gêneros
      final filteredPosts = nearbyPosts
          .where((post) {
            return post.genres.any((genre) => genres.any((searchGenre) =>
                genre.toLowerCase().contains(searchGenre.toLowerCase())));
          })
          .take(limit)
          .toList();

      return filteredPosts;
    } catch (e) {
      debugPrint('❌ HomeRepositoryImpl.loadPostsByGenres error: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProfileEntity>> searchProfiles({
    String? name,
    String? instrument,
    String? city,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('profiles');

      // Filtro por nome (case-insensitive via Firestore array search)
      if (name != null && name.isNotEmpty) {
        // Busca por nome usando >= e < para prefix search
        final nameLower = name.toLowerCase();
        query = query
            .orderBy('nameLower')
            .where('nameLower', isGreaterThanOrEqualTo: nameLower)
            .where('nameLower', isLessThan: '$nameLower\uf8ff');
      }

      // Filtro por instrumento
      if (instrument != null && instrument.isNotEmpty) {
        query = query.where('instruments', arrayContains: instrument);
      }

      // Filtro por cidade
      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final profiles = snapshot.docs
          .map((doc) =>
              ProfileEntity.fromJson({...doc.data(), 'profileId': doc.id}))
          .toList();

      return profiles;
    } catch (e) {
      debugPrint('❌ HomeRepositoryImpl.searchProfiles error: $e');
      return [];
    }
  }

  /// Calcula bounds aproximados para geosearch
  /// Retorna retângulo que contém o círculo de raio especificado
  Map<String, double> _calculateBounds(
      double lat, double lng, double radiusKm) {
    // Conversão aproximada: 1 grau ≈ 111km
    final latDelta = radiusKm / 111.0;
    final lngDelta = radiusKm / (111.0 * (lat * 3.14159 / 180.0).abs());

    return {
      'minLat': lat - latDelta,
      'maxLat': lat + latDelta,
      'minLng': lng - lngDelta,
      'maxLng': lng + lngDelta,
    };
  }

  @override
  Stream<List<PostEntity>> watchNearbyPosts({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    try {
      // Calcula bounds do retângulo que contém o círculo de busca
      final bounds = _calculateBounds(latitude, longitude, radiusKm);

      return _firestore
          .collection('posts')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .where('location',
              isGreaterThan: GeoPoint(bounds['minLat']!, bounds['minLng']!))
          .where('location',
              isLessThan: GeoPoint(bounds['maxLat']!, bounds['maxLng']!))
          .orderBy('location')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
        final posts = snapshot.docs.map(PostEntity.fromFirestore).toList();

        // Filtra posts dentro do raio circular
        final postsInRadius = posts.where((post) {
          final distance = geo.calculateDistance(
            LatLng(latitude, longitude),
            LatLng(post.latitude, post.longitude),
          );
          return distance <= radiusKm;
        }).toList();

        // Adiciona distância e ordena
        final postsWithDistance = postsInRadius.map((post) {
          final distance = geo.calculateDistance(
            LatLng(latitude, longitude),
            LatLng(post.latitude, post.longitude),
          );
          return post.copyWith(distanceKm: distance);
        }).toList();

        postsWithDistance.sort((a, b) => (a.distanceKm ?? double.infinity)
            .compareTo(b.distanceKm ?? double.infinity));

        return postsWithDistance;
      });
    } catch (e) {
      debugPrint('❌ HomeRepositoryImpl.watchNearbyPosts error: $e');
      return Stream.value([]);
    }
  }
}
