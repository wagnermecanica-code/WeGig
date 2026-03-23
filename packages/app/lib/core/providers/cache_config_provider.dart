import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'cache_config_provider.g.dart';

/// Configuração centralizada de cache para todo o app
/// 
/// Gerencia:
/// - TTLs por tipo de dado
/// - Limites de tamanho
/// - Flags de habilitação
/// - Persistência de preferências
/// 
/// Uso:
/// ```dart
/// final config = ref.watch(cacheConfigProvider);
/// final postTTL = config.postCacheTTL;
/// ```
@immutable
class CacheConfig {
  const CacheConfig({
    this.postCacheTTL = const Duration(minutes: 1),
    this.profileCacheTTL = const Duration(minutes: 5),
    this.notificationCacheTTL = const Duration(minutes: 1),
    this.messageCacheTTL = const Duration(seconds: 30),
    this.settingsCacheTTL = const Duration(minutes: 10),
    this.imageCacheMaxSizeMB = 200,
    this.imageCacheMaxAgeDays = 7,
    this.firestoreCacheMaxSizeMB = 100,
    this.enableOfflineMode = true,
    this.enableImageCache = true,
    this.enableFirestoreCache = true,
  });

  // ============================================
  // TTLs por tipo de dado
  // ============================================
  
  /// TTL para cache de posts/feed
  final Duration postCacheTTL;
  
  /// TTL para cache de perfis
  final Duration profileCacheTTL;
  
  /// TTL para cache de notificações
  final Duration notificationCacheTTL;
  
  /// TTL para cache de mensagens
  final Duration messageCacheTTL;
  
  /// TTL para cache de configurações
  final Duration settingsCacheTTL;

  // ============================================
  // Limites de tamanho
  // ============================================
  
  /// Tamanho máximo do cache de imagens (MB)
  final int imageCacheMaxSizeMB;
  
  /// Idade máxima de imagens em cache (dias)
  final int imageCacheMaxAgeDays;
  
  /// Tamanho máximo do cache Firestore (MB)
  final int firestoreCacheMaxSizeMB;

  // ============================================
  // Flags de habilitação
  // ============================================
  
  /// Habilita modo offline (Firestore persistence)
  final bool enableOfflineMode;
  
  /// Habilita cache de imagens
  final bool enableImageCache;
  
  /// Habilita cache do Firestore
  final bool enableFirestoreCache;

  // ============================================
  // Métodos utilitários
  // ============================================
  
  /// Cria cópia com valores modificados
  CacheConfig copyWith({
    Duration? postCacheTTL,
    Duration? profileCacheTTL,
    Duration? notificationCacheTTL,
    Duration? messageCacheTTL,
    Duration? settingsCacheTTL,
    int? imageCacheMaxSizeMB,
    int? imageCacheMaxAgeDays,
    int? firestoreCacheMaxSizeMB,
    bool? enableOfflineMode,
    bool? enableImageCache,
    bool? enableFirestoreCache,
  }) {
    return CacheConfig(
      postCacheTTL: postCacheTTL ?? this.postCacheTTL,
      profileCacheTTL: profileCacheTTL ?? this.profileCacheTTL,
      notificationCacheTTL: notificationCacheTTL ?? this.notificationCacheTTL,
      messageCacheTTL: messageCacheTTL ?? this.messageCacheTTL,
      settingsCacheTTL: settingsCacheTTL ?? this.settingsCacheTTL,
      imageCacheMaxSizeMB: imageCacheMaxSizeMB ?? this.imageCacheMaxSizeMB,
      imageCacheMaxAgeDays: imageCacheMaxAgeDays ?? this.imageCacheMaxAgeDays,
      firestoreCacheMaxSizeMB: firestoreCacheMaxSizeMB ?? this.firestoreCacheMaxSizeMB,
      enableOfflineMode: enableOfflineMode ?? this.enableOfflineMode,
      enableImageCache: enableImageCache ?? this.enableImageCache,
      enableFirestoreCache: enableFirestoreCache ?? this.enableFirestoreCache,
    );
  }
  
