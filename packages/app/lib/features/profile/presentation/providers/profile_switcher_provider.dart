import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';
import 'package:wegig_app/features/post/presentation/providers/post_cache_provider.dart';
import 'package:wegig_app/features/post/presentation/providers/post_providers.dart';
import 'package:wegig_app/features/post/presentation/providers/interest_providers.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

part 'profile_switcher_provider.g.dart';

/// Gerenciador centralizado de troca de perfil
/// 
/// Responsável por:
/// - Executar troca de perfil via ProfileNotifier
/// - Invalidar TODOS os caches relacionados (posts, notificações, mensagens)
/// - Atualizar Analytics com perfil ativo
/// - Garantir consistência de dados entre perfis
/// 
/// Benefícios:
/// - Um único ponto de controle para troca de perfil
/// - Impossível esquecer de invalidar algum cache
/// - Fácil adicionar novos providers no futuro
/// - Logs centralizados para debugging
@riverpod
class ProfileSwitcherNotifier extends _$ProfileSwitcherNotifier {
  @override
  void build() {
    // Stateless - apenas executa ações
  }

  /// Troca para o perfil especificado e invalida todos os caches
  /// 
  /// Sequence:
  /// 1. Executa troca via ProfileNotifier
  /// 2. Invalida cache de posts (feed limpo para novo perfil)
  /// 3. Atualiza Analytics
  /// 
  /// NOTA: Token FCM NÃO é removido do perfil antigo.
  /// O token é mantido em TODOS os perfis do usuário para que
  /// push notifications cheguem independente do perfil ativo.
  /// 
  /// [profileId] ID do perfil de destino (não o uid do usuário)
  Future<void> switchToProfile(String profileId) async {
    final startTime = DateTime.now();
    
    try {
      debugPrint('🔄 ProfileSwitcher: Iniciando troca para perfil $profileId');
      
      // 1. ✅ Trocar perfil (atualiza Firestore + estado local)
      await ref.read(profileProvider.notifier).switchProfile(profileId);
      debugPrint('   ✅ Perfil trocado no ProfileNotifier');
      
      // 2. ✅ Invalidar cache de posts
      ref.read(postCacheNotifierProvider.notifier).invalidate();
      ref.invalidate(postNotifierProvider);
      // 2.1 ✅ Invalidar interesses (depende do perfil ativo)
      ref.invalidate(interestNotifierProvider);
      // 2.2 ✅ Limpar streams compartilhados de bloqueio
      BlockedRelations.clearStreamCache();
      debugPrint('   ✅ Cache de posts e streams de bloqueio invalidados');
      
      // 3. ✅ Invalidar providers de notificações e mensagens
      // Nota: Estes providers usam activeProfile, serão automaticamente
      // recarregados quando profileProvider mudar
      debugPrint('   ✅ Notificações e mensagens serão recarregadas automaticamente');
      
      // 4. ✅ Token FCM: NÃO remover do perfil antigo!
      // O token é mantido em TODOS os perfis para que push notifications
      // cheguem independente do perfil ativo.
      debugPrint('   ✅ Token FCM mantido em todos os perfis');
      
      // 5. ✅ Atualizar Analytics
      await _updateAnalytics(profileId);
      
      final elapsed = DateTime.now().difference(startTime);
      debugPrint('✅ ProfileSwitcher: Troca completa em ${elapsed.inMilliseconds}ms');
      
      // 7. ✅ Log evento para analytics
      await FirebaseAnalytics.instance.logEvent(
        name: 'profile_switched',
        parameters: {
          'profile_id': profileId,
          'switch_duration_ms': elapsed.inMilliseconds,
        },
      );
      
    } catch (e, stackTrace) {
      debugPrint('❌ ProfileSwitcher: Erro ao trocar perfil - $e');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
      
      // Log erro no Analytics
      await FirebaseAnalytics.instance.logEvent(
        name: 'profile_switch_error',
        parameters: {
          'profile_id': profileId,
          'error': e.toString(),
        },
      );
      
      rethrow;
    }
  }
  
  /// Atualiza Firebase Analytics com novo perfil ativo
  /// 
  /// Define user property 'active_profile_id' para segmentação
  /// nos dashboards do Analytics
  Future<void> _updateAnalytics(String profileId) async {
    try {
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'active_profile_id',
        value: profileId,
      );
      debugPrint('   ✅ Analytics atualizado: active_profile_id=$profileId');
    } catch (e) {
      debugPrint('   ⚠️ Erro ao atualizar Analytics: $e');
      // Não faz rethrow - falha em analytics não deve bloquear troca
    }
  }
  
  /// Força invalidação de TODOS os caches sem trocar perfil
  /// 
  /// Útil para:
  /// - Pull-to-refresh global
  /// - Após criar/editar conteúdo importante
  /// - Recovery de estado inconsistente
  Future<void> refreshAllCaches() async {
    debugPrint('🔄 ProfileSwitcher: Invalidando todos os caches...');
    
    ref.read(postCacheNotifierProvider.notifier).invalidate();
    ref.invalidate(postNotifierProvider);
    ref.invalidate(interestNotifierProvider);
    
    debugPrint('✅ ProfileSwitcher: Todos os caches invalidados');
    
    await FirebaseAnalytics.instance.logEvent(
      name: 'caches_refreshed',
      parameters: {'source': 'manual'},
    );
  }
}
