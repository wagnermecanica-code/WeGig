import 'package:flutter/foundation.dart';

/// Mixin para padronizar comportamento de cache em Notifiers
/// 
/// Fornece:
/// - TTL (Time To Live) configurável
/// - Validação de cache expirado
/// - Métodos de invalidação
/// - Logging consistente
/// 
/// Uso:
/// ```dart
/// class MyNotifier extends _$MyNotifier with CacheAwareMixin {
///   @override
///   Duration get cacheTTL => const Duration(minutes: 5);
///   
///   Future<List<Item>> fetchItems() async {
///     if (isCacheValid) {
///       debugPrint('Cache hit!');
///       return state.value ?? [];
///     }
///     // Fetch from server...
///     markCacheUpdated();
///   }
/// }
/// ```
mixin CacheAwareMixin {
  /// Timestamp da última atualização do cache
  DateTime? _lastCacheUpdate;
  
  /// Indica se o cache foi manualmente invalidado
  bool _isInvalidated = false;
  
  /// Duração do TTL do cache (deve ser sobrescrito)
  /// 
  /// Valores recomendados por tipo de dado:
  /// - Feed de posts: 2 minutos
  /// - Perfil do usuário: 5 minutos
  /// - Notificações: 1 minuto
  /// - Mensagens: 30 segundos
  /// - Configurações: 10 minutos
  Duration get cacheTTL => const Duration(minutes: 2);
  
  /// Nome do cache para logging (opcional, sobrescrever para logs melhores)
  String get cacheName => 'CacheAware';
  
  /// Verifica se o cache ainda é válido
  /// 
  /// Retorna `false` se:
  /// - Cache nunca foi atualizado
  /// - Cache foi manualmente invalidado
  /// - TTL expirou
  bool get isCacheValid {
    if (_isInvalidated) {
      _logCache('invalidado manualmente');
      return false;
    }
    
    if (_lastCacheUpdate == null) {
      _logCache('nunca foi preenchido');
      return false;
    }
    
    final elapsed = DateTime.now().difference(_lastCacheUpdate!);
    final isValid = elapsed < cacheTTL;
    
    if (!isValid) {
      _logCache('TTL expirado (${elapsed.inSeconds}s > ${cacheTTL.inSeconds}s)');
    }
    
    return isValid;
  }
  
  /// Tempo restante até o cache expirar
  /// 
  /// Retorna `Duration.zero` se cache já expirou ou é inválido
  Duration get cacheTimeRemaining {
    if (_lastCacheUpdate == null || _isInvalidated) {
      return Duration.zero;
    }
    
    final elapsed = DateTime.now().difference(_lastCacheUpdate!);
    final remaining = cacheTTL - elapsed;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  /// Idade do cache em segundos
  /// 
  /// Retorna -1 se cache nunca foi atualizado
  int get cacheAgeSeconds {
    if (_lastCacheUpdate == null) return -1;
    return DateTime.now().difference(_lastCacheUpdate!).inSeconds;
  }
  
  /// Marca o cache como atualizado (chamar após fetch bem-sucedido)
  void markCacheUpdated() {
    _lastCacheUpdate = DateTime.now();
    _isInvalidated = false;
    _logCache('atualizado');
  }
  
  /// Invalida o cache (força refresh no próximo acesso)
  /// 
  /// Use quando:
  /// - Usuário faz pull-to-refresh
  /// - Perfil ativo muda
  /// - Dados foram modificados localmente
  void invalidateCache() {
    _isInvalidated = true;
    _logCache('invalidado');
  }
  
  /// Reseta completamente o estado do cache
  /// 
  /// Diferente de `invalidateCache()`, também limpa o timestamp.
  /// Use em logout ou troca de ambiente.
  void resetCache() {
    _lastCacheUpdate = null;
    _isInvalidated = false;
    _logCache('resetado completamente');
  }
  
  /// Informações do cache para debugging
  Map<String, dynamic> get cacheDebugInfo => {
    'name': cacheName,
    'ttlSeconds': cacheTTL.inSeconds,
    'lastUpdate': _lastCacheUpdate?.toIso8601String(),
    'ageSeconds': cacheAgeSeconds,
    'remainingSeconds': cacheTimeRemaining.inSeconds,
    'isValid': isCacheValid,
    'isInvalidated': _isInvalidated,
  };
  
  /// Log interno com prefixo consistente
  void _logCache(String message) {
    if (kDebugMode) {
      debugPrint('🗄️ [$cacheName] Cache $message');
    }
  }
  
  /// Log público para eventos importantes
  void logCacheEvent(String event) {
    if (kDebugMode) {
      debugPrint('🗄️ [$cacheName] $event');
    }
  }
}

/// Extension para facilitar uso do mixin com Riverpod Ref
extension CacheAwareRefExtension on CacheAwareMixin {
  /// Verifica cache e executa fetch se necessário
  /// 
  /// ```dart
  /// final data = await executeWithCache(
  ///   cachedData: state.value,
  ///   fetchData: () => repository.fetchItems(),
  /// );
  /// ```
  Future<T> executeWithCache<T>({
    required T? cachedData,
    required Future<T> Function() fetchData,
  }) async {
    if (isCacheValid && cachedData != null) {
      logCacheEvent('Hit! Retornando dados em cache');
      return cachedData;
    }
    
    logCacheEvent('Miss! Buscando dados frescos...');
    final freshData = await fetchData();
    markCacheUpdated();
    
    return freshData;
  }
}
