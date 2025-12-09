import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Configuração de cache do Firestore isolada por flavor/ambiente
/// 
/// WeGig usa 3 ambientes Firebase separados:
/// - Dev: wegig-dev
/// - Staging: wegig-staging  
/// - Prod: to-sem-banda-83e19
/// 
/// O cache é automaticamente isolado por Google App ID, mas esta classe
/// adiciona validações extras e logs para garantir isolamento total.
class FirebaseCacheConfig {
  /// Configura cache do Firestore por flavor
  /// 
  /// IMPORTANTE: Deve ser chamado DEPOIS de Firebase.initializeApp()
  /// pois FirebaseFirestore.instance requer Firebase já inicializado.
  static Future<void> configure(String flavor) async {
    final firestore = FirebaseFirestore.instance;
    
    // Configurar cache com tamanhos apropriados por ambiente
    // Nota: clearPersistence() removido pois causa crash se Firestore
    // já foi acessado. O cache já é isolado por App ID automaticamente.
    firestore.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: _getCacheSizeForFlavor(flavor),
    );
    
    // Log detalhado para debugging
    final cacheSize = _getCacheSizeForFlavor(flavor) ~/ (1024 * 1024);
    debugPrint('🔥 Firestore cache configurado:');
    debugPrint('   - Flavor: $flavor');
    debugPrint('   - Projeto: ${_getProjectIdForFlavor(flavor)}');
    debugPrint('   - Cache size: ${cacheSize}MB');
    debugPrint('   - Persistence: ENABLED');
  }
  
  /// Tamanho do cache por ambiente
  /// 
  /// - Dev: 50MB (menos posts, perfis de teste)
  /// - Staging: 75MB (volume intermediário)
  /// - Prod: 100MB (volume completo de usuários)
  static int _getCacheSizeForFlavor(String flavor) {
    switch (flavor) {
      case 'dev':
        return 50 * 1024 * 1024; // 50MB
      case 'staging':
        return 75 * 1024 * 1024; // 75MB
      case 'prod':
        return 100 * 1024 * 1024; // 100MB
      default:
        debugPrint('⚠️ Flavor desconhecido: $flavor, usando 100MB');
        return 100 * 1024 * 1024;
    }
  }
  
  /// Project ID esperado por flavor (para validação em logs)
  static String _getProjectIdForFlavor(String flavor) {
    switch (flavor) {
      case 'dev':
        return 'wegig-dev';
      case 'staging':
        return 'wegig-staging';
      case 'prod':
        return 'to-sem-banda-83e19';
      default:
        return 'unknown';
    }
  }
  
  /// Valida que o projeto Firebase carregado corresponde ao flavor esperado
  /// 
  /// Deve ser chamado DEPOIS de Firebase.initializeApp() para verificar
  /// que o projeto correto foi inicializado.
  static void validateEnvironment(String flavor, String actualProjectId) {
    final expectedProjectId = _getProjectIdForFlavor(flavor);
    
    debugPrint('🔍 Firebase Environment Validation:');
    debugPrint('   Flavor: $flavor');
    debugPrint('   Expected Project: $expectedProjectId');
    debugPrint('   Actual Project: $actualProjectId');
    
    if (actualProjectId != expectedProjectId) {
      debugPrint('❌ ERRO CRÍTICO: Projeto Firebase incorreto!');
      debugPrint('   ⚠️ Dados serão salvos no projeto ERRADO!');
      debugPrint('   ⚠️ Verifique firebase_options_$flavor.dart');
      debugPrint('   ⚠️ Verifique GoogleService-Info.plist no Xcode');
      
      // Em debug, lança erro para forçar correção
      if (kDebugMode) {
        throw StateError(
          'ERRO CRÍTICO: Projeto Firebase incorreto para flavor $flavor!\n'
          'Esperado: $expectedProjectId\n'
          'Atual: $actualProjectId\n'
          'Dados iriam para o ambiente errado!',
        );
      }
    } else {
      debugPrint('✅ Projeto Firebase CORRETO: $actualProjectId');
    }
  }
  
  /// Força limpeza completa do cache (útil para debugging)
  /// 
  /// ⚠️ Só deve ser usado em desenvolvimento, nunca em produção.
  static Future<void> forceClearCache() async {
    if (!kDebugMode) {
      debugPrint('⚠️ forceClearCache() ignorado em release mode');
      return;
    }
    
    try {
      await FirebaseFirestore.instance.clearPersistence();
      debugPrint('✅ Cache Firestore completamente limpo');
    } catch (e) {
      debugPrint('❌ Erro ao limpar cache: $e');
      debugPrint('   Reinicie o app para limpar o cache');
    }
  }
}
