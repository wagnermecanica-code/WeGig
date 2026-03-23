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

import 'dart:async' show Completer;
import 'dart:io' show Platform;
import 'dart:math' show min;
import 'dart:ui' show Color;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

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
  static final PushNotificationService _instance = PushNotificationService._();
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

  // Evita concorrência: o plugin do Firebase Messaging só permite 1 requestPermission
  // por vez. Se múltiplos fluxos chamarem em paralelo (bootstrap + salvar token +
  // troca de perfil), as chamadas extras aguardam a mesma Future.
  static Completer<NotificationSettings>? _permissionRequestInFlight;

  String? _currentToken;
  String? _currentProfileId;

  /// Callback quando notificação é clicada (app terminated/background)
  void Function(RemoteMessage)? onNotificationTapped;

  /// Callback quando notificação é recebida (foreground)
  void Function(RemoteMessage)? onForegroundMessage;

  // Tap recebido antes do app conseguir registrar o handler de navegação.
  RemoteMessage? _pendingNotificationTap;

  /// Registra o handler de tap e processa tap pendente (se houver).
  ///
  /// Importante para o caso de app abrir via push (terminated), onde o
  /// `getInitialMessage()` pode ocorrer antes de termos `GoRouter` disponível.
  void attachOnNotificationTapped(void Function(RemoteMessage) handler) {
    onNotificationTapped = handler;
    final pending = _pendingNotificationTap;
    _pendingNotificationTap = null;
    if (pending != null) {
      debugPrint(
        '🔔 PushNotificationService: Flushing pending tap: ${pending.data}',
      );
      handler(pending);
    }
  }

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
        debugPrint(
            '🔔 PushNotificationService: [Android] Criando canal de notificação PRIMEIRO...');
        await _createNotificationChannel();
        debugPrint(
            '✅ PushNotificationService: [Android] Canal criado com sucesso');
      }
      // 🍎 iOS: NÃO inicializar flutter_local_notifications.
      // No iOS, o firebase_messaging já gerencia o UNUserNotificationCenterDelegate.
      // Se inicializarmos flutter_local_notifications, ele toma o delegate e
      // onMessageOpenedApp para de funcionar (taps em notificações de background
      // são interceptados pelo flutter_local_notifications em vez do FCM).
      // O display em foreground é feito via setForegroundNotificationPresentationOptions.

      // CRÍTICO: Configurar como as notificações devem ser apresentadas quando app está em foreground
      // Isso garante que o FCM entregue as mensagens corretamente
      debugPrint(
          '🔔 PushNotificationService: Configurando foreground presentation options...');
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true, // Mostrar alerta
        badge: true, // Mostrar badge
        sound: true, // Tocar som
      );
      debugPrint('✅ PushNotificationService: Foreground options configuradas');

      // Configurar handlers
      debugPrint(
          '🔔 PushNotificationService: Configurando message handlers...');
      _setupMessageHandlers();

      // Escutar mudanças de token (refresh automático FCM)
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint(
            '🔄 PushNotificationService: Token refreshed: ${newToken.substring(0, min(20, newToken.length))}...');
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
      debugPrint(
          '📢 PushNotificationService: iOS detected, skipping Android channel creation');
      return;
    }

    debugPrint(
        '📢 PushNotificationService: Creating Android notification channel...');

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _highImportanceChannelId, // ID do canal
      _highImportanceChannelName, // Nome visível nas configurações
      description: _highImportanceChannelDesc,
      importance:
          Importance.max, // ALTERADO: max em vez de high para garantir popup
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true, // Habilitar LED
      ledColor: Color(0xFFE47911), // Cor do LED = cor accent
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      debugPrint(
          '❌ PushNotificationService: AndroidFlutterLocalNotificationsPlugin is null!');
      return;
    }

    // Criar canal
    await androidPlugin.createNotificationChannel(channel);
    debugPrint(
        '📢 PushNotificationService: Channel "$_highImportanceChannelId" created');

    // Inicializar flutter_local_notifications para Android
    // CRÍTICO: Usar o ícone correto que existe no projeto
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    final initialized = await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('👆 Local notification tapped: ${response.payload}');
        // Payload pode conter dados para navegação
      },
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    debugPrint(
        '📢 PushNotificationService: flutter_local_notifications initialized: $initialized');
    debugPrint('   Channel ID: $_highImportanceChannelId');
    debugPrint('   Channel Importance: max');
  }

  /// Handler para notificação clicada em background (Android)
  @pragma('vm:entry-point')
  static void _notificationTapBackground(NotificationResponse response) {
    debugPrint('👆 [Background] Notification tapped: ${response.payload}');
  }

  // 🍎 NOTA: flutter_local_notifications NÃO é inicializado no iOS.
  // Motivo: ao chamar _localNotifications.initialize() no iOS, o plugin
  // registra-se como UNUserNotificationCenterDelegate, interceptando os taps
  // em notificações. Isso impede que firebase_messaging receba o callback
  // onMessageOpenedApp, quebrando a navegação ao tocar em notificações
  // quando o app está em background.
  //
  // No iOS, o display de notificações é gerenciado por:
  // - Foreground: setForegroundNotificationPresentationOptions(alert: true)
  // - Background/terminated: APNS nativo
  // Taps em ambos os casos são capturados por firebase_messaging via
  // onMessageOpenedApp e getInitialMessage, respectivamente.

  /// Mostra notificação local quando app está em foreground (Android only)
  ///
  /// No Android, FCM não mostra popup quando app está aberto, então usamos
  /// flutter_local_notifications para exibir uma notificação local.
  ///
  /// No iOS, `setForegroundNotificationPresentationOptions(alert: true)` já
  /// faz o sistema exibir a notificação. Ao tocar, `onMessageOpenedApp` é
  /// disparado pelo firebase_messaging — sem necessidade de notificação local.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    // 🍎 iOS: pular — o sistema já exibe a notificação via APNS/FCM
    if (Platform.isIOS) return;

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

    debugPrint(
        '🔔 _setupMessageHandlers: FirebaseMessaging.onMessage listener registrado');

    // Background/Terminated: app minimizado ou fechado
    // Quando usuário clica na notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
          '👆 PushNotificationService: Notification tapped (background)');
      debugPrint('   Type: ${message.data['type']}');

      // Callback para navegação (ou fila se ainda não registrado)
      final handler = onNotificationTapped;
      if (handler != null) {
        handler(message);
      } else {
        _pendingNotificationTap = message;
      }
    });

    debugPrint(
        '🔔 _setupMessageHandlers: FirebaseMessaging.onMessageOpenedApp listener registrado');

    // Terminated: app estava fechado e foi aberto pela notificação
    // 🍎 iOS: getInitialMessage() pode retornar null se chamado muito cedo.
    // Adicionamos retry com delay para dar tempo ao plugin nativo de processar
    // a notificação de lançamento.
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
            '👆 PushNotificationService: Notification tapped (terminated)');
        debugPrint('   Type: ${message.data['type']}');

        final handler = onNotificationTapped;
        if (handler != null) {
          handler(message);
        } else {
          _pendingNotificationTap = message;
        }
      } else if (Platform.isIOS) {
        // 🍎 iOS retry: o plugin nativo pode não ter processado a notificação
        // de lançamento a tempo. Tentar novamente após um breve delay.
        Future.delayed(const Duration(milliseconds: 1500), () {
          _messaging.getInitialMessage().then((RemoteMessage? retryMessage) {
            if (retryMessage != null) {
              debugPrint(
                  '👆 PushNotificationService: Notification tapped (terminated - iOS retry)');
              debugPrint('   Type: ${retryMessage.data['type']}');

              final handler = onNotificationTapped;
              if (handler != null) {
                handler(retryMessage);
              } else {
                _pendingNotificationTap = retryMessage;
              }
            }
          });
        });
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
    final inFlight = _permissionRequestInFlight;
    if (inFlight != null) {
      debugPrint(
        '⏳ PushNotificationService: Permission request already in progress, awaiting...',
      );
      return inFlight.future;
    }

    // Android 13+: a permissão POST_NOTIFICATIONS precisa ser solicitada
    // explicitamente via permission_handler. FirebaseMessaging.requestPermission
    // nem sempre dispara o prompt no Android.
    if (Platform.isAndroid) {
      final completer = Completer<NotificationSettings>();
      _permissionRequestInFlight = completer;

      try {
        final status = await Permission.notification.request();
        debugPrint(
          '📱 PushNotificationService: Android notification permission: $status',
        );

        final settings = await _messaging.getNotificationSettings();
        completer.complete(settings);
        return settings;
      } catch (e, st) {
        debugPrint('❌ PushNotificationService: Android permission error: $e');
        completer.completeError(e, st);
        rethrow;
      } finally {
        _permissionRequestInFlight = null;
      }
    }

    // Se já temos um estado decidido, evita chamar requestPermission de novo.
    final current = await _messaging.getNotificationSettings();
    if (current.authorizationStatus != AuthorizationStatus.notDetermined) {
      debugPrint(
        '📱 PushNotificationService: Permission already decided: ${current.authorizationStatus}',
      );
      return current;
    }

    final completer = Completer<NotificationSettings>();
    _permissionRequestInFlight = completer;

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

      debugPrint(
        '📱 PushNotificationService: Permission status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ PushNotificationService: Permission granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ PushNotificationService: Provisional permission');
      } else {
        debugPrint('❌ PushNotificationService: Permission denied');
      }

      completer.complete(settings);
      return settings;
    } catch (e, st) {
      debugPrint('❌ PushNotificationService: Permission error: $e');
      completer.completeError(e, st);
      rethrow;
    } finally {
      // Libera para próximas tentativas (ex: usuário muda setting e app tenta de novo)
      _permissionRequestInFlight = null;
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
        debugPrint(
            '   Token: ${newToken.substring(0, min(20, newToken.length))}...');
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
        final tokenPreview =
            _currentToken!.substring(0, min(20, _currentToken!.length));
        debugPrint('   Token: $tokenPreview...');
        if (kDebugMode) {
          debugPrint('   Full Token: $_currentToken');
        }
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
      // NOTA: Campo 'updatedAt' é usado pela Cloud Function para ordenar tokens (mais recentes primeiro)
      // e auxiliar limpeza baseada em falhas de envio (FCM responses).
      await _firestore
          .collection('profiles')
          .doc(profileId)
          .collection('fcmTokens')
          .doc(token)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.name.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('💾 PushNotificationService: Token saved for profile: '
          '$profileId');
    } catch (e, st) {
      if (e is FirebaseException) {
        debugPrint(
          '❌ PushNotificationService: Save token error for profile=$profileId '
          '(code=${e.code}, message=${e.message})',
        );
      } else {
        debugPrint(
            '❌ PushNotificationService: Save token error for profile=$profileId: $e');
      }
      debugPrint('   Stack: $st');
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

      // Não usamos batch aqui: se 1 perfil falhar por permissão,
      // um batch inteiro falharia e nenhum token seria salvo.
      var successCount = 0;

      for (final profileId in profileIds) {
        try {
          final tokenRef = _firestore
              .collection('profiles')
              .doc(profileId)
              .collection('fcmTokens')
              .doc(token);

          await tokenRef.set({
            'token': token,
            'platform': defaultTargetPlatform.name.toLowerCase(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          successCount++;
        } catch (e, st) {
          if (e is FirebaseException) {
            debugPrint(
              '❌ PushNotificationService: Failed to save token for profile=$profileId '
              '(code=${e.code}, message=${e.message})',
            );
          } else {
            debugPrint(
                '❌ PushNotificationService: Failed to save token for profile=$profileId: $e');
          }
          debugPrint('   Stack: $st');
        }
      }

      // Manter referência do primeiro perfil (ou ativo)
      _currentProfileId = profileIds.first;

      debugPrint(
        '💾 PushNotificationService: Token saved for $successCount/${profileIds.length} profiles',
      );
    } catch (e, st) {
      if (e is FirebaseException) {
        debugPrint(
          '❌ PushNotificationService: Save tokens error '
          '(code=${e.code}, message=${e.message})',
        );
      } else {
        debugPrint('❌ PushNotificationService: Save tokens error: $e');
      }
      debugPrint('   Stack: $st');
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
    } catch (e, st) {
      if (e is FirebaseException) {
        debugPrint(
          '❌ PushNotificationService: Remove token error for profile=$profileId '
          '(code=${e.code}, message=${e.message})',
        );
      } else {
        debugPrint(
            '❌ PushNotificationService: Remove token error for profile=$profileId: $e');
      }
      debugPrint('   Stack: $st');
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
      debugPrint(
          '✅ Token: ${token != null ? "OK (${token.length} chars)" : "MISSING"}');
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
      debugPrint(
          '🍎 APNS Token: ${apnsToken != null ? "OK" : "N/A (Android)"}');
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

  // ══════════════════════════════════════════════════════════════════════════
  // 📱 APP BADGE MANAGEMENT (iOS/Android icon badge)
  // ══════════════════════════════════════════════════════════════════════════

  /// Atualiza o badge do ícone do app com o número de notificações não lidas
  ///
  /// Deve ser chamado quando:
  /// - App é aberto (para sincronizar com Firestore)
  /// - Notificação é marcada como lida
  /// - Todas notificações são marcadas como lidas
  ///
  /// [profileId] - ID do perfil ativo
  /// [uid] - UID do usuário (para query Firestore)
  Future<void> updateAppBadge(String profileId, String uid) async {
    try {
      // Verificar se o dispositivo suporta badge
      final isSupported = await FlutterAppBadger.isAppBadgeSupported();
      if (!isSupported) {
        debugPrint(
            '📱 PushNotificationService: App badge not supported on this device');
        return;
      }

      final trimmedProfileId = profileId.trim();
      final trimmedUid = uid.trim();
      if (trimmedProfileId.isEmpty || trimmedUid.isEmpty) {
        debugPrint('📱 PushNotificationService: Skip badge sync (missing profileId/uid)');
        return;
      }

      // Contar notificações não lidas do perfil no Firestore.
      //
      // IMPORTANTE:
      // - Evita usar `count()` + múltiplos `where` (especialmente `expiresAt`) pois
      //   isso costuma exigir índices compostos e pode falhar silenciosamente no device,
      //   mantendo o badge antigo (ex.: sempre 1 via APNS).
      // - `expiresAt` pode ser null em alguns docs; então fazemos filtro client-side.
      // - O badge do ícone do app deve incluir `newMessage` (mensagens não lidas).
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        debugPrint('📱 PushNotificationService: Fetching badge count from server for uid=$trimmedUid profile=$trimmedProfileId');
        snapshot = await _firestore
            .collection('notifications')
            .where('recipientUid', isEqualTo: trimmedUid)
            .where('read', isEqualTo: false)
            .get(const GetOptions(source: Source.server));
        debugPrint('📱 PushNotificationService: Server returned ${snapshot.docs.length} docs');
      } catch (e) {
        // Fallback: offline/stale. Preferimos mostrar algo do cache do que manter
        // um badge antigo vindo do APNS.
        debugPrint('📱 PushNotificationService: Badge server fetch failed, using cache: $e');
        try {
          snapshot = await _firestore
              .collection('notifications')
              .where('recipientUid', isEqualTo: trimmedUid)
              .where('read', isEqualTo: false)
              .get(const GetOptions(source: Source.cache));
          debugPrint('📱 PushNotificationService: Cache returned ${snapshot.docs.length} docs');
        } catch (cacheError) {
          // Nem cache funcionou - forçar limpeza do badge para evitar valor "preso"
          debugPrint('📱 PushNotificationService: Cache also failed: $cacheError - clearing badge');
          await FlutterAppBadger.updateBadgeCount(0);
          await FlutterAppBadger.removeBadge();
          return;
        }
      }

      final now = DateTime.now();
      final unreadCount = snapshot.docs.where((doc) {
        final data = doc.data();

        final recipientProfileId = data['recipientProfileId'] as String?;
        if (recipientProfileId != trimmedProfileId) return false;

        final expiresAt = data['expiresAt'] as Timestamp?;
        if (expiresAt != null && expiresAt.toDate().isBefore(now)) return false;

        return true;
      }).length;

      debugPrint(
          '📱 PushNotificationService: Badge sync - found $unreadCount unread for profile $trimmedProfileId (total docs: ${snapshot.docs.length})');

      if (unreadCount > 0) {
        await FlutterAppBadger.updateBadgeCount(unreadCount);
        debugPrint(
            '📱 PushNotificationService: App badge updated to $unreadCount');
      } else {
        // Forçar limpeza dupla para Samsung - às vezes removeBadge sozinho não funciona
        await FlutterAppBadger.updateBadgeCount(0);
        await FlutterAppBadger.removeBadge();
        debugPrint('📱 PushNotificationService: App badge removed (0 unread)');
      }
    } catch (e) {
      debugPrint('❌ PushNotificationService: Error updating app badge: $e');
    }
  }

  /// Remove o badge do ícone do app (zera o contador)
  ///
  /// Chamado quando todas as notificações são lidas
  Future<void> clearAppBadge() async {
    try {
      final isSupported = await FlutterAppBadger.isAppBadgeSupported();
      if (!isSupported) return;

      await FlutterAppBadger.removeBadge();
      debugPrint('📱 PushNotificationService: App badge cleared');
    } catch (e) {
      debugPrint('❌ PushNotificationService: Error clearing app badge: $e');
    }
  }
}
