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

import 'dart:async' show Completer, StreamSubscription;
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' show min;
import 'dart:ui' show Color;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/firebase/blocked_relations.dart';
import '../../../../core/firebase/blocked_profiles.dart';

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
  static const String _myNetworkBadgeSeenAtKeyPrefix =
      'my_network_badge_seen_at_v1';
  static const String _myNetworkBadgeSeenAtField = 'myNetworkBadgeSeenAt';

  // Evita concorrência: o plugin do Firebase Messaging só permite 1 requestPermission
  // por vez. Se múltiplos fluxos chamarem em paralelo (bootstrap + salvar token +
  // troca de perfil), as chamadas extras aguardam a mesma Future.
  static Completer<NotificationSettings>? _permissionRequestInFlight;
  static Completer<String?>? _apnsTokenWaitInFlight;
  static final Map<String, Future<void>> _badgeSyncInFlight = {};

  String? _currentToken;
  String? _currentProfileId;
  bool _isInitialized = false;

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;

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

    if (_isInitialized) {
      debugPrint(
        'ℹ️ PushNotificationService: initialize() já executado, reaproveitando listeners existentes',
      );
      return;
    }

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
      _onTokenRefreshSubscription?.cancel();
      _onTokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
        debugPrint(
            '🔄 PushNotificationService: Token refreshed: ${newToken.substring(0, min(20, newToken.length))}...');
        _currentToken = newToken;

        // Atualizar token no Firestore se perfil ativo existe
        if (_currentProfileId != null) {
          saveTokenForProfile(_currentProfileId!);
        }
      });

      _isInitialized = true;

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
        _handleLocalNotificationTap(response.payload);
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

  void _handleLocalNotificationTap(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('⚠️ PushNotificationService: Invalid local payload shape');
        return;
      }

      final message = RemoteMessage.fromMap(<String, dynamic>{
        'data': decoded,
      });

      final handler = onNotificationTapped;
      if (handler != null) {
        handler(message);
      } else {
        _pendingNotificationTap = message;
      }
    } catch (error) {
      debugPrint(
        '⚠️ PushNotificationService: Failed to decode local notification payload: $error',
      );
    }
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
      payload: jsonEncode(message.data),
    );

    debugPrint('📱 PushNotificationService: Local notification shown');
  }

  /// Configura handlers de mensagens (foreground, background, terminated)
  void _setupMessageHandlers() {
    debugPrint('🔔 _setupMessageHandlers: Registrando listeners FCM...');

    // Foreground: app aberto
    _onMessageSubscription?.cancel();
    _onMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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
    _onMessageOpenedSubscription?.cancel();
    _onMessageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
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

      if (Platform.isIOS &&
          current.authorizationStatus == AuthorizationStatus.authorized) {
        final apnsToken = await _waitForApnsToken();
        debugPrint(
          '🍎 PushNotificationService: APNS after cached permission = ${apnsToken != null ? "OK" : "MISSING"}',
        );
      }

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
        final apnsToken = await _waitForApnsToken();
        debugPrint(
          '🍎 PushNotificationService: APNS after permission = ${apnsToken != null ? "OK" : "MISSING"}',
        );
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
      if (Platform.isIOS) {
        final apnsToken = await _waitForApnsToken();
        if (apnsToken == null) {
          debugPrint(
            '⚠️ PushNotificationService: Skipping FCM token refresh because APNS token is still unavailable',
          );
          return null;
        }
      }

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

      if (Platform.isIOS) {
        final apnsToken = await _waitForApnsToken();
        if (apnsToken == null) {
          debugPrint(
            '⚠️ PushNotificationService: APNS token not available yet, deferring FCM token fetch',
          );
          return null;
        }
      }

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

  Future<String?> _waitForApnsToken() async {
    if (!Platform.isIOS) {
      return null;
    }

    final inFlight = _apnsTokenWaitInFlight;
    if (inFlight != null) {
      return inFlight.future;
    }

    final completer = Completer<String?>();
    _apnsTokenWaitInFlight = completer;

    try {
      for (var attempt = 0; attempt < 10; attempt++) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) {
          completer.complete(apnsToken);
          return apnsToken;
        }

        if (attempt == 0) {
          debugPrint(
            '🍎 PushNotificationService: Waiting for APNS token before FCM operations...',
          );
        }

        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      completer.complete(null);
      return null;
    } catch (e, st) {
      debugPrint('❌ PushNotificationService: APNS token wait error: $e');
      completer.completeError(e, st);
      rethrow;
    } finally {
      _apnsTokenWaitInFlight = null;
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

  /// Troca de perfil: garante token no novo perfil sem remover dos demais
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

  /// Atualiza o badge do ícone do app com a contagem canônica da Minha Rede.
  ///
  /// Deve ser chamado quando:
  /// - App é aberto ou retorna do background
  /// - Ações que alteram a contagem da Minha Rede acontecem em foreground
  /// - O perfil ativo muda
  ///
  /// [profileId] - ID do perfil ativo
  /// [uid] - UID do usuário (para query Firestore)
  Future<void> updateAppBadge(String profileId, String uid) async {
    final trimmedProfileId = profileId.trim();
    final trimmedUid = uid.trim();
    final syncKey = '$trimmedProfileId|$trimmedUid';

    final inFlight = _badgeSyncInFlight[syncKey];
    if (inFlight != null) {
      debugPrint(
        '⏳ PushNotificationService: Reusing in-flight badge sync for $trimmedProfileId',
      );
      await inFlight;
      return;
    }

    final syncFuture = _updateAppBadgeInternal(
      profileId: trimmedProfileId,
      uid: trimmedUid,
    );
    _badgeSyncInFlight[syncKey] = syncFuture;

    try {
      await syncFuture;
    } finally {
      if (identical(_badgeSyncInFlight[syncKey], syncFuture)) {
        _badgeSyncInFlight.remove(syncKey);
      }
    }
  }

  Future<void> _updateAppBadgeInternal({
    required String profileId,
    required String uid,
  }) async {
    try {
      // Verificar se o dispositivo suporta badge
      final isSupported = await FlutterAppBadger.isAppBadgeSupported();
      if (!isSupported) {
        debugPrint(
            '📱 PushNotificationService: App badge not supported on this device');
        return;
      }

      if (profileId.isEmpty || uid.isEmpty) {
        debugPrint(
            '📱 PushNotificationService: Skip badge sync (missing profileId/uid)');
        return;
      }

      final badgeCounts = await _loadAppBadgeCounts(
        profileId: profileId,
        uid: uid,
      );
      final badgeCount = badgeCounts.total;

      debugPrint(
          '📱 PushNotificationService: Badge sync for $profileId => notifications=${badgeCounts.notifications}, messages=${badgeCounts.messages}, myNetwork=${badgeCounts.myNetwork}, total=$badgeCount');

      if (badgeCount > 0) {
        await FlutterAppBadger.updateBadgeCount(badgeCount);
        debugPrint(
            '📱 PushNotificationService: App badge updated to $badgeCount');
      } else {
        // Forçar limpeza dupla para Samsung - às vezes removeBadge sozinho não funciona
        await FlutterAppBadger.updateBadgeCount(0);
        await FlutterAppBadger.removeBadge();
        // Android: quando não há nada pendente, limpar a bandeja também —
        // do contrário launchers que derivam o badge de NotificationCompat
        // .setNumber mantêm pushes antigos mostrando números obsoletos.
        if (Platform.isAndroid) {
          try {
            await _localNotifications.cancelAll();
          } catch (e) {
            debugPrint(
                '⚠️ PushNotificationService: Failed to clear Android tray: $e');
          }
        }
        debugPrint('📱 PushNotificationService: App badge removed (0 count)');
      }
    } catch (e) {
      debugPrint('❌ PushNotificationService: Error updating app badge: $e');
    }
  }

  Future<_AppBadgeCounts> _loadAppBadgeCounts({
    required String profileId,
    required String uid,
  }) async {
    final blockedProfileIds = await BlockedProfiles.get(
      firestore: _firestore,
      profileId: profileId,
    );
    final excludedProfileIds = await BlockedRelations.getExcludedProfileIds(
      firestore: _firestore,
      profileId: profileId,
      uid: uid,
    );

    final results = await Future.wait<int>([
      _loadUnreadNotificationCount(
        profileId: profileId,
        uid: uid,
        blockedProfileIds: blockedProfileIds,
      ),
      _loadUnreadMessagesCount(
        profileId: profileId,
        uid: uid,
        excludedProfileIds: excludedProfileIds,
      ),
      _loadMyNetworkBadgeCount(
        profileId: profileId,
        uid: uid,
        excludedProfileIds: excludedProfileIds,
      ),
    ]);

    return _AppBadgeCounts(
      notifications: results[0],
      messages: results[1],
      myNetwork: results[2],
    );
  }

  Future<int> _loadUnreadNotificationCount({
    required String profileId,
    required String uid,
    required List<String> blockedProfileIds,
  }) async {
    final snapshot = await _loadQueryWithCacheFallback(
      _firestore
          .collection('notifications')
          .where('recipientProfileId', isEqualTo: profileId)
          .where('recipientUid', isEqualTo: uid)
          .where('read', isEqualTo: false),
      debugLabel: 'unread notifications for badge sync',
    );

    final now = DateTime.now();
    return snapshot.docs.where((doc) {
      final data = doc.data();
      if (_isNotificationTypeExcludedFromBadge(data)) {
        return false;
      }
      if (_isConnectionActivityNotificationData(data)) {
        return false;
      }
      if (_isNotificationExpired(data, now)) {
        return false;
      }
      if (_notificationMatchesBlockedProfile(data, blockedProfileIds)) {
        return false;
      }
      return true;
    }).length;
  }

  bool _isNotificationTypeExcludedFromBadge(
    Map<String, dynamic> notificationData,
  ) {
    final type = (notificationData['type'] as String? ?? '').trim();
    return type == 'newMessage';
  }

  bool _isConnectionActivityNotificationData(
    Map<String, dynamic> notificationData,
  ) {
    final actionData = _coerceMap(notificationData['actionData']);
    final data = _coerceMap(notificationData['data']);
    final eventType =
        ((actionData['eventType'] ?? data['eventType']) as String?)?.trim();
    return eventType?.startsWith('connection') ?? false;
  }

  bool _isNotificationExpired(
    Map<String, dynamic> notificationData,
    DateTime now,
  ) {
    final expiresAt = _parseTimestamp(notificationData['expiresAt']);
    return expiresAt != null && expiresAt.isBefore(now);
  }

  bool _notificationMatchesBlockedProfile(
    Map<String, dynamic> notificationData,
    List<String> blockedProfileIds,
  ) {
    if (blockedProfileIds.isEmpty) {
      return false;
    }

    final blockedSet = blockedProfileIds.toSet();
    final actionData = _coerceMap(notificationData['actionData']);
    final data = _coerceMap(notificationData['data']);
    final candidateProfileIds = <String>{};

    void addCandidate(dynamic value) {
      if (value is! String) {
        return;
      }
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        candidateProfileIds.add(normalized);
      }
    }

    addCandidate(notificationData['senderProfileId']);
    addCandidate(actionData['authorProfileId']);
    addCandidate(actionData['interestedProfileId']);
    addCandidate(actionData['senderProfileId']);
    addCandidate(actionData['commenterProfileId']);
    addCandidate(data['actionProfileId']);
    addCandidate(data['authorProfileId']);
    addCandidate(data['interestedProfileId']);
    addCandidate(data['senderProfileId']);

    return candidateProfileIds.any(blockedSet.contains);
  }

  Map<String, dynamic> _coerceMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  Future<int> _loadUnreadMessagesCount({
    required String profileId,
    required String uid,
    required List<String> excludedProfileIds,
  }) async {
    final snapshot = await _loadQueryWithCacheFallback(
      _firestore
          .collection('conversations')
          .where('participants', arrayContains: uid),
      debugLabel: 'conversations for unread badge sync',
    );

    var unreadConversations = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();

      final participantProfiles =
          (data['participantProfiles'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>();
      if (!participantProfiles.contains(profileId)) {
        continue;
      }

      final deletedByProfiles =
          (data['deletedByProfiles'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>();
      if (deletedByProfiles.contains(profileId)) {
        continue;
      }

      final archivedByProfiles =
          (data['archivedByProfiles'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>();
      if (archivedByProfiles.contains(profileId)) {
        continue;
      }

      final otherProfileId = participantProfiles.firstWhere(
        (candidate) => candidate != profileId,
        orElse: () => '',
      );
      if (otherProfileId.isNotEmpty &&
          excludedProfileIds.contains(otherProfileId)) {
        continue;
      }

      final unreadCount = Map<String, dynamic>.from(
          data['unreadCount'] as Map<String, dynamic>? ??
              const <String, dynamic>{});
      final countForProfile = (unreadCount[profileId] as num?)?.toInt() ?? 0;
      if (countForProfile > 0) {
        unreadConversations++;
      }
    }

    return unreadConversations;
  }

  Future<int> _loadMyNetworkBadgeCount({
    required String profileId,
    required String uid,
    required List<String> excludedProfileIds,
  }) async {
    final seenAt = await _loadMyNetworkBadgeSeenAt(profileId);

    final pendingRequests = await _loadPendingReceivedRequests(
      profileId: profileId,
      uid: uid,
    );
    final connections = await _loadConnections(
      profileId: profileId,
      uid: uid,
    );

    final pendingReceivedCount = pendingRequests.docs.where((doc) {
      final data = doc.data();
      final requesterProfileId =
          (data['requesterProfileId'] as String? ?? '').trim();
      final requesterUid = (data['requesterUid'] as String? ?? '').trim();
      final requesterName = (data['requesterName'] as String? ?? '').trim();
      final createdAt = _parseTimestamp(data['createdAt']);

      return requesterProfileId.isNotEmpty &&
          requesterUid.isNotEmpty &&
          requesterName.isNotEmpty &&
          (seenAt == null ||
              (createdAt != null && createdAt.isAfter(seenAt))) &&
          !excludedProfileIds.contains(requesterProfileId);
    }).length;

    final newlyAcceptedOutgoingCount = connections.docs.where((doc) {
      final data = doc.data();
      final profileIds =
          (data['profileIds'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>();
      if (!profileIds.contains(profileId)) {
        return false;
      }

      final initiatedByProfileId =
          (data['initiatedByProfileId'] as String? ?? '').trim();
      if (initiatedByProfileId != profileId) {
        return false;
      }

      final createdAt = _parseTimestamp(data['createdAt']);
      if (seenAt != null && (createdAt == null || !createdAt.isAfter(seenAt))) {
        return false;
      }

      final otherProfileId = profileIds
          .firstWhere((candidate) => candidate != profileId, orElse: () => '');
      if (otherProfileId.isEmpty ||
          excludedProfileIds.contains(otherProfileId)) {
        return false;
      }

      final profileUids =
          (data['profileUids'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>();
      final profileNames = Map<String, dynamic>.from(
        data['profileNames'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      );
      final otherIndex = profileIds.indexOf(otherProfileId);
      final otherUid = otherIndex >= 0 && otherIndex < profileUids.length
          ? profileUids[otherIndex].trim()
          : '';
      final otherName = (profileNames[otherProfileId] as String? ?? '').trim();

      return otherUid.isNotEmpty && otherName.isNotEmpty;
    }).length;

    return pendingReceivedCount + newlyAcceptedOutgoingCount;
  }

  Future<DateTime?> _loadMyNetworkBadgeSeenAt(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final localSeenAtMillis = prefs.getInt(_badgeSeenAtKey(profileId));
    final localSeenAt = localSeenAtMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(localSeenAtMillis)
        : null;

    DateTime? remoteSeenAt;
    try {
      final profileSnapshot = await _loadDocumentWithCacheFallback(
        _firestore.collection('profiles').doc(profileId),
        debugLabel: 'profile badge seenAt',
      );
      remoteSeenAt = _parseTimestamp(
        profileSnapshot.data()?[_myNetworkBadgeSeenAtField],
      );
    } catch (error) {
      debugPrint(
        '📱 PushNotificationService: Failed to load remote badge seenAt for $profileId: $error',
      );
    }

    final resolvedSeenAt = _latestDate(localSeenAt, remoteSeenAt);
    if (resolvedSeenAt != null &&
        resolvedSeenAt.millisecondsSinceEpoch != localSeenAtMillis) {
      await prefs.setInt(
        _badgeSeenAtKey(profileId),
        resolvedSeenAt.millisecondsSinceEpoch,
      );
    }

    return resolvedSeenAt;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _loadPendingReceivedRequests({
    required String profileId,
    required String uid,
  }) {
    return _loadQueryWithCacheFallback(
      _firestore
          .collection('connectionRequests')
          .where('recipientProfileId', isEqualTo: profileId)
          .where('recipientUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending'),
      debugLabel: 'pending received requests',
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _loadConnections({
    required String profileId,
    required String uid,
  }) {
    return _loadQueryWithCacheFallback(
      _firestore
          .collection('connections')
          .where('profileUids', arrayContains: uid)
          .orderBy('createdAt', descending: true),
      debugLabel: 'connections for badge sync',
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _loadQueryWithCacheFallback(
    Query<Map<String, dynamic>> query, {
    required String debugLabel,
  }) async {
    try {
      final snapshot = await query.get(const GetOptions(source: Source.server));
      debugPrint(
        '📱 PushNotificationService: Loaded $debugLabel from server (${snapshot.docs.length} docs)',
      );
      return snapshot;
    } catch (error) {
      debugPrint(
        '📱 PushNotificationService: Server fetch failed for $debugLabel, using cache: $error',
      );
      try {
        final snapshot =
            await query.get(const GetOptions(source: Source.cache));
        debugPrint(
          '📱 PushNotificationService: Loaded $debugLabel from cache (${snapshot.docs.length} docs)',
        );
        return snapshot;
      } catch (cacheError) {
        debugPrint(
          '📱 PushNotificationService: Cache fetch failed for $debugLabel: $cacheError',
        );
        rethrow;
      }
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadDocumentWithCacheFallback(
    DocumentReference<Map<String, dynamic>> reference, {
    required String debugLabel,
  }) async {
    try {
      final snapshot =
          await reference.get(const GetOptions(source: Source.server));
      debugPrint(
        '📱 PushNotificationService: Loaded $debugLabel from server (exists=${snapshot.exists})',
      );
      return snapshot;
    } catch (error) {
      debugPrint(
        '📱 PushNotificationService: Server fetch failed for $debugLabel, using cache: $error',
      );
      final snapshot =
          await reference.get(const GetOptions(source: Source.cache));
      debugPrint(
        '📱 PushNotificationService: Loaded $debugLabel from cache (exists=${snapshot.exists})',
      );
      return snapshot;
    }
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  DateTime? _latestDate(DateTime? first, DateTime? second) {
    if (first == null) {
      return second;
    }
    if (second == null) {
      return first;
    }
    return first.isAfter(second) ? first : second;
  }

  String _badgeSeenAtKey(String profileId) {
    return '$_myNetworkBadgeSeenAtKeyPrefix:$profileId';
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

class _AppBadgeCounts {
  const _AppBadgeCounts({
    required this.notifications,
    required this.messages,
    required this.myNetwork,
  });

  final int notifications;
  final int messages;
  final int myNetwork;

  int get total => notifications + messages + myNetwork;
}
