import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Service para gerenciar Push Notifications via Firebase Cloud Messaging
///
/// Responsabilidades:
/// - Inicializar Firebase Messaging
/// - Gerenciar permissões de notificações
/// - Salvar/remover tokens FCM no Firestore
/// - Configurar handlers de foreground/background
/// - Integrar com sistema multi-perfil
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService _instance =
      PushNotificationService._();
  factory PushNotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentToken;
  String? _currentProfileId;

  /// Callback quando notificação é clicada (app terminated/background)
  void Function(RemoteMessage)? onNotificationTapped;

  /// Callback quando notificação é recebida (foreground)
  void Function(RemoteMessage)? onForegroundMessage;

  /// Inicializa o serviço de push notifications
  ///
  /// Deve ser chamado no main.dart APÓS Firebase.initializeApp()
  /// ```dart
  /// await PushNotificationService().initialize();
  /// ```
  Future<void> initialize() async {
    try {
      // Configurar handlers
      _setupMessageHandlers();

      // Escutar mudanças de token (refresh automático FCM)
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 PushNotificationService: Token refreshed');
        _currentToken = newToken;
        
        // Atualizar token no Firestore se perfil ativo existe
        if (_currentProfileId != null) {
          saveTokenForProfile(_currentProfileId!);
        }
      });

      debugPrint('✅ PushNotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('❌ PushNotificationService: Initialization error: $e');
    }
  }

  /// Configura handlers de mensagens (foreground, background, terminated)
  void _setupMessageHandlers() {
    // Foreground: app aberto
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 PushNotificationService: Message received (foreground)');
      debugPrint('   Title: ${message.notification?.title}');
      debugPrint('   Body: ${message.notification?.body}');
      debugPrint('   Data: ${message.data}');

      // Callback customizado
      onForegroundMessage?.call(message);
    });

    // Background/Terminated: app minimizado ou fechado
    // Quando usuário clica na notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 PushNotificationService: Notification tapped (background)');
      debugPrint('   Type: ${message.data['type']}');
      
      // Callback para navegação
      onNotificationTapped?.call(message);
    });

    // Terminated: app estava fechado e foi aberto pela notificação
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
            '👆 PushNotificationService: Notification tapped (terminated)');
        debugPrint('   Type: ${message.data['type']}');
        
        // Callback para navegação
        onNotificationTapped?.call(message);
      }
    });
  }

  /// Solicita permissão para enviar notificações
  ///
  /// Android: Concedido automaticamente até API 32 (Android 12L)
  /// Android 13+: Solicita permissão POST_NOTIFICATIONS
  /// iOS: Sempre solicita permissão
  ///
  /// ```dart
  /// final settings = await service.requestPermission();
  /// if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  ///   // Permissão concedida
  /// }
  /// ```
  Future<NotificationSettings> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📱 PushNotificationService: Permission status: '
          '${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ PushNotificationService: Permission granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ PushNotificationService: Provisional permission');
      } else {
        debugPrint('❌ PushNotificationService: Permission denied');
      }

      return settings;
    } catch (e) {
      debugPrint('❌ PushNotificationService: Permission error: $e');
      rethrow;
    }
  }

  /// Obtém o status atual de permissões
  Future<NotificationSettings> getNotificationSettings() async {
    return await _messaging.getNotificationSettings();
  }

  /// Obtém o token FCM atual
  ///
  /// Retorna null se token não pôde ser gerado (sem permissão, etc)
  Future<String?> getToken() async {
    try {
      if (_currentToken != null) return _currentToken;

      _currentToken = await _messaging.getToken();
      
      if (_currentToken != null) {
        debugPrint('🔑 PushNotificationService: Token obtained');
        debugPrint('   Token: ${_currentToken!.substring(0, 20)}...');
      } else {
        debugPrint('⚠️ PushNotificationService: Token is null');
      }

      return _currentToken;
    } catch (e) {
      debugPrint('❌ PushNotificationService: Get token error: $e');
      return null;
    }
  }

  /// Salva token FCM para um perfil específico no Firestore
  ///
  /// Estrutura: profiles/{profileId}/fcmTokens/{token}
  /// ```dart
  /// await service.saveTokenForProfile(activeProfile.profileId);
  /// ```
  Future<void> saveTokenForProfile(String profileId) async {
    try {
      final token = await getToken();
      if (token == null) {
        debugPrint('⚠️ PushNotificationService: Cannot save null token');
        return;
      }

      _currentProfileId = profileId;

      // Salvar token no Firestore
      await _firestore
          .collection('profiles')
          .doc(profileId)
          .collection('fcmTokens')
          .doc(token)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.name.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('💾 PushNotificationService: Token saved for profile: '
          '$profileId');
    } catch (e) {
      debugPrint('❌ PushNotificationService: Save token error: $e');
    }
  }

  /// Remove token FCM de um perfil específico
  ///
  /// Útil ao fazer logout ou trocar de perfil
  Future<void> removeTokenFromProfile(String profileId) async {
    try {
      final token = _currentToken ?? await getToken();
      if (token == null) return;

      await _firestore
          .collection('profiles')
          .doc(profileId)
          .collection('fcmTokens')
          .doc(token)
          .delete();

      debugPrint('🗑️ PushNotificationService: Token removed from profile: '
          '$profileId');
    } catch (e) {
      debugPrint('❌ PushNotificationService: Remove token error: $e');
    }
  }

  /// Remove token de TODOS os perfis
  ///
  /// Chamado ao fazer logout completo
  Future<void> removeTokenFromAllProfiles(List<String> profileIds) async {
    for (final profileId in profileIds) {
      await removeTokenFromProfile(profileId);
    }
    
    _currentProfileId = null;
    debugPrint('🗑️ PushNotificationService: Token removed from all profiles');
  }

  /// Troca de perfil: remove token do antigo e adiciona no novo
  ///
  /// ```dart
  /// await service.switchProfile(
  ///   oldProfileId: 'old123',
  ///   newProfileId: 'new456',
  /// );
  /// ```
  Future<void> switchProfile({
    required String? oldProfileId,
    required String newProfileId,
  }) async {
    if (oldProfileId != null) {
      await removeTokenFromProfile(oldProfileId);
    }
    await saveTokenForProfile(newProfileId);
    
    debugPrint('🔄 PushNotificationService: Switched profile: '
        '$oldProfileId → $newProfileId');
  }

  /// Subscreve a um tópico FCM
  ///
  /// Útil para notificações broadcast (ex: "all_users")
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('📢 PushNotificationService: Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ PushNotificationService: Subscribe error: $e');
    }
  }

  /// Cancela subscrição de um tópico FCM
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('🔕 PushNotificationService: Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ PushNotificationService: Unsubscribe error: $e');
    }
  }

  /// Limpa todos os dados do service (logout)
  void clear() {
    _currentToken = null;
    _currentProfileId = null;
    onNotificationTapped = null;
    onForegroundMessage = null;
    debugPrint('🧹 PushNotificationService: Cleared');
  }
}
