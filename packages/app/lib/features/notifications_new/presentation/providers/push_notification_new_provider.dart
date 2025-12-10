/// WeGig - Push Notification Provider
///
/// Provider Riverpod para estado de Push Notifications.
/// Parte da nova feature NotificationsNew.
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegig_app/features/notifications_new/data/services/push_notification_service.dart';

/// Estado do PushNotificationService
class PushNotificationNewState {
  const PushNotificationNewState({
    required this.isInitialized,
    required this.hasPermission,
    required this.token,
    this.lastMessage,
    this.lastTappedNotification,
  });

  final bool isInitialized;
  final bool hasPermission;
  final String? token;
  final RemoteMessage? lastMessage;
  final RemoteMessage? lastTappedNotification;

  PushNotificationNewState copyWith({
    bool? isInitialized,
    bool? hasPermission,
    String? token,
    RemoteMessage? lastMessage,
    RemoteMessage? lastTappedNotification,
  }) {
    return PushNotificationNewState(
      isInitialized: isInitialized ?? this.isInitialized,
      hasPermission: hasPermission ?? this.hasPermission,
      token: token ?? this.token,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTappedNotification:
          lastTappedNotification ?? this.lastTappedNotification,
    );
  }

  factory PushNotificationNewState.initial() {
    return const PushNotificationNewState(
      isInitialized: false,
      hasPermission: false,
      token: null,
    );
  }
}

/// Provider do PushNotificationService (Singleton)
/// 
/// Usado diretamente quando precisa acessar o service sem estado.
/// Exemplo: settings_page para solicitar permissões.
final pushNotificationNewServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

/// Provider do estado de Push Notifications
final pushNotificationNewProvider =
    StateNotifierProvider<PushNotificationNewNotifier, PushNotificationNewState>(
  (ref) => PushNotificationNewNotifier(ref),
);

/// Provider para última mensagem recebida (foreground)
final lastReceivedMessageNewProvider = Provider<RemoteMessage?>((ref) {
  final state = ref.watch(pushNotificationNewProvider);
  return state.lastMessage;
});

/// Provider para última notificação clicada
final lastTappedNotificationNewProvider = Provider<RemoteMessage?>((ref) {
  final state = ref.watch(pushNotificationNewProvider);
  return state.lastTappedNotification;
});

/// Notifier para gerenciar estado de Push Notifications
class PushNotificationNewNotifier
    extends StateNotifier<PushNotificationNewState> {
  PushNotificationNewNotifier(this.ref)
      : super(PushNotificationNewState.initial());

  final Ref ref;

  /// Inicializa push notifications
  Future<void> initialize() async {
    final service = PushNotificationService();

    // Configurar callbacks
    service.onForegroundMessage = _handleForegroundMessage;
    service.onNotificationTapped = _handleNotificationTapped;

    // Inicializar
    await service.initialize();

    // Obter token
    final token = await service.getToken();

    // Verificar permissões
    final settings = await service.getNotificationSettings();
    final hasPermission =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    state = state.copyWith(
      isInitialized: true,
      hasPermission: hasPermission,
      token: token,
    );

    debugPrint('✅ PushNotificationNewProvider: Initialized');
  }

  /// Solicita permissão
  Future<bool> requestPermission() async {
    final service = PushNotificationService();
    final settings = await service.requestPermission();

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized;

    if (granted) {
      final token = await service.getToken();
      state = state.copyWith(
        hasPermission: true,
        token: token,
      );
    }

    return granted;
  }

  /// Salva token para perfil
  Future<void> saveTokenForProfile(String profileId) async {
    final service = PushNotificationService();
    await service.saveTokenForProfile(profileId);
  }

  /// Remove token de perfil
  Future<void> removeTokenFromProfile(String profileId) async {
    final service = PushNotificationService();
    await service.removeTokenFromProfile(profileId);
  }

  /// Troca de perfil
  Future<void> switchProfile({
    required String? oldProfileId,
    required String newProfileId,
  }) async {
    final service = PushNotificationService();
    await service.switchProfile(
      oldProfileId: oldProfileId,
      newProfileId: newProfileId,
    );
  }

  /// Limpa estado (logout)
  void clear() {
    final service = PushNotificationService();
    service.clear();
    state = PushNotificationNewState.initial();
  }

  /// Handler de mensagens em foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 PushNotificationNewProvider: Foreground message');
    state = state.copyWith(lastMessage: message);
  }

  /// Handler de notificação clicada
  void _handleNotificationTapped(RemoteMessage message) {
    debugPrint('👆 PushNotificationNewProvider: Notification tapped');
    state = state.copyWith(lastTappedNotification: message);
  }
}
