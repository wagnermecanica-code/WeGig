/// WeGig - Push Notification Service
///
/// Service para gerenciar Push Notifications via Firebase Cloud Messaging.
/// Este serviço é INFRAESTRUTURA (não UI de notificações).
///
/// Responsabilidades:
/// - Inicializar Firebase Messaging
/// - Gerenciar permissões de notificações
/// - Salvar/remover tokens FCM no Firestore
/// - Configurar handlers de foreground/background
/// - Integrar com sistema multi-perfil
/// - Criar canal de notificação de alta importância (Android)
library;

import 'dart:io' show Platform;
import 'dart:math' show min;
import 'dart:ui' show Color;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  /// Canal de notificação de alta importância (Android)
  /// DEVE corresponder ao channelId usado nas Cloud Functions
  static const String _highImportanceChannelId = 'high_importance_channel';
  static const String _highImportanceChannelName = 'Notificações Importantes';
  static const String _highImportanceChannelDesc = 
      'Canal para notificações de posts próximos, interesses e mensagens';

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
    debugPrint('🔔 PushNotificationService: Iniciando initialize()...');
    try {
      // ANDROID CRÍTICO: Criar canal ANTES de qualquer outra operação FCM
      // O canal DEVE existir antes de receber qualquer notificação
      if (Platform.isAndroid) {
        debugPrint('🔔 PushNotificationService: [Android] Criando canal de notificação PRIMEIRO...');
        await _createNotificationChannel();
        debugPrint('✅ PushNotificationService: [Android] Canal criado com sucesso');
      }
      
      // CRÍTICO: Configurar como as notificações devem ser apresentadas quando app está em foreground
      // Isso garante que o FCM entregue as mensagens corretamente
      debugPrint('🔔 PushNotificationService: Configurando foreground presentation options...');
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,  // Mostrar alerta
        badge: true,  // Mostrar badge
        sound: true,  // Tocar som
      );
      debugPrint('✅ PushNotificationService: Foreground options configuradas');
      
      // Configurar handlers
      debugPrint('🔔 PushNotificationService: Configurando message handlers...');
      _setupMessageHandlers();

      // Escutar mudanças de token (refresh automático FCM)
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 PushNotificationService: Token refreshed: ${newToken.substring(0, min(20, newToken.length))}...');
        _currentToken = newToken;
        
        // Atualizar token no Firestore se perfil ativo existe
        if (_currentProfileId != null) {
          saveTokenForProfile(_currentProfileId!);
        }
      });

      debugPrint('✅ PushNotificationService: Initialized successfully');
      
      // Executar diagnóstico automaticamente em debug
      await runDiagnostics();
    } catch (e, stack) {
      debugPrint('❌ PushNotificationService: Initialization error: $e');
      debugPrint('❌ PushNotificationService: Stack: $stack');
    }
  }

  /// Cria canal de notificação de alta importância no Android
  /// 
  /// CRÍTICO: O channelId DEVE corresponder ao usado nas Cloud Functions
  /// Cloud Function usa: channelId: 'high_importance_channel'
  Future<void> _createNotificationChannel() async {
    if (!Platform.isAndroid) {
      debugPrint('📢 PushNotificationService: iOS detected, skipping Android channel creation');
      return;
    }

    debugPrint('📢 PushNotificationService: Creating Android notification channel...');

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _highImportanceChannelId, // ID do canal
      _highImportanceChannelName, // Nome visível nas configurações
      description: _highImportanceChannelDesc,
      importance: Importance.max, // ALTERADO: max em vez de high para garantir popup
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true, // Habilitar LED
      ledColor: Color(0xFFE47911), // Cor do LED = cor accent
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) {
      debugPrint('❌ PushNotificationService: AndroidFlutterLocalNotificationsPlugin is null!');
      return;
    }

    // Criar canal
    await androidPlugin.createNotificationChannel(channel);
    debugPrint('📢 PushNotificationService: Channel "$_highImportanceChannelId" created');

    // Inicializar flutter_local_notifications para Android
    // CRÍTICO: Usar o ícone correto que existe no projeto
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    final initialized = await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('👆 Local notification tapped: ${response.payload}');
        // Payload pode conter dados para navegação
      },
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    debugPrint('📢 PushNotificationService: flutter_local_notifications initialized: $initialized');
    debugPrint('   Channel ID: $_highImportanceChannelId');
    debugPrint('   Channel Importance: max');
  }

  /// Handler para notificação clicada em background (Android)
  @pragma('vm:entry-point')
  static void _notificationTapBackground(NotificationResponse response) {
    debugPrint('👆 [Background] Notification tapped: ${response.payload}');
  }

  /// Mostra notificação local quando app está em foreground
  /// 
  /// Necessário porque FCM não mostra popup quando app está aberto
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Criar detalhes da notificação Android
    const androidDetails = AndroidNotificationDetails(
      _highImportanceChannelId,
      _highImportanceChannelName,
      channelDescription: _highImportanceChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFE47911), // Cor accent do app
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    // Gerar ID único para a notificação
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _localNotifications.show(
      notificationId,
      notification.title,
      notification.body,
      notificationDetails,
      payload: message.data.toString(),
    );

    debugPrint('📱 PushNotificationService: Local notification shown');
  }

  /// Configura handlers de mensagens (foreground, background, terminated)
  void _setupMessageHandlers() {
    debugPrint('🔔 _setupMessageHandlers: Registrando listeners FCM...');
    
    // Foreground: app aberto
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 PushNotificationService: Message received (foreground)');
      debugPrint('   Title: ${message.notification?.title}');
      debugPrint('   Body: ${message.notification?.body}');
      debugPrint('   Data: ${message.data}');

      // Mostrar notificação local quando app está em foreground
      _showLocalNotification(message);

      // Callback customizado
      onForegroundMessage?.call(message);
    });
    
    debugPrint('🔔 _setupMessageHandlers: FirebaseMessaging.onMessage listener registrado');

    // Background/Terminated: app minimizado ou fechado
    // Quando usuário clica na notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 PushNotificationService: Notification tapped (background)');
      debugPrint('   Type: ${message.data['type']}');
      
      // Callback para navegação
      onNotificationTapped?.call(message);
    });
    
    debugPrint('🔔 _setupMessageHandlers: FirebaseMessaging.onMessageOpenedApp listener registrado');

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

  /// Força a regeneração do token FCM
  /// 
  /// IMPORTANTE: Use após atualizar SHA-1 no Firebase Console ou
  /// quando suspeitar que o token antigo é inválido.
  /// O token antigo é deletado do servidor FCM e um novo é gerado.
  Future<String?> forceTokenRefresh() async {
    debugPrint('🔄 PushNotificationService: Forcing token refresh...');
    try {
      // Deletar o token antigo
      await _messaging.deleteToken();
      debugPrint('🗑️ PushNotificationService: Old token deleted');
      
      // Limpar cache
      _currentToken = null;
      
      // Aguardar um pouco para o servidor processar
      await Future<void>.delayed(const Duration(milliseconds: 500));
      
      // Obter novo token
      final newToken = await _messaging.getToken();
      _currentToken = newToken;
      
      if (newToken != null) {
        debugPrint('✅ PushNotificationService: New token generated');
        debugPrint('   Token: ${newToken.substring(0, min(20, newToken.length))}...');
        debugPrint('   Full Token: $newToken');
        debugPrint('   Length: ${newToken.length} chars');
      } else {
        debugPrint('⚠️ PushNotificationService: Failed to generate new token');
      }
      
      return newToken;
    } catch (e, stack) {
      debugPrint('❌ PushNotificationService: Token refresh error: $e');
      debugPrint('   Stack: $stack');
      return null;
    }
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
        // Usa min() para evitar RangeError quando token < 20 caracteres
        final tokenPreview = _currentToken!.substring(0, min(20, _currentToken!.length));
        debugPrint('   Token: $tokenPreview...');
        debugPrint('   Full Token: $_currentToken'); // Adicionado para debug
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
      // NOTA: Campo 'updatedAt' é usado pela Cloud Function para validar idade do token
      await _firestore
          .collection('profiles')
          .doc(profileId)
          .collection('fcmTokens')
          .doc(token)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.name.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(), // Cloud Function valida tokens > 60 dias
      }, SetOptions(merge: true));

      debugPrint('💾 PushNotificationService: Token saved for profile: '
          '$profileId');
    } catch (e) {
      debugPrint('❌ PushNotificationService: Save token error: $e');
    }
  }

  /// Salva token FCM para MÚLTIPLOS perfis do usuário
  ///
  /// Usado no login para garantir que push notifications cheguem
  /// para QUALQUER perfil do usuário, não apenas o ativo.
  /// 
  /// Estrutura: profiles/{profileId}/fcmTokens/{token}
  /// ```dart
  /// await service.saveTokenForProfiles(['profile1', 'profile2', 'profile3']);
  /// ```
  Future<void> saveTokenForProfiles(List<String> profileIds) async {
    try {
      final token = await getToken();
      if (token == null) {
        debugPrint('⚠️ PushNotificationService: Cannot save null token');
        return;
      }

      if (profileIds.isEmpty) {
        debugPrint('⚠️ PushNotificationService: No profiles to save token');
        return;
      }

      // Usar batch write para salvar em todos os perfis de uma vez
      final batch = _firestore.batch();
      
      for (final profileId in profileIds) {
        final tokenRef = _firestore
            .collection('profiles')
            .doc(profileId)
            .collection('fcmTokens')
            .doc(token);
            
        batch.set(tokenRef, {
          'token': token,
          'platform': defaultTargetPlatform.name.toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      
      // Manter referência do primeiro perfil (ou ativo)
      _currentProfileId = profileIds.first;

      debugPrint('💾 PushNotificationService: Token saved for ${profileIds.length} profiles');
    } catch (e) {
      debugPrint('❌ PushNotificationService: Save tokens error: $e');
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

  /// Diagnóstico completo do estado do FCM
  /// 
  /// Use para debugar problemas de push notification
  Future<Map<String, dynamic>> runDiagnostics() async {
    final diagnostics = <String, dynamic>{};
    
    debugPrint('🔍 === FCM DIAGNOSTICS START ===');
    
    // 1. Token
    try {
      final token = await _messaging.getToken();
      diagnostics['token'] = token != null;
      diagnostics['tokenLength'] = token?.length ?? 0;
      debugPrint('✅ Token: ${token != null ? "OK (${token.length} chars)" : "MISSING"}');
      if (token != null) {
        debugPrint('   Token: $token');
      }
    } catch (e) {
      diagnostics['token'] = false;
      diagnostics['tokenError'] = e.toString();
      debugPrint('❌ Token error: $e');
    }
    
    // 2. Permission
    try {
      final settings = await _messaging.getNotificationSettings();
      diagnostics['authorizationStatus'] = settings.authorizationStatus.name;
      debugPrint('📱 Authorization: ${settings.authorizationStatus.name}');
    } catch (e) {
      diagnostics['permissionError'] = e.toString();
      debugPrint('❌ Permission error: $e');
    }
    
    // 3. APNS Token (iOS only)
    try {
      final apnsToken = await _messaging.getAPNSToken();
      diagnostics['apnsToken'] = apnsToken != null;
      debugPrint('🍎 APNS Token: ${apnsToken != null ? "OK" : "N/A (Android)"}');
    } catch (e) {
      diagnostics['apnsError'] = e.toString();
    }
    
    // 4. Auto-init enabled
    try {
      final autoInitEnabled = _messaging.isAutoInitEnabled;
      diagnostics['autoInitEnabled'] = autoInitEnabled;
      debugPrint('🔄 Auto-init: ${autoInitEnabled ? "Enabled" : "Disabled"}');
    } catch (e) {
      diagnostics['autoInitError'] = e.toString();
    }
    
    // 5. Current state
    diagnostics['currentToken'] = _currentToken != null;
    diagnostics['currentProfileId'] = _currentProfileId;
    debugPrint('💾 Current token cached: ${_currentToken != null}');
    debugPrint('👤 Current profile ID: $_currentProfileId');
    
    debugPrint('🔍 === FCM DIAGNOSTICS END ===');
    
    return diagnostics;
  }
}
