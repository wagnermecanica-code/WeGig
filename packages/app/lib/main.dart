import 'dart:ui' show PlatformDispatcher;

import 'package:core_ui/services/env_service.dart';
import 'package:core_ui/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carregar variáveis de ambiente ANTES de inicializar Firebase
  await EnvService.init();
  if (EnvService.isDevelopment) {
    EnvService.printAll(); // Debug apenas em dev
  }

  // Firebase initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurar Crashlytics
  FlutterError.onError = (details) {
    debugPrint('Flutter Error: ${details.exception}');
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async Error: $error');
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Forçar orientação portrait (UX consistente)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: WeGigApp()));
}

/// Tela de erro exibida quando Firebase não inicializa
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Color(0xFFFF5252),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Erro ao conectar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Não foi possível conectar aos servidores.\nVerifique sua conexão e tente novamente.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF757575),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: SystemNavigator.pop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A699),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Fechar App',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WeGigApp extends ConsumerWidget {
  const WeGigApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'WeGig',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.light, // TODO: Criar dark theme

      // Limita textScale para acessibilidade (0.8x - 1.5x)
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler
                .clamp(minScaleFactor: 0.8, maxScaleFactor: 1.5),
          ),
          child: child!,
        );
      },
    );
  }
}

class App extends ConsumerWidget {

  const App({
    required this.flavor, required this.appName, super.key,
  });
  final String flavor;
  final String appName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    // Show debug banner only for dev/staging
    final showDebugBanner = flavor != 'prod';

    return MaterialApp.router(
      routerConfig: router,
      title: appName,
      debugShowCheckedModeBanner: showDebugBanner,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,

      // Limita textScale para acessibilidade (0.8x - 1.5x)
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);

        // Add flavor banner in dev/staging
        Widget result = MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler
                .clamp(minScaleFactor: 0.8, maxScaleFactor: 1.5),
          ),
          child: child!,
        );

        if (showDebugBanner) {
          result = Banner(
            message: flavor.toUpperCase(),
            location: BannerLocation.topEnd,
            color: flavor == 'dev' ? Colors.blue : Colors.orange,
            child: result,
          );
        }

        return result;
      },
    );
  }
}
