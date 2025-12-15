import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cache_analytics_provider.g.dart';

/// Métricas de cache para Analytics
@immutable
class CacheMetrics {
  const CacheMetrics({
    this.totalCacheHits = 0,
    this.totalCacheMisses = 0,
    this.postCacheHits = 0,
    this.postCacheMisses = 0,
    this.imageCacheHits = 0,
    this.imageCacheMisses = 0,
    this.gpsCacheHits = 0,
    this.gpsCacheMisses = 0,
    this.lastReportTime,
  });
  
  final int totalCacheHits;
  final int totalCacheMisses;
  final int postCacheHits;
  final int postCacheMisses;
  final int imageCacheHits;
  final int imageCacheMisses;
  final int gpsCacheHits;
  final int gpsCacheMisses;
  final DateTime? lastReportTime;
  
  /// Taxa de acerto total (0.0 - 1.0)
  double get hitRate {
    final total = totalCacheHits + totalCacheMisses;
    if (total == 0) return 0.0;
    return totalCacheHits / total;
  }
  
  /// Taxa de acerto formatada (ex: "85%")
  String get hitRateFormatted => '${(hitRate * 100).toStringAsFixed(1)}%';
  
  /// Total de operações de cache
  int get totalOperations => totalCacheHits + totalCacheMisses;
  
  CacheMetrics copyWith({
    int? totalCacheHits,
    int? totalCacheMisses,
    int? postCacheHits,
    int? postCacheMisses,
    int? imageCacheHits,
    int? imageCacheMisses,
    int? gpsCacheHits,
    int? gpsCacheMisses,
    DateTime? lastReportTime,
  }) {
    return CacheMetrics(
      totalCacheHits: totalCacheHits ?? this.totalCacheHits,
      totalCacheMisses: totalCacheMisses ?? this.totalCacheMisses,
      postCacheHits: postCacheHits ?? this.postCacheHits,
      postCacheMisses: postCacheMisses ?? this.postCacheMisses,
      imageCacheHits: imageCacheHits ?? this.imageCacheHits,
      imageCacheMisses: imageCacheMisses ?? this.imageCacheMisses,
      gpsCacheHits: gpsCacheHits ?? this.gpsCacheHits,
      gpsCacheMisses: gpsCacheMisses ?? this.gpsCacheMisses,
      lastReportTime: lastReportTime ?? this.lastReportTime,
    );
  }
  
  Map<String, dynamic> toMap() => {
    'total_cache_hits': totalCacheHits,
    'total_cache_misses': totalCacheMisses,
    'cache_hit_rate': hitRate,
    'post_cache_hits': postCacheHits,
    'post_cache_misses': postCacheMisses,
    'image_cache_hits': imageCacheHits,
    'image_cache_misses': imageCacheMisses,
    'gps_cache_hits': gpsCacheHits,
    'gps_cache_misses': gpsCacheMisses,
  };
}

/// Tipo de cache para métricas
enum CacheType {
  post,
  image,
  gps,
  profile,
  notification,
  message,
}

/// Provider de métricas de cache para Analytics
/// 
/// Funcionalidades:
/// - Contagem de cache hits/misses
/// - Cálculo de taxa de acerto
/// - Envio periódico para Firebase Analytics
/// - Métricas por tipo de cache
/// 
/// Uso:
/// ```dart
/// // Registrar hit
/// ref.read(cacheAnalyticsNotifierProvider.notifier).recordHit(CacheType.post);
/// 
/// // Registrar miss
/// ref.read(cacheAnalyticsNotifierProvider.notifier).recordMiss(CacheType.post);
/// ```
@Riverpod(keepAlive: true)
class CacheAnalyticsNotifier extends _$CacheAnalyticsNotifier {
  /// Intervalo mínimo entre reports para Analytics (5 minutos)
  static const _reportInterval = Duration(minutes: 5);
  
  @override
  CacheMetrics build() {
    return const CacheMetrics();
  }
  
