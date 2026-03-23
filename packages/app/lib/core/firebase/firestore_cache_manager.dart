import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Gerenciador de cache local do Firestore
/// 
/// Responsável por:
/// - Contar posts expirados no cache offline (para analytics)
/// - Agendar verificações periódicas (1x por dia)
/// 
/// ⚠️ IMPORTANTE: O Firestore SDK NÃO suporta "delete from cache only".
/// WriteBatch.commit() SEMPRE envia deletes ao servidor, mesmo quando a
/// query original usou Source.cache. Por isso, este manager NÃO deleta
/// posts expirados — a filtragem é feita nas queries do app
/// (where expiresAt > now) e os posts expirados saem naturalmente do
/// cache conforme o LRU do Firestore descarta documentos antigos.
///
/// Posts expirados permanecem no Firestore intencionalmente para que o
/// owner os visualize na ViewProfilePage (histórico de posts).
class FirestoreCacheManager {
  static Timer? _cleanupTimer;
  static DateTime? _lastCleanup;
  
  /// Inicializa o manager e agenda verificações periódicas
  /// 
  /// Deve ser chamado no bootstrap, DEPOIS de Firebase.initializeApp()
  static Future<void> initialize() async {
    debugPrint('🧹 FirestoreCacheManager: Inicializando...');
    
    // Apenas logar stats, NÃO deletar posts
    await _logExpiredPostsStats();
    
    // Agendar verificação periódica
    _schedulePeriodicCleanup();
    
    debugPrint('✅ FirestoreCacheManager inicializado');
  }
  
  /// Loga estatísticas de posts expirados no cache (sem deletar nada)
  /// 
  /// ⚠️ NÃO deleta posts — batch.delete() + commit() enviaria deletes
  /// ao servidor Firestore, removendo posts que o owner precisa ver.
  static Future<void> _logExpiredPostsStats() async {
    try {
      final now = Timestamp.now();
      
      // Query APENAS no cache local (sem network)
      final expiredPosts = await FirebaseFirestore.instance
        .collection('posts')
        .where('expiresAt', isLessThan: now)
        .get(const GetOptions(source: Source.cache));
      
      _lastCleanup = DateTime.now();
      
      if (expiredPosts.docs.isEmpty) {
        debugPrint('✅ Nenhum post expirado no cache');
      } else {
        debugPrint('ℹ️ ${expiredPosts.docs.length} posts expirados no cache (não deletados — filtrados via query)');
      }
      
    } catch (e, stackTrace) {
      debugPrint('⚠️ Erro ao verificar posts expirados: $e');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  /// Mantido para compatibilidade — agora é no-op seguro.
  /// 
  /// ⚠️ Antes este método usava batch.delete() + commit() que
  /// deletava posts do servidor real (bug crítico). Agora apenas loga.
  static Future<void> clearExpiredPosts() async {
    await _logExpiredPostsStats();
  }
  
  /// Limpa referências de posts de um perfil do cache local
  /// 
  /// ⚠️ NÃO deleta do servidor — apenas loga para diagnóstico.
  /// Antes usava batch.delete() + commit() que deletava do servidor real.
  static Future<void> clearPostsForProfile(String profileId) async {
    try {
      debugPrint('ℹ️ clearPostsForProfile($profileId) — no-op (posts não são deletados do servidor)');
    } catch (e) {
      debugPrint('⚠️ Erro em clearPostsForProfile: $e');
    }
  }
  
  /// Agenda verificação periódica do cache
  /// 
  /// Executa 1x por dia para logar stats
  static void _schedulePeriodicCleanup() {
    // Cancelar timer anterior se existir
    _cleanupTimer?.cancel();
    
    // Criar novo timer (24 horas)
    _cleanupTimer = Timer.periodic(const Duration(hours: 24), (_) {
      debugPrint('⏰ Verificação agendada do cache iniciando...');
      _logExpiredPostsStats();
    });
    
    debugPrint('⏰ Verificação periódica agendada (1x por dia)');
  }
  
  /// Limpa TODO o cache do Firestore (útil para debugging)
  /// 
  /// ⚠️ ATENÇÃO: Só funciona em debug mode e requer restart do app
  static Future<void> clearAllCache() async {
    if (!kDebugMode) {
      debugPrint('⚠️ clearAllCache() bloqueado em release mode');
      return;
    }
    
    try {
      await FirebaseFirestore.instance.clearPersistence();
      debugPrint('✅ Todo o cache Firestore foi limpo');
      debugPrint('   ⚠️ Reinicie o app para aplicar mudanças');
    } catch (e) {
      debugPrint('❌ Erro ao limpar cache: $e');
      debugPrint('   Firestore já está em uso. Reinicie o app e tente novamente.');
    }
  }
  
  /// Obtém estatísticas do cache (útil para analytics)
  static Future<CacheStats> getCacheStats() async {
    try {
      // Contar documentos no cache
      final posts = await FirebaseFirestore.instance
        .collection('posts')
        .get(const GetOptions(source: Source.cache));
      
      final expiredPosts = await FirebaseFirestore.instance
        .collection('posts')
        .where('expiresAt', isLessThan: Timestamp.now())
        .get(const GetOptions(source: Source.cache));
      
      return CacheStats(
        totalPosts: posts.docs.length,
        expiredPosts: expiredPosts.docs.length,
        lastCleanup: _lastCleanup,
      );
    } catch (e) {
      debugPrint('⚠️ Erro ao obter stats do cache: $e');
      return CacheStats(
        totalPosts: 0,
        expiredPosts: 0,
        lastCleanup: _lastCleanup,
      );
    }
  }
  
  /// Cancela limpezas agendadas (chamado no dispose do app)
  static void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    debugPrint('🛑 FirestoreCacheManager disposed');
  }
}

/// Estatísticas do cache local
class CacheStats {
  final int totalPosts;
  final int expiredPosts;
  final DateTime? lastCleanup;
  
  CacheStats({
    required this.totalPosts,
    required this.expiredPosts,
    this.lastCleanup,
  });
  
  int get validPosts => totalPosts - expiredPosts;
  
  double get expirationRate => 
    totalPosts > 0 ? (expiredPosts / totalPosts) * 100 : 0;
  
  @override
  String toString() {
    return 'CacheStats(total: $totalPosts, válidos: $validPosts, '
           'expirados: $expiredPosts, taxa: ${expirationRate.toStringAsFixed(1)}%)';
  }
}
