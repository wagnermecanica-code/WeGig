import 'dart:ui' show PlatformDispatcher;

import 'package:core_ui/services/env_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegig_app/firebase_options_dev.dart';
import 'package:wegig_app/main.dart' show WeGigApp;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carregar variáveis de ambiente
  await EnvService.init();
  if (EnvService.isDevelopment) {
    EnvService.printAll();
  }

  // Initialize Firebase with DEV configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurar Crashlytics (desabilitado em DEV)
  FlutterError.onError = (details) {
    debugPrint('[DEV] Flutter Error: ${details.exception}');
    // FirebaseCrashlytics desabilitado em DEV
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[DEV] Async Error: $error');
    return true;
  };

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: WeGigApp()));
}