  /// Registra um cache hit
  void recordHit(CacheType type) {
    state = state.copyWith(
      totalCacheHits: state.totalCacheHits + 1,
      postCacheHits: type == CacheType.post 
          ? state.postCacheHits + 1 
          : state.postCacheHits,
      imageCacheHits: type == CacheType.image 
          ? state.imageCacheHits + 1 
          : state.imageCacheHits,
      gpsCacheHits: type == CacheType.gps 
          ? state.gpsCacheHits + 1 
          : state.gpsCacheHits,
    );
    
    if (kDebugMode) {
      debugPrint('📊 CacheAnalytics: HIT ($type) - Rate: ${state.hitRateFormatted}');
    }
    
    _maybeReportToAnalytics();
  }
  
  /// Registra um cache miss
  void recordMiss(CacheType type) {
    state = state.copyWith(
      totalCacheMisses: state.totalCacheMisses + 1,
      postCacheMisses: type == CacheType.post 
          ? state.postCacheMisses + 1 
          : state.postCacheMisses,
      imageCacheMisses: type == CacheType.image 
          ? state.imageCacheMisses + 1 
          : state.imageCacheMisses,
      gpsCacheMisses: type == CacheType.gps 
          ? state.gpsCacheMisses + 1 
          : state.gpsCacheMisses,
    );
    
    if (kDebugMode) {
      debugPrint('📊 CacheAnalytics: MISS ($type) - Rate: ${state.hitRateFormatted}');
    }
    
    _maybeReportToAnalytics();
  }
  
  /// Envia métricas para Analytics se intervalo passou
  void _maybeReportToAnalytics() {
    final now = DateTime.now();
    final lastReport = state.lastReportTime;
    
    // Verificar se deve reportar
    if (lastReport != null && now.difference(lastReport) < _reportInterval) {
      return;
    }
    
    // Verificar se tem dados suficientes
    if (state.totalOperations < 10) {
      return;
    }
    
    _sendToAnalytics();
  }
  
  /// Força envio de métricas para Analytics
  Future<void> reportNow() async {
    await _sendToAnalytics();
  }
  
  /// Envia métricas para Firebase Analytics
  Future<void> _sendToAnalytics() async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'cache_metrics',
        parameters: {
          'hit_rate': (state.hitRate * 100).round(),
          'total_hits': state.totalCacheHits,
          'total_misses': state.totalCacheMisses,
          'post_hits': state.postCacheHits,
          'post_misses': state.postCacheMisses,
        },
      );
      
      state = state.copyWith(lastReportTime: DateTime.now());
      
      debugPrint('📊 CacheAnalytics: Métricas enviadas para Analytics');
      debugPrint('   Hit Rate: ${state.hitRateFormatted}');
      debugPrint('   Total: ${state.totalOperations} operações');
      
    } catch (e) {
      debugPrint('⚠️ CacheAnalytics: Erro ao enviar - $e');
    }
  }
  
  /// Reseta métricas (útil para testes ou nova sessão)
  void reset() {
    state = const CacheMetrics();
    debugPrint('📊 CacheAnalytics: Métricas resetadas');
  }
  
  /// Log detalhado das métricas atuais
  void printMetrics() {
    if (kDebugMode) {
      debugPrint('📊 === Cache Metrics ===');
      debugPrint('   Total Operations: ${state.totalOperations}');
      debugPrint('   Hit Rate: ${state.hitRateFormatted}');
      debugPrint('   ---');
      debugPrint('   Posts: ${state.postCacheHits} hits / ${state.postCacheMisses} misses');
      debugPrint('   Images: ${state.imageCacheHits} hits / ${state.imageCacheMisses} misses');
      debugPrint('   GPS: ${state.gpsCacheHits} hits / ${state.gpsCacheMisses} misses');
      debugPrint('   ---');
      debugPrint('   Last Report: ${state.lastReportTime?.toIso8601String() ?? 'never'}');
    }
  }
}

/// Provider de conveniência para taxa de acerto
@riverpod
double cacheHitRate(CacheHitRateRef ref) {
  return ref.watch(cacheAnalyticsNotifierProvider).hitRate;
}

/// Provider de conveniência para taxa de acerto formatada
@riverpod
String cacheHitRateFormatted(CacheHitRateFormattedRef ref) {
  return ref.watch(cacheAnalyticsNotifierProvider).hitRateFormatted;
}