  /// Configuração para ambiente de desenvolvimento (mais agressiva)
  factory CacheConfig.development() {
    return const CacheConfig(
      postCacheTTL: Duration(minutes: 1),
      profileCacheTTL: Duration(minutes: 2),
      notificationCacheTTL: Duration(seconds: 30),
      messageCacheTTL: Duration(seconds: 15),
      settingsCacheTTL: Duration(minutes: 5),
      imageCacheMaxSizeMB: 100,
      imageCacheMaxAgeDays: 3,
      firestoreCacheMaxSizeMB: 50,
    );
  }
  
  /// Configuração para produção (mais conservadora)
  factory CacheConfig.production() {
    return const CacheConfig(
      // Mantém paridade com dev para reduzir sensação de “feed lento” em staging/prod.
      postCacheTTL: Duration(minutes: 1),
      profileCacheTTL: Duration(minutes: 5),
      notificationCacheTTL: Duration(minutes: 1),
      messageCacheTTL: Duration(seconds: 30),
      settingsCacheTTL: Duration(minutes: 10),
      imageCacheMaxSizeMB: 200,
      imageCacheMaxAgeDays: 7,
      firestoreCacheMaxSizeMB: 100,
    );
  }
  
  /// Informações para debugging
  Map<String, dynamic> toDebugMap() => {
    'postCacheTTL': '${postCacheTTL.inSeconds}s',
    'profileCacheTTL': '${profileCacheTTL.inSeconds}s',
    'notificationCacheTTL': '${notificationCacheTTL.inSeconds}s',
    'messageCacheTTL': '${messageCacheTTL.inSeconds}s',
    'settingsCacheTTL': '${settingsCacheTTL.inSeconds}s',
    'imageCacheMaxSizeMB': imageCacheMaxSizeMB,
    'imageCacheMaxAgeDays': imageCacheMaxAgeDays,
    'firestoreCacheMaxSizeMB': firestoreCacheMaxSizeMB,
    'enableOfflineMode': enableOfflineMode,
    'enableImageCache': enableImageCache,
    'enableFirestoreCache': enableFirestoreCache,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheConfig &&
        other.postCacheTTL == postCacheTTL &&
        other.profileCacheTTL == profileCacheTTL &&
        other.notificationCacheTTL == notificationCacheTTL &&
        other.messageCacheTTL == messageCacheTTL &&
        other.settingsCacheTTL == settingsCacheTTL &&
        other.imageCacheMaxSizeMB == imageCacheMaxSizeMB &&
        other.imageCacheMaxAgeDays == imageCacheMaxAgeDays &&
        other.firestoreCacheMaxSizeMB == firestoreCacheMaxSizeMB &&
        other.enableOfflineMode == enableOfflineMode &&
        other.enableImageCache == enableImageCache &&
        other.enableFirestoreCache == enableFirestoreCache;
  }

  @override
  int get hashCode => Object.hash(
    postCacheTTL,
    profileCacheTTL,
    notificationCacheTTL,
    messageCacheTTL,
    settingsCacheTTL,
    imageCacheMaxSizeMB,
    imageCacheMaxAgeDays,
    firestoreCacheMaxSizeMB,
    enableOfflineMode,
    enableImageCache,
    enableFirestoreCache,
  );
}

/// Provider de configuração de cache
/// 
/// Carrega configurações do SharedPreferences e permite
/// modificações em runtime.
@Riverpod(keepAlive: true)
class CacheConfigNotifier extends _$CacheConfigNotifier {
  static const String _prefsKeyPrefix = 'cache_config_';
  
  @override
  CacheConfig build() {
    // Carrega configuração inicial (pode ser async no futuro)
    _loadFromPrefs();
    
    // Retorna configuração padrão de produção
    return CacheConfig.production();
  }
  
