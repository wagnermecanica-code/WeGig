import 'dart:ui' show PlatformDispatcher;

import 'package:core_ui/services/env_service.dart';
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

  await _initHive();

  await _initEnv(printEnvOnDebug);
  
  await _initializeFirebase(firebaseOptions);

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

  debugPrint('🔔 Bootstrap: enablePushNotifications = $enablePushNotifications');
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
    debugPrint('🔔 _initializePushNotifications: Chamando PushNotificationService().initialize()...');
    await PushNotificationService().initialize();
    debugPrint('✅ PushNotificationService initialized for $flavorLabel');
  } catch (error, stackTrace) {
    debugPrint('⚠️ PushNotificationService init failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

void _configureErrorHandling({
  required bool enableCrashlytics,
  required String flavorLabel,
}) {
  if (enableCrashlytics) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
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
