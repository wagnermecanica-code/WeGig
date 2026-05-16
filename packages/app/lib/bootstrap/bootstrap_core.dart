import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:core_ui/services/env_service.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wegig_app/core/firebase/firebase_cache_config.dart';
import 'package:wegig_app/core/firebase/firestore_cache_manager.dart';
import 'package:wegig_app/features/notifications_new/data/services/push_notification_service.dart';
import 'package:wegig_app/utils/firebase_context_logger.dart';

typedef BackgroundMessageHandler = Future<void> Function(RemoteMessage message);

Future<void> bootstrapCoreServices({
  required FirebaseOptions firebaseOptions,
  required String flavorLabel,
  required BackgroundMessageHandler backgroundHandler,
  String? expectedProjectId,
  bool enableCrashlytics = false,
  bool enablePushNotifications = true,
  bool printEnvOnDebug = true,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Bootstrapping services for $flavorLabel');

  // ✅ iOS 17+/26 é agressivo com jetsam — reduzir tamanho máximo do
  // imageCache global do Flutter para diminuir footprint em background.
  // Default é 1000 imagens / 100 MB, muito generoso. 40 MB cobre uma feed
  // média sem impactar scroll.
  PaintingBinding.instance.imageCache
    ..maximumSize = 200
    ..maximumSizeBytes = 40 * 1024 * 1024;

  await _initHive();

  await _initEnv(printEnvOnDebug);

  await _initializeFirebase(firebaseOptions);
  await _initializeAppCheck();

  logFirebaseOptions(
    flavor: flavorLabel,
    options: firebaseOptions,
    expectedProjectId: expectedProjectId,
  );

  // ✅ VALIDAÇÃO CRÍTICA: Garantir que o projeto correto foi carregado
  // Se o projeto estiver errado, dados irão para o ambiente errado!
  if (expectedProjectId != null) {
    FirebaseCacheConfig.validateEnvironment(
      flavorLabel.toLowerCase(),
      firebaseOptions.projectId,
    );
  }

  // ✅ Configurar cache Firestore DEPOIS de inicializar Firebase
  // FirebaseFirestore.instance requer Firebase já inicializado
  await FirebaseCacheConfig.configure(flavorLabel.toLowerCase());

  // ✅ Inicializar FirestoreCacheManager para limpar posts expirados
  // Agenda limpeza automática 1x por dia
  await FirestoreCacheManager.initialize();

  FirebaseMessaging.onBackgroundMessage(backgroundHandler);

  debugPrint(
      '🔔 Bootstrap: enablePushNotifications = $enablePushNotifications');
  if (enablePushNotifications) {
    await _initializePushNotifications(flavorLabel);
  } else {
    debugPrint('⚠️ Bootstrap: Push notifications DESABILITADAS');
  }

  _configureErrorHandling(
    enableCrashlytics: enableCrashlytics,
    flavorLabel: flavorLabel,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  debugPrint('🎯 Orientation locked to portrait');

  // ✅ Inicializar Facebook App Events + ATT (iOS)
  await _initializeFacebookSdk();

  // ✅ Inicializar TikTok Business SDK (track launch)
  await _initializeTikTokSdk();

  debugPrint('✅ Bootstrapping completed for $flavorLabel');
}

Future<void> _initHive() async {
  try {
    await Hive.initFlutter();
    debugPrint('✅ Hive initialized successfully');
  } catch (error, stackTrace) {
    debugPrint('⚠️ Hive init failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initEnv(bool printEnvOnDebug) async {
  try {
    await EnvService.init();
    if (printEnvOnDebug && EnvService.isDevelopment) {
      EnvService.printAll();
    }
    debugPrint('✅ EnvService loaded');
  } catch (error, stackTrace) {
    debugPrint('⚠️ EnvService init failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initializeFirebase(FirebaseOptions options) async {
  if (Firebase.apps.isNotEmpty) {
    final existingApp = Firebase.app();
    debugPrint('ℹ️ Firebase already initialized (${existingApp.name})');
    return;
  }

  try {
    await Firebase.initializeApp(options: options);
    debugPrint('✅ Firebase initialized successfully');

    // ✅ Validar que o projeto correto foi carregado
    final actualProjectId = options.projectId;
    debugPrint('   Project ID: $actualProjectId');
  } on FirebaseException catch (error, stackTrace) {
    if (error.code == 'duplicate-app') {
      debugPrint('ℹ️ Firebase already initialized (${error.message})');
      return;
    }

    debugPrint('❌ Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  } catch (error, stackTrace) {
    debugPrint('❌ Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }
}

Future<void> _initializePushNotifications(String flavorLabel) async {
  debugPrint('🔔 _initializePushNotifications: INICIANDO para $flavorLabel');
  try {
    debugPrint(
        '🔔 _initializePushNotifications: Chamando PushNotificationService().initialize()...');
    await PushNotificationService().initialize();
    debugPrint('✅ PushNotificationService initialized for $flavorLabel');
  } catch (error, stackTrace) {
    debugPrint('⚠️ PushNotificationService init failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initializeAppCheck() async {
  try {
    final androidProvider =
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity;
    final appleProvider =
        kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck;
    await FirebaseAppCheck.instance.activate(
      androidProvider: androidProvider,
      appleProvider: appleProvider,
    );
    debugPrint(
      '🛡️ Firebase App Check initialized '
      '(android=${androidProvider.name}, apple=${appleProvider.name})',
    );
  } catch (error, stackTrace) {
    debugPrint('⚠️ Firebase App Check init failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initializeFacebookSdk() async {
  try {
    final facebookAppEvents = FacebookAppEvents();
    TrackingStatus? trackingStatus;
    var advertiserTrackingEnabled = false;

    // iOS: solicitar ATT e configurar advertiser tracking
    if (Platform.isIOS) {
      trackingStatus =
          await AppTrackingTransparency.requestTrackingAuthorization();
      advertiserTrackingEnabled = trackingStatus == TrackingStatus.authorized;
      await facebookAppEvents.setAdvertiserTracking(
        enabled: advertiserTrackingEnabled,
      );
      debugPrint(
        '📊 ATT status: $trackingStatus, AdvertiserTracking: $advertiserTrackingEnabled',
      );
    }

    // Ativar coleta de eventos automaticamente (iOS + Android)
    await facebookAppEvents.setAutoLogAppEventsEnabled(true);

    final appId = await facebookAppEvents.getApplicationId();
    debugPrint(
      '📘 Facebook SDK diagnostics: appId=${appId ?? "NULL"}, autoLogRequested=true, platform=${Platform.operatingSystem}',
    );

    if (!kReleaseMode) {
      await facebookAppEvents.logEvent(
        name: 'fb_sdk_diagnostic_boot',
        parameters: <String, dynamic>{
          'platform': Platform.operatingSystem,
          'att_status': trackingStatus?.name ?? 'not_applicable',
          'advertiser_tracking_enabled': advertiserTrackingEnabled,
          'auto_log_requested': true,
        },
      );
      debugPrint(
        '📘 Facebook SDK diagnostics: fb_sdk_diagnostic_boot sent successfully',
      );
    }

    debugPrint('✅ Facebook App Events SDK initialized');
  } catch (error, stackTrace) {
    debugPrint('⚠️ Facebook SDK init failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initializeTikTokSdk() async {
  debugPrint('⚠️ TikTok Business SDK disabled by configuration');
}

void _configureErrorHandling({
  required bool enableCrashlytics,
  required String flavorLabel,
}) {
  if (enableCrashlytics) {
    FlutterError.onError = (details) {
      if (_isNonFatalImageFailure(details.exception, details.stack)) {
        FirebaseCrashlytics.instance.recordFlutterError(details);
        FlutterError.presentError(details);
        return;
      }

      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: !_isNonFatalImageFailure(error, stack),
      );
      return true;
    };
    return;
  }

  FlutterError.onError = (details) {
    debugPrint('[$flavorLabel] Flutter Error: ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[$flavorLabel] Async Error: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };
}

bool _isNonFatalImageFailure(Object error, StackTrace? stack) {
  final message = error.toString();
  final stackText = stack?.toString() ?? '';
  final isImageStack = stackText.contains('image_stream.dart') ||
      stackText.contains('multi_image_stream_completer.dart') ||
      stackText.contains('cached_network_image') ||
      stackText.contains('flutter_cache_manager') ||
      stackText.contains('web_helper.dart') ||
      stackText.contains('file_service.dart') ||
      stackText.contains('image_provider.dart');

  if (!isImageStack) return false;

  return message.contains('HandshakeException') ||
      message.contains('PathNotFoundException') ||
      message.contains('No host specified in URI');
}
