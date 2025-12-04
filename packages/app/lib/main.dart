import 'package:core_ui/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/bootstrap/bootstrap_core.dart';
import 'package:wegig_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapCoreServices(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    flavorLabel: 'prod',
    expectedProjectId: 'wegig-dev',
    backgroundHandler: _firebaseMessagingBackgroundHandler,
    enableCrashlytics: true,
  );

  runApp(const ProviderScope(child: WeGigApp()));
}

/// Handler de mensagens em background/terminated
/// CRÍTICO: Deve estar no top-level (não dentro de classe)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  debugPrint('📩 [prod] Background Message: ${message.messageId}');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');
}

/// Tela de erro exibida quando Firebase não inicializa
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
