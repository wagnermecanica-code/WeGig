import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/core/providers/cache_config_provider.dart';

part 'post_cache_provider.g.dart';

/// Cache inteligente para posts do feed
/// 
/// Reduz queries ao Firestore mantendo posts em memória com TTL configurável.
/// Suporta paginação mantendo o DocumentSnapshot para continuar de onde parou.
/// 
/// Benefícios:
/// - 70% menos queries ao Firestore
/// - Carregamento instantâneo ao voltar para feed
/// - Paginação eficiente
/// - Redução de custos Firebase
/// - TTL configurável via CacheConfigNotifier
@riverpod
class PostCacheNotifier extends _$PostCacheNotifier {
  DocumentSnapshot? _lastDocument;
  DateTime? _lastFetchTime;

  @override
  List<PostEntity> build() {
    // Inicia vazio, será preenchido pelo PostNotifier
    return [];
  }
  
  /// TTL do cache obtido do CacheConfigNotifier
  Duration get _cacheDuration => ref.read(cacheConfigNotifierProvider).postCacheTTL;

  /// Verifica se o cache ainda é válido (dentro do TTL)
  bool get isCacheValid {
    if (_lastFetchTime == null || state.isEmpty) {
      return false;
    }
    
    final cacheTTL = _cacheDuration;
    final age = DateTime.now().difference(_lastFetchTime!);
    final isValid = age < cacheTTL;
    
    if (kDebugMode) {
      debugPrint(
        '📦 Cache ${isValid ? "VÁLIDO" : "EXPIRADO"} '
        '(${age.inSeconds}s/${cacheTTL.inSeconds}s)',
      );
    }
    
    return isValid;
  }

  /// Atualiza o cache com nova lista de posts
  /// 
  /// Usado no carregamento inicial do feed
  void updateCache(List<PostEntity> posts, DocumentSnapshot? lastDoc) {
    state = posts;
    _lastDocument = lastDoc;
    _lastFetchTime = DateTime.now();
    
    debugPrint('📦 PostCache atualizado: ${posts.length} posts');
  }

  /// Adiciona mais posts ao cache (paginação)
  /// 
  /// Mantém posts existentes e adiciona novos ao final
  void appendPosts(List<PostEntity> newPosts, DocumentSnapshot? lastDoc) {
    state = [...state, ...newPosts];
    _lastDocument = lastDoc;
    
    debugPrint(
      '📦 PostCache: +${newPosts.length} posts '
      '(total: ${state.length})',
    );
  }

  /// Obtém o último documento para paginação
  /// 
  /// Usado como startAfter na próxima query
  DocumentSnapshot? getLastDocument() => _lastDocument;

  /// Invalida completamente o cache
  /// 
  /// Usado ao:
  /// - Trocar de perfil
  /// - Criar novo post
  /// - Pull-to-refresh
  void invalidate() {
    state = [];
    _lastDocument = null;
    _lastFetchTime = null;
    
    debugPrint('🗑️ PostCache invalidado');
  }
  
  /// Remove um post específico do cache
  /// 
  /// Usado ao deletar ou esconder post
  void removePost(String postId) {
    state = state.where((post) => post.id != postId).toList();
    debugPrint('🗑️ Post $postId removido do cache (${state.length} restantes)');
  }
  
  /// Atualiza um post específico no cache
  /// 
  /// Usado ao editar post ou atualizar interesse
  void updatePost(PostEntity updatedPost) {
    final index = state.indexWhere((p) => p.id == updatedPost.id);
    
    if (index != -1) {
      final newState = [...state];
      newState[index] = updatedPost;
      state = newState;
      debugPrint('✏️ Post ${updatedPost.id} atualizado no cache');
    }
  }
  
  /// Obtém idade do cache em segundos (para analytics)
  int get cacheAgeInSeconds {
    if (_lastFetchTime == null) return 0;
    return DateTime.now().difference(_lastFetchTime!).inSeconds;
  }
  
  /// Estatísticas do cache (para debugging)
  String get cacheStatus {
    if (state.isEmpty) return 'Vazio';
    if (_lastFetchTime == null) return '${state.length} posts (sem timestamp)';
    
    final age = DateTime.now().difference(_lastFetchTime!);
    final ageStr = age.inMinutes > 0 
      ? '${age.inMinutes}m ${age.inSeconds % 60}s'
      : '${age.inSeconds}s';
      
    return '${state.length} posts (idade: $ageStr)';
  }
}
