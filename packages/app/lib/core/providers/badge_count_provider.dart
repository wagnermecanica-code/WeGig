import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

part 'badge_count_provider.g.dart';

/// Estado consolidado de badges (notificações + mensagens)
@immutable
class BadgeCounts {
  const BadgeCounts({
    this.unreadNotifications = 0,
    this.unreadMessages = 0,
    this.lastUpdate,
  });
  
  final int unreadNotifications;
  final int unreadMessages;
  final DateTime? lastUpdate;
  
  /// Total de badges não lidas
  int get total => unreadNotifications + unreadMessages;
  
  /// Tem alguma badge para mostrar
  bool get hasAny => total > 0;
  
  /// Texto formatado para exibição (ex: "99+" se > 99)
  String get formattedTotal {
    if (total == 0) return '';
    if (total > 99) return '99+';
    return total.toString();
  }
  
  String get formattedNotifications {
    if (unreadNotifications == 0) return '';
    if (unreadNotifications > 99) return '99+';
    return unreadNotifications.toString();
  }
  
  String get formattedMessages {
    if (unreadMessages == 0) return '';
    if (unreadMessages > 99) return '99+';
    return unreadMessages.toString();
  }
  
  BadgeCounts copyWith({
    int? unreadNotifications,
    int? unreadMessages,
    DateTime? lastUpdate,
  }) {
    return BadgeCounts(
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BadgeCounts &&
        other.unreadNotifications == unreadNotifications &&
        other.unreadMessages == unreadMessages;
  }

  @override
  int get hashCode => Object.hash(unreadNotifications, unreadMessages);
  
  @override
  String toString() => 'BadgeCounts(notifications: $unreadNotifications, messages: $unreadMessages)';
}

/// Provider de contagem de badges com invalidação automática
/// 
/// Funcionalidades:
/// - Contagem de notificações não lidas
/// - Contagem de mensagens não lidas
/// - Invalidação automática ao trocar perfil
/// - Cache com TTL de 30 segundos
/// - Streams do Firestore para atualizações em tempo real
/// 
/// Uso:
/// ```dart
/// final badges = ref.watch(badgeCountNotifierProvider);
/// if (badges.hasAny) {
///   // Mostrar badge no ícone
/// }
/// ```
@Riverpod(keepAlive: true)
class BadgeCountNotifier extends _$BadgeCountNotifier {
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  String? _currentProfileId;
  String? _currentAuthUid;
  
  @override
  BadgeCounts build() {
    // Observar mudanças no usuário autenticado
    ref.listen(currentUserProvider, (previous, next) {
      final newAuthUid = next?.uid;
      if (newAuthUid != _currentAuthUid) {
        debugPrint('🔔 BadgeCount: Auth mudou, reavaliando streams');
        _currentAuthUid = newAuthUid;
        _refreshStreamsFromCurrentState();
      }
    });

    // Observar mudanças no perfil ativo
    ref.listen(profileProvider, (previous, next) {
      _refreshStreamsFromCurrentState();
    });
    
    // Cleanup ao dispose
    ref.onDispose(() {
      _notificationsSubscription?.cancel();
      _messagesSubscription?.cancel();
      debugPrint('🔔 BadgeCountNotifier: Disposed');
    });
    
    // Setup inicial
    _currentAuthUid = ref.read(currentUserProvider)?.uid;
    _refreshStreamsFromCurrentState();
    
    return const BadgeCounts();
  }

  void _refreshStreamsFromCurrentState() {
    final authUid = ref.read(currentUserProvider)?.uid;
    final activeProfile = ref.read(profileProvider).value?.activeProfile;

    final eligibleProfileId = (authUid != null &&
            activeProfile != null &&
            activeProfile.uid == authUid)
        ? activeProfile.profileId
        : null;

    if (eligibleProfileId != _currentProfileId) {
      debugPrint('🔔 BadgeCount: Atualizando streams (profileId: $eligibleProfileId)');
      _currentProfileId = eligibleProfileId;
      _setupStreams(eligibleProfileId);
      return;
    }

    if (eligibleProfileId == null) {
      // Garante que, durante transições (logout/login/switch), não fiquem streams ativos.
      _setupStreams(null);
    }
  }
  
  /// Configura streams do Firestore para contagem em tempo real
  void _setupStreams(String? profileId) {
    // Cancelar streams anteriores
    _notificationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    
    if (profileId == null) {
      state = const BadgeCounts();
      return;
    }
    
    final firestore = FirebaseFirestore.instance;
    
    // Stream de notificações não lidas
    _notificationsSubscription = firestore
        .collection('profiles')
        .doc(profileId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
            state = state.copyWith(
              unreadNotifications: snapshot.docs.length,
              lastUpdate: DateTime.now(),
            );
            debugPrint('🔔 Badges: ${snapshot.docs.length} notificações não lidas');
          },
          onError: (e) {
            debugPrint('⚠️ BadgeCount: Erro em notifications stream - $e');
          },
        );
    
    // Stream de mensagens não lidas
    _messagesSubscription = firestore
        .collection('profiles')
        .doc(profileId)
        .collection('conversations')
        .where('unreadCount', isGreaterThan: 0)
        .snapshots()
        .listen(
          (snapshot) {
            // Somar unreadCount de todas as conversas
            int totalUnread = 0;
            for (final doc in snapshot.docs) {
              final data = doc.data();
              totalUnread += (data['unreadCount'] as int?) ?? 0;
            }
            
            state = state.copyWith(
              unreadMessages: totalUnread,
              lastUpdate: DateTime.now(),
            );
            debugPrint('💬 Badges: $totalUnread mensagens não lidas');
          },
          onError: (e) {
            debugPrint('⚠️ BadgeCount: Erro em messages stream - $e');
          },
        );
    
    debugPrint('🔔 BadgeCount: Streams configurados para $profileId');
  }
  
  /// Força atualização das contagens
  Future<void> refresh() async {
    _refreshStreamsFromCurrentState();
  }
  
  /// Invalida badges (zera contagens locais)
  /// 
  /// Útil ao trocar de perfil antes dos streams atualizarem
  void invalidate() {
    state = const BadgeCounts();
    debugPrint('🔔 BadgeCount: Invalidado');
  }
  
  /// Marca todas notificações como lidas (atualiza otimisticamente)
  void markAllNotificationsRead() {
    state = state.copyWith(unreadNotifications: 0);
    debugPrint('🔔 BadgeCount: Notificações marcadas como lidas (otimista)');
  }
  
  /// Marca mensagens de uma conversa como lidas
  void decrementMessages(int count) {
    final newCount = (state.unreadMessages - count).clamp(0, 999);
    state = state.copyWith(unreadMessages: newCount);
    debugPrint('💬 BadgeCount: -$count mensagens (total: $newCount)');
  }
}

/// Provider de conveniência para total de badges
@riverpod
int totalBadgeCount(TotalBadgeCountRef ref) {
  return ref.watch(badgeCountNotifierProvider).total;
}

/// Provider de conveniência para notificações não lidas
@riverpod
int unreadNotificationsCount(UnreadNotificationsCountRef ref) {
  return ref.watch(badgeCountNotifierProvider).unreadNotifications;
}

/// Provider de conveniência para mensagens não lidas
@riverpod
int unreadMessagesCount(UnreadMessagesCountRef ref) {
  return ref.watch(badgeCountNotifierProvider).unreadMessages;
}

/// Provider que indica se há badges para mostrar
@riverpod
bool hasBadges(HasBadgesRef ref) {
  return ref.watch(badgeCountNotifierProvider).hasAny;
}
