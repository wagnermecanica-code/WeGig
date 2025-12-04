import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/features/home/data/repositories/home_repository_impl.dart';
import 'package:wegig_app/features/home/domain/repositories/home_repository.dart';
import 'package:wegig_app/features/home/domain/usecases/load_nearby_posts.dart';
import 'package:wegig_app/features/home/domain/usecases/load_posts_by_genres.dart';
import 'package:wegig_app/features/home/domain/usecases/search_profiles.dart';
import 'package:wegig_app/features/post/presentation/providers/post_providers.dart';

part 'home_providers.freezed.dart';
part 'home_providers.g.dart';

// ========================= DATA LAYER =========================

/// Provider para Firestore instance
@riverpod
FirebaseFirestore firestore(Ref ref) {
  return FirebaseFirestore.instance;
}

/// Provider para HomeRepository
@riverpod
HomeRepository homeRepository(Ref ref) {
  final postRepository = ref.watch(postRepositoryNewProvider);
  final firestore = ref.watch(firestoreProvider);

  return HomeRepositoryImpl(
    postRepository: postRepository,
    firestore: firestore,
  );
}

// ========================= USE CASES =========================

/// Provider para LoadNearbyPostsUseCase
@riverpod
LoadNearbyPostsUseCase loadNearbyPostsUseCase(Ref ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return LoadNearbyPostsUseCase(repository);
}

/// Provider para LoadPostsByGenresUseCase
@riverpod
LoadPostsByGenresUseCase loadPostsByGenresUseCase(Ref ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return LoadPostsByGenresUseCase(repository);
}

/// Provider para SearchProfilesUseCase
@riverpod
SearchProfilesUseCase searchProfilesUseCase(Ref ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return SearchProfilesUseCase(repository);
}

// ========================= PRESENTATION LAYER =========================

/// Estado do feed de posts
@freezed
class FeedState with _$FeedState {
  const factory FeedState({
    @Default([]) List<PostEntity> posts,
    @Default(false) bool isLoading,
    String? error,
    @Default(true) bool hasMore,
    String? lastPostId,
  }) = _FeedState;
}

/// Notifier para gerenciar feed de posts
@riverpod
class FeedNotifier extends _$FeedNotifier {
  late final LoadNearbyPostsUseCase _loadNearbyPostsUseCase;
  late final LoadPostsByGenresUseCase _loadPostsByGenresUseCase;

  @override
  FeedState build() {
    _loadNearbyPostsUseCase = ref.watch(loadNearbyPostsUseCaseProvider);
    _loadPostsByGenresUseCase = ref.watch(loadPostsByGenresUseCaseProvider);
    return const FeedState();
  }

  /// Carrega posts próximos
  Future<void> loadNearbyPosts({
    required double latitude,
    required double longitude,
    required double radiusKm,
    bool refresh = false,
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      posts: refresh ? [] : state.posts,
      lastPostId: refresh ? null : state.lastPostId,
    );

    try {
      final posts = await _loadNearbyPostsUseCase(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        lastPostId: refresh ? null : state.lastPostId,
      );

      state = state.copyWith(
        posts: refresh ? posts : [...state.posts, ...posts],
        isLoading: false,
        hasMore: posts.length >= 50,
        lastPostId: posts.isNotEmpty ? posts.last.id : state.lastPostId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Carrega posts filtrados por gênero
  Future<void> loadPostsByGenres({
    required List<String> genres,
    required double latitude,
    required double longitude,
    required double radiusKm,
    bool refresh = false,
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      posts: refresh ? [] : state.posts,
      lastPostId: refresh ? null : state.lastPostId,
    );

    try {
      final posts = await _loadPostsByGenresUseCase(
        genres: genres,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        lastPostId: refresh ? null : state.lastPostId,
      );

      state = state.copyWith(
        posts: refresh ? posts : [...state.posts, ...posts],
        isLoading: false,
        hasMore: posts.length >= 50,
        lastPostId: posts.isNotEmpty ? posts.last.id : state.lastPostId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Limpa o feed
  void clear() {
    state = const FeedState();
  }
}

/// Alias para o provider gerado por Riverpod
final feedProvider = feedNotifierProvider;

// ========================= SEARCH =========================

/// Estado da busca de perfis
@freezed
class ProfileSearchState with _$ProfileSearchState {
  const factory ProfileSearchState({
    @Default([]) List<ProfileEntity> profiles,
    @Default(false) bool isLoading,
    String? error,
  }) = _ProfileSearchState;
}

/// Notifier para busca de perfis
@riverpod
class ProfileSearchNotifier extends _$ProfileSearchNotifier {
  late final SearchProfilesUseCase _searchProfilesUseCase;

  @override
  ProfileSearchState build() {
    _searchProfilesUseCase = ref.watch(searchProfilesUseCaseProvider);
    return const ProfileSearchState();
  }

  /// Executa busca de perfis
  Future<void> searchProfiles({
    String? name,
    String? instrument,
    String? city,
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
    );

    try {
      final profiles = await _searchProfilesUseCase(
        name: name,
        instrument: instrument,
        city: city,
      );

      state = state.copyWith(
        profiles: profiles,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Limpa resultados de busca
  void clear() {
    state = const ProfileSearchState();
  }
}

/// Alias para o provider gerado por Riverpod
final profileSearchProvider = profileSearchNotifierProvider;

// ========================= STREAMS =========================

/// Provider para stream de posts próximos (tempo real)
@riverpod
Stream<List<PostEntity>> nearbyPostsStream(
  Ref ref,
  Map<String, double> params,
) {
  final repository = ref.watch(homeRepositoryProvider);

  final latitude = params['latitude'] ?? 0.0;
  final longitude = params['longitude'] ?? 0.0;
  final radiusKm = params['radiusKm'] ?? 50.0;

  return repository.watchNearbyPosts(
    latitude: latitude,
    longitude: longitude,
    radiusKm: radiusKm,
  );
}
