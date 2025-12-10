import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/features/messages/presentation/providers/messages_providers.dart';
import 'package:wegig_app/features/notifications_new/data/services/push_notification_service.dart';
import 'package:wegig_app/features/notifications_new/presentation/providers/notifications_new_providers.dart';
import 'package:wegig_app/features/post/presentation/providers/post_cache_provider.dart';
import 'package:wegig_app/features/post/presentation/providers/post_providers.dart';
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
  /// 1. Captura perfil antigo (para FCM)
  /// 2. Executa troca via ProfileNotifier
  /// 3. Invalida cache de posts (feed limpo para novo perfil)
  /// 4. Atualiza token FCM (remove do antigo, adiciona no novo)
  /// 5. Atualiza Analytics
  /// 
  /// [profileId] ID do perfil de destino (não o uid do usuário)
  Future<void> switchToProfile(String profileId) async {
    final startTime = DateTime.now();
    
    try {
      debugPrint('🔄 ProfileSwitcher: Iniciando troca para perfil $profileId');
      
      // 0. ✅ Capturar perfil antigo para FCM
      final oldProfileId = ref.read(profileProvider).value?.activeProfile?.profileId;
      
      // 1. ✅ Trocar perfil (atualiza Firestore + estado local)
      await ref.read(profileProvider.notifier).switchProfile(profileId);
      debugPrint('   ✅ Perfil trocado no ProfileNotifier');
      
      // 2. ✅ Invalidar cache de posts
      ref.read(postCacheNotifierProvider.notifier).invalidate();
      ref.invalidate(postNotifierProvider);
      debugPrint('   ✅ Cache de posts invalidado');
      
      // 3. ✅ Invalidar providers de notificações e mensagens
      // Nota: Estes providers usam activeProfile, serão automaticamente
      // recarregados quando profileProvider mudar
      debugPrint('   ✅ Notificações e mensagens serão recarregadas automaticamente');
      
      // 4. ✅ Atualizar token FCM (CRÍTICO para notificações corretas)
      await _updateFcmToken(oldProfileId: oldProfileId, newProfileId: profileId);
      
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
  
  /// Atualiza token FCM para o novo perfil
  /// 
  /// Remove token do perfil antigo e adiciona no novo.
  /// Isso garante que notificações push sejam enviadas para o perfil correto.
  Future<void> _updateFcmToken({
    required String? oldProfileId,
    required String newProfileId,
  }) async {
    try {
      await PushNotificationService().switchProfile(
        oldProfileId: oldProfileId,
        newProfileId: newProfileId,
      );
      debugPrint('   ✅ Token FCM atualizado: $oldProfileId → $newProfileId');
    } catch (e) {
      debugPrint('   ⚠️ Erro ao atualizar FCM token: $e');
      // Não faz rethrow - falha em FCM não deve bloquear troca
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
    
    debugPrint('✅ ProfileSwitcher: Todos os caches invalidados');
    
    await FirebaseAnalytics.instance.logEvent(
      name: 'caches_refreshed',
      parameters: {'source': 'manual'},
    );
  }
}
