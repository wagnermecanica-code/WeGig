import 'package:core_ui/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/app/router/push_notification_router.dart';
import 'package:wegig_app/bootstrap/bootstrap_core.dart';
import 'package:wegig_app/firebase_options.dart';
import 'package:wegig_app/features/notifications_new/data/services/push_notification_service.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'dart:async' show unawaited;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapCoreServices(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    flavorLabel: 'prod',
    expectedProjectId: 'to-sem-banda-83e19',
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
class WeGigApp extends ConsumerStatefulWidget {
  const WeGigApp({super.key});

  @override
  ConsumerState<WeGigApp> createState() => _WeGigAppState();
}

class _WeGigAppState extends ConsumerState<WeGigApp>
    with WidgetsBindingObserver {
  ProviderSubscription<GoRouter>? _routerSub;
  ProviderSubscription<AsyncValue<ProfileState>>? _profileSub;

  /// Push notification recebida ao abrir app do estado terminated.
  /// Armazenada aqui quando o profile ainda não carregou (router em /splash),
  /// para ser processada assim que o profile estiver pronto e o router
  /// estabilizar em /home.
  RemoteMessage? _deferredPushMessage;

  bool _canHandlePushForActiveProfile(
    RemoteMessage message,
    String activeProfileId,
  ) {
    final type = (message.data['type'] as String?)?.trim();

    // Restrição de perfil é crítica para mensagens.
    if (type != 'newMessage') {
      return true;
    }

    final payloadRecipientProfileId =
        (message.data['recipientProfileId'] as String?)?.trim();

    // Compat com pushes legados sem recipientProfileId explícito.
    if (payloadRecipientProfileId == null ||
        payloadRecipientProfileId.isEmpty) {
      return true;
    }

    final allowed = payloadRecipientProfileId == activeProfileId;
    if (!allowed) {
      debugPrint(
        '🚫 WeGigApp: Push newMessage ignorada por mismatch de perfil '
        '(active=$activeProfileId, recipient=$payloadRecipientProfileId)',
      );
    }
    return allowed;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Bind push notification taps to router navigation once.
    // Also flushes any pending tap captured during bootstrap (terminated).
    //
    // ⚠️ TERMINATED STATE: Quando o app abre do estado terminated via tap
    // em notificação, o profile ainda está carregando e o GoRouter redirect
    // manda tudo para /splash. Se navegarmos agora, o push('/post/$id') é
    // engolido pelo redirect. Solução: armazenar a mensagem em
    // _deferredPushMessage e processar quando o profile carregar.
    _routerSub = ref.listenManual<GoRouter>(
      goRouterProvider,
      (_, router) {
        final service = PushNotificationService();
        service.attachOnNotificationTapped((RemoteMessage message) {
          final profileState = ref.read(profileProvider);
          final activeProfile = profileState.valueOrNull?.activeProfile;
          final hasActiveProfile = activeProfile != null;

          if (hasActiveProfile) {
            if (!_canHandlePushForActiveProfile(
              message,
              activeProfile.profileId,
            )) {
              return;
            }

            // Profile pronto → router já estabilizou em /home → navegar direto
            unawaited(
              handlePushNotificationTap(router: router, message: message),
            );
          } else {
            // Profile ainda carregando → adiar navegação
            debugPrint(
              '🔔 WeGigApp: Deferring push navigation until profile loads '
              '(type=${message.data['type']})',
            );
            _deferredPushMessage = message;
          }
        });
      },
      fireImmediately: true,
    );

    // Sincronizar badge do ícone do app ao iniciar
    _syncAppBadge();

    // Também sincroniza quando o profileProvider finalmente carregar ou quando
    // o usuário trocar de perfil (initState pode rodar antes do profile estar pronto).
    _profileSub = ref.listenManual(
      profileProvider,
      (_, next) {
        final activeProfile = next.valueOrNull?.activeProfile;
        if (activeProfile == null) return;
        unawaited(
          PushNotificationService().updateAppBadge(
            activeProfile.profileId,
            activeProfile.uid,
          ),
        );

        // ✅ Processar push notification adiada (terminated state).
        // Agora o profile carregou → redirect vai mandar para /home →
        // podemos empilhar a tela destino com segurança.
        final deferred = _deferredPushMessage;
        if (deferred != null) {
          if (!_canHandlePushForActiveProfile(
            deferred,
            activeProfile.profileId,
          )) {
            _deferredPushMessage = null;
            return;
          }

          _deferredPushMessage = null;
          debugPrint(
            '🔔 WeGigApp: Profile loaded, processing deferred push '
            '(type=${deferred.data['type']})',
          );
          final router = ref.read(goRouterProvider);
          // Pequeno delay para garantir que o redirect de /splash → /home
          // completou antes de empilhar a tela destino.
          Future.delayed(const Duration(milliseconds: 500), () {
            unawaited(
              handlePushNotificationTap(router: router, message: deferred),
            );
          });
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _syncAppBadge();
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _releaseMemoryCaches(reason: 'background');
    }
  }

  /// Chamado pelo Flutter quando o sistema operacional sinaliza pressão de
  /// memória (iOS `applicationDidReceiveMemoryWarning`, Android `onTrimMemory`).
  /// Libera caches voláteis para tentar evitar o kill do processo.
  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    _releaseMemoryCaches(reason: 'memory-warning');
  }

  void _releaseMemoryCaches({required String reason}) {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final beforeBytes = imageCache.currentSizeBytes;
      final beforeCount = imageCache.currentSize;
      imageCache.clear();
      imageCache.clearLiveImages();
      debugPrint(
        '🧹 WeGigApp: imageCache cleared ($reason) — freed ~${beforeBytes ~/ 1024} KB, $beforeCount images',
      );
    } catch (e) {
      debugPrint('⚠️ WeGigApp: Error releasing caches ($reason): $e');
    }
  }

  /// Sincroniza o badge do ícone do app com notificações não lidas do Firestore
  Future<void> _syncAppBadge() async {
    try {
      final profileState = ref.read(profileProvider);
      final activeProfile = profileState.value?.activeProfile;
      if (activeProfile != null) {
        await PushNotificationService().updateAppBadge(
          activeProfile.profileId,
          activeProfile.uid,
        );
      }
    } catch (e) {
      debugPrint('❌ WeGigApp: Error syncing app badge: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routerSub?.close();
    _routerSub = null;
    _profileSub?.close();
    _profileSub = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    required this.flavor,
    required this.appName,
    super.key,
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