  /// Carrega configurações salvas do SharedPreferences
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final enableOffline = prefs.getBool('${_prefsKeyPrefix}enableOfflineMode');
      final enableImageCache = prefs.getBool('${_prefsKeyPrefix}enableImageCache');
      final imageCacheMaxSize = prefs.getInt('${_prefsKeyPrefix}imageCacheMaxSizeMB');
      
      if (enableOffline != null || enableImageCache != null || imageCacheMaxSize != null) {
        state = state.copyWith(
          enableOfflineMode: enableOffline,
          enableImageCache: enableImageCache,
          imageCacheMaxSizeMB: imageCacheMaxSize,
        );
        debugPrint('📦 CacheConfig: Carregado do SharedPreferences');
      }
    } catch (e) {
      debugPrint('⚠️ CacheConfig: Erro ao carregar prefs: $e');
    }
  }
  
  /// Atualiza configuração e persiste
  Future<void> updateConfig(CacheConfig Function(CacheConfig) updater) async {
    final newConfig = updater(state);
    state = newConfig;
    
    await _saveToPrefs(newConfig);
    debugPrint('📦 CacheConfig: Atualizado e salvo');
  }
  
  /// Salva configurações no SharedPreferences
  Future<void> _saveToPrefs(CacheConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('${_prefsKeyPrefix}enableOfflineMode', config.enableOfflineMode);
      await prefs.setBool('${_prefsKeyPrefix}enableImageCache', config.enableImageCache);
      await prefs.setInt('${_prefsKeyPrefix}imageCacheMaxSizeMB', config.imageCacheMaxSizeMB);
    } catch (e) {
      debugPrint('⚠️ CacheConfig: Erro ao salvar prefs: $e');
    }
  }
  
  /// Habilita/desabilita modo offline
  Future<void> setOfflineMode(bool enabled) async {
    await updateConfig((c) => c.copyWith(enableOfflineMode: enabled));
  }
  
  /// Habilita/desabilita cache de imagens
  Future<void> setImageCache(bool enabled) async {
    await updateConfig((c) => c.copyWith(enableImageCache: enabled));
  }
  
  /// Define tamanho máximo do cache de imagens
  Future<void> setImageCacheMaxSize(int sizeMB) async {
    await updateConfig((c) => c.copyWith(imageCacheMaxSizeMB: sizeMB));
  }
  
  /// Reseta para configuração padrão
  Future<void> resetToDefaults() async {
    state = const CacheConfig();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefsKeyPrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
      debugPrint('📦 CacheConfig: Resetado para padrões');
    } catch (e) {
      debugPrint('⚠️ CacheConfig: Erro ao resetar prefs: $e');
    }
  }
  
  /// Aplica configuração de desenvolvimento
  void applyDevelopmentConfig() {
    state = CacheConfig.development();
    debugPrint('📦 CacheConfig: Aplicada configuração de desenvolvimento');
  }
  
  /// Aplica configuração de produção
  void applyProductionConfig() {
    state = CacheConfig.production();
    debugPrint('📦 CacheConfig: Aplicada configuração de produção');
  }
  
  /// Log informações de debug
  void printDebugInfo() {
    if (kDebugMode) {
      debugPrint('📦 CacheConfig Debug Info:');
      state.toDebugMap().forEach((key, value) {
        debugPrint('   $key: $value');
      });
    }
  }
}

/// Provider de conveniência para acessar TTLs específicos
@riverpod
Duration postCacheTTL(PostCacheTTLRef ref) {
  return ref.watch(cacheConfigNotifierProvider).postCacheTTL;
}

@riverpod
Duration profileCacheTTL(ProfileCacheTTLRef ref) {
  return ref.watch(cacheConfigNotifierProvider).profileCacheTTL;
}

@riverpod
Duration notificationCacheTTL(NotificationCacheTTLRef ref) {
  return ref.watch(cacheConfigNotifierProvider).notificationCacheTTL;
}

@riverpod
Duration messageCacheTTL(MessageCacheTTLRef ref) {
  return ref.watch(cacheConfigNotifierProvider).messageCacheTTL;
}
