import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Gerenciador de cache de imagens customizado para WeGig
/// 
/// Configurações otimizadas:
/// - Limite de disco: 200MB
/// - TTL: 7 dias
/// - Limpeza automática de arquivos expirados
/// 
/// Uso:
/// ```dart
/// CachedNetworkImage(
///   cacheManager: WeGigImageCacheManager.instance,
///   imageUrl: 'https://...',
/// )
/// ```
class WeGigImageCacheManager {
  static const String _cacheKey = 'wegig_image_cache';
  
  /// Instância singleton do cache manager
  static CacheManager? _instance;
  
  /// Obtém a instância do cache manager (lazy initialization)
  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        _cacheKey,
        // ✅ Limite de arquivos em disco: 200MB
        maxNrOfCacheObjects: 500, // ~400KB por imagem média
        // ✅ TTL: 7 dias (posts expiram em 30, mas 7 é suficiente)
        stalePeriod: const Duration(days: 7),
      ),
    );
    return _instance!;
  }
  
  /// Limpa todo o cache de imagens
  /// 
  /// Útil para:
  /// - Troca de ambiente (dev/staging/prod)
  /// - Logout completo
  /// - Problemas de exibição de imagens
  static Future<void> clearAll() async {
    try {
      await instance.emptyCache();
      debugPrint('🗑️ ImageCacheManager: Cache limpo completamente');
    } catch (e) {
      debugPrint('⚠️ ImageCacheManager: Erro ao limpar cache: $e');
    }
  }
  
  /// Remove uma imagem específica do cache
  /// 
  /// [url] URL da imagem a ser removida
  static Future<void> removeFile(String url) async {
    try {
      await instance.removeFile(url);
      debugPrint('🗑️ ImageCacheManager: Removido do cache: $url');
    } catch (e) {
      debugPrint('⚠️ ImageCacheManager: Erro ao remover arquivo: $e');
    }
  }
  
  /// Obtém informações sobre o cache atual
  /// 
  /// Retorna map com:
  /// - cacheKey: identificador do cache
  /// - stalePeriod: tempo de expiração em dias
  static Map<String, dynamic> getCacheInfo() {
    return {
      'cacheKey': _cacheKey,
      'stalePeriod': '7 days',
      'maxObjects': 500,
      'estimatedMaxSize': '200MB',
    };
  }
  
  /// Log informações do cache (debug only)
  static void printCacheInfo() {
    if (kDebugMode) {
      final info = getCacheInfo();
      debugPrint('📷 ImageCacheManager Info:');
      debugPrint('   - Key: ${info['cacheKey']}');
      debugPrint('   - TTL: ${info['stalePeriod']}');
      debugPrint('   - Max Objects: ${info['maxObjects']}');
      debugPrint('   - Max Size: ${info['estimatedMaxSize']}');
    }
  }
}
