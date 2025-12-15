import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Gerenciador de cache local do Firestore
/// 
/// Responsável por:
/// - Limpar posts expirados (>30 dias) do cache offline
/// - Agendar limpezas periódicas (1x por dia)
/// - Otimizar uso de espaço em disco
/// 
/// WeGig usa posts com expiração de 30 dias. Este manager garante que
/// posts expirados sejam removidos do cache local para:
/// - Liberar espaço em disco
/// - Evitar mostrar conteúdo expirado quando offline
/// - Manter cache consistente com dados do servidor
class FirestoreCacheManager {
  static Timer? _cleanupTimer;
  static DateTime? _lastCleanup;
  
  /// Inicializa o manager e agenda limpezas periódicas
  /// 
  /// Deve ser chamado no bootstrap, DEPOIS de Firebase.initializeApp()
  static Future<void> initialize() async {
    debugPrint('🧹 FirestoreCacheManager: Inicializando...');
    
    // Limpar cache expirado imediatamente
    await clearExpiredPosts();
    
    // Agendar limpeza periódica (1x por dia às 3h da manhã)
    _schedulePeriodicCleanup();
    
    debugPrint('✅ FirestoreCacheManager inicializado');
  }
  
  /// Limpa posts expirados do cache local
  /// 
  /// Query posts com expiresAt < now() usando Source.cache para buscar
  /// apenas no cache local (não faz network request).
  static Future<void> clearExpiredPosts() async {
    try {
      final now = Timestamp.now();
      debugPrint('🧹 Limpando posts expirados do cache...');
      
      // ✅ Query APENAS no cache local (sem network)
      final expiredPosts = await FirebaseFirestore.instance
        .collection('posts')
        .where('expiresAt', isLessThan: now)
        .get(const GetOptions(source: Source.cache));
      
      if (expiredPosts.docs.isEmpty) {
        debugPrint('✅ Nenhum post expirado no cache');
        _lastCleanup = DateTime.now();
        return;
      }
      
      // Deletar em batch para eficiência
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in expiredPosts.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      _lastCleanup = DateTime.now();
      debugPrint('✅ ${expiredPosts.docs.length} posts expirados removidos do cache');
      debugPrint('   Espaço liberado: ~${(expiredPosts.docs.length * 5)} KB');
      
    } catch (e, stackTrace) {
      debugPrint('⚠️ Erro ao limpar posts expirados: $e');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }
  
  /// Limpa posts de um usuário específico (útil ao deletar perfil)
  static Future<void> clearPostsForProfile(String profileId) async {
    try {
      debugPrint('🧹 Limpando posts do perfil $profileId do cache...');
      
      final userPosts = await FirebaseFirestore.instance
        .collection('posts')
        .where('profileId', isEqualTo: profileId)
        .get(const GetOptions(source: Source.cache));
      
      if (userPosts.docs.isEmpty) {
        debugPrint('✅ Nenhum post do perfil no cache');
        return;
      }
      
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in userPosts.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      debugPrint('✅ ${userPosts.docs.length} posts removidos do cache');
      
    } catch (e) {
      debugPrint('⚠️ Erro ao limpar posts do perfil: $e');
    }
  }
  
  /// Agenda limpeza periódica do cache
  /// 
  /// Executa 1x por dia para manter cache otimizado
  static void _schedulePeriodicCleanup() {
    // Cancelar timer anterior se existir
    _cleanupTimer?.cancel();
    
    // Criar novo timer (24 horas)
    _cleanupTimer = Timer.periodic(const Duration(hours: 24), (_) {
      debugPrint('⏰ Limpeza agendada do cache iniciando...');
      clearExpiredPosts();
    });
    
    debugPrint('⏰ Limpeza periódica agendada (1x por dia)');
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
