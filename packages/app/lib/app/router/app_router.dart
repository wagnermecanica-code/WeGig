// lib/app/router/app_router.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../navigation/bottom_nav_scaffold.dart';
import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:wegig_app/core/firebase/blocked_profiles.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';
import 'package:wegig_app/features/auth/presentation/pages/auth_page.dart';
import 'package:wegig_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:wegig_app/features/mensagens_new/presentation/pages/chat_new_page.dart';
import 'package:wegig_app/features/post/presentation/pages/post_feed_page.dart';
import 'package:wegig_app/features/post/presentation/pages/post_detail_page.dart';
import 'package:wegig_app/features/connections/presentation/pages/connections_page.dart';
import 'package:wegig_app/features/connections/presentation/pages/connection_suggestions_page.dart';
import 'package:wegig_app/features/connections/presentation/pages/network_activity_page.dart';
import 'package:wegig_app/features/connections/presentation/pages/connection_requests_page.dart';
import 'package:wegig_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:wegig_app/features/profile/presentation/pages/view_profile_page.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:wegig_app/features/settings/presentation/pages/settings_page.dart';
import 'package:wegig_app/features/notifications_new/presentation/pages/notifications_new_page.dart';

part 'app_router.g.dart';

/// Notifier usado para pedir refresh do GoRouter sem recriar a instância.
///
/// Isso elimina glitches de navegação causados por reconstruções do provider
/// `goRouterProvider` (que desmontavam a AuthPage no meio do fluxo de login).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _subs.add(
      _ref.listen<AsyncValue<User?>>(authStateProvider, (_, __) {
        notifyListeners();
      }),
    );
    _subs.add(
      _ref.listen<AsyncValue<ProfileState>>(profileProvider, (_, __) {
        notifyListeners();
      }),
    );
    _subs.add(
      _ref.listen<bool>(authOperationInProgressProvider, (_, __) {
        notifyListeners();
      }),
    );
  }

  final Ref _ref;
  final List<ProviderSubscription<dynamic>> _subs = [];

  @override
  void dispose() {
    for (final s in _subs) {
      s.close();
    }
    _subs.clear();
    super.dispose();
  }
}

// ============================================
// TYPE-SAFE ROUTE CLASSES
// ============================================

/// Type-safe route definitions for compile-time navigation safety
class AppRoutes {
  const AppRoutes._();

  /// Auth route path
  static const String auth = '/auth';

  /// Splash/loading route path
  static const String splash = '/loading';

  /// Create profile route path
  static const String createProfile = '/profiles/new';

  /// Home route path
  static const String home = '/home';

  /// Profile route template
  static String profile(String profileId) => '/profile/$profileId';

  /// Post detail route template
  static String postDetail(String postId) => '/post/$postId';

  /// Post feed (vertical carrossel)
  static const String postFeed = '/posts/feed';

  /// Conversation/chat route template (legacy - ChatDetailPage)
  static String conversation(String conversationId) =>
      '/conversation/$conversationId';

  /// Chat new route template (MensagensNew feature)
  static String chatNew(String conversationId) => '/chat-new/$conversationId';

  /// Edit profile route template
  static String editProfile(String profileId) => '/profile/$profileId/edit';

  /// Notifications new route path
  static const String notificationsNew = '/notifications-new';

  /// Dedicated connections route path
  static const String connections = '/network/connections';

  /// Dedicated connection suggestions route path
  static const String connectionSuggestions = '/network/suggestions';

  /// Dedicated network activity route path
  static const String networkActivity = '/network/activity';

  /// Dedicated pending received requests route path
  static const String pendingReceivedRequests =
      '/network/requests/received';

  /// Dedicated pending sent requests route path
  static const String pendingSentRequests = '/network/requests/sent';
}

// ============================================
// ROUTER PROVIDER WITH AUTH GUARD
// ============================================

/// Provider do GoRouter com auth guard e redirect logic usando rotas tipadas
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  final slideTween = Tween<Offset>(
    begin: const Offset(
        0.02, 0.04), // Leve deslocamento para reduzir flashes brancos
    end: Offset.zero,
  );

  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    barrierColor: Colors.transparent,
    maintainState: true,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Apenas Slide - removido FadeTransition
      final Animation<Offset> slideAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ).drive(slideTween);

      return SlideTransition(
        position: slideAnimation,
        child: child,
      );
    },
  );
}

// ✅ NOVA TRANSIÇÃO: Slide lateral completo (estilo nativo iOS/Android)
CustomTransitionPage<void> _slideLeftPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0); // Começa da direita
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

@riverpod
GoRouter goRouter(Ref ref) {
  // ✅ CRÍTICO: manter UMA instância de GoRouter.
  // Não usar ref.watch(...) aqui, senão o provider reconstrói o GoRouter e
  // desmonta widgets (glitch + "ref after disposed" em fluxos async).
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.auth,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final isGoingToAuth = state.matchedLocation == AppRoutes.auth;
      final isGoingToSplash = state.matchedLocation == AppRoutes.splash;
      final isGoingToCreateProfile =
          state.matchedLocation == AppRoutes.createProfile;

      debugPrint(
          'Router: location=${state.matchedLocation}, isLoggedIn=$isLoggedIn, isGoingToAuth=$isGoingToAuth, isGoingToSplash=$isGoingToSplash, isGoingToCreateProfile=$isGoingToCreateProfile');

      // ✅ CRÍTICO: Se uma operação de auth está em andamento, não redirecionar
      // Isso evita race condition durante login social onde precisamos verificar
      // Firestore antes de decidir se o login é válido
      final isAuthOperationInProgress =
          ref.read(authOperationInProgressProvider);
      if (isAuthOperationInProgress) {
        debugPrint(
            'Router: ⏸️ Auth operation in progress, NOT redirecting (staying at ${state.matchedLocation})');
        return null; // Manter na rota atual
      }

      final profileState = isLoggedIn
          ? ref.read(profileProvider)
          : const AsyncValue<ProfileState>.data(ProfileState());

      final profileData = profileState.valueOrNull;
      final isProfileBootstrapping = profileData?.isLoading ?? false;
      // NOTE: `AsyncLoading` can carry a previous value during refresh.
      // We should treat that as usable profile data to avoid getting stuck on /loading.
      final hasProfileData = profileData != null;
      final hasAnyProfile = (profileData?.profiles.isNotEmpty ?? false);
      final hasActiveProfile = profileData?.activeProfile != null;

      // ✅ FIX: Mostrar splash apenas durante bootstrap real.
      // - Auth loading => sempre splash
      // - Logado, mas profile ainda não tem valor algum (AsyncLoading sem valor anterior) => splash
      // - Se profile estiver apenas fazendo refresh (AsyncLoading com valor anterior),
      //   NÃO bloquear navegação (evita bounce após salvar/editar perfil).
      final shouldShowSplash = authState.isLoading ||
          (isLoggedIn &&
              (isProfileBootstrapping ||
                  (!hasProfileData && profileState.isLoading)));

      debugPrint(
          'Router: authState.isLoading=${authState.isLoading}, authState.hasError=${authState.hasError}, user=$user');
      debugPrint(
          'Router: profileState.isLoading=${profileState.isLoading}, profileState.hasError=${profileState.hasError}');
      debugPrint(
          'Router: shouldShowSplash=$shouldShowSplash, hasProfileData=$hasProfileData, hasAnyProfile=$hasAnyProfile, hasActiveProfile=$hasActiveProfile');

      if (shouldShowSplash) {
        if (isGoingToSplash) return null;
        debugPrint('Router: shouldShowSplash, returning splash');
        return AppRoutes.splash;
      }

      // Se está logado mas o carregamento do profile falhou e não temos dados,
      // não ficar preso no splash; volta para /auth.
      if (isLoggedIn && !hasProfileData && profileState.hasError) {
        debugPrint('Router: profile load error without data, returning auth');
        return AppRoutes.auth;
      }

      if (!isLoggedIn) {
        debugPrint('Router: not logged in, returning auth');
        return AppRoutes.auth;
      }

      // ✅ CRÍTICO: Se profileState ainda está carregando (isLoading=true),
      // NÃO tomar decisão sobre createProfile ainda!
      // Isso evita race condition onde decidimos "não tem perfis" antes da query do servidor terminar.
      if (profileState.isLoading && !hasAnyProfile) {
        debugPrint(
            'Router: ⏳ profile still loading, waiting before deciding (staying at ${state.matchedLocation})');
        // Se já está no splash, ficar lá
        if (isGoingToSplash) return null;
        // Se está em outra rota válida, manter lá temporariamente
        if (!isGoingToAuth) return null;
        // Se está na auth, ir para splash para esperar
        return AppRoutes.splash;
      }

      // Agora sabemos que está logado E profileState carregou com sucesso
      if (hasProfileData && !isProfileBootstrapping && !hasAnyProfile) {
        debugPrint(
            'Router: logged in but no profiles, returning createProfile');
        return AppRoutes.createProfile;
      }

      // Usuário logado com perfis - verificar se está em rota permitida
      // Se está indo para auth/splash, redireciona para home
      // NOTA: createProfile é permitido para usuários que querem criar perfis adicionais
      if (isGoingToAuth || isGoingToSplash) {
        debugPrint('Router: logged in with profiles, redirecting to home');
        return AppRoutes.home;
      }

      // Rota atual é válida (home, profile, post, conversation, createProfile, etc) - não redirecionar
      debugPrint(
          'Router: logged in with profiles, allowing current route: ${state.matchedLocation}');
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => _fadePage(state, const _SplashPage()),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        pageBuilder: (context, state) => _fadePage(state, const AuthPage()),
      ),
      GoRoute(
        path: AppRoutes.createProfile,
        name: 'createProfile',
        pageBuilder: (context, state) =>
            _fadePage(state, const EditProfilePage(isNewProfile: true)),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          final indexRaw = state.uri.queryParameters['index'];

          int initialIndex = 0;
          if (tab == 'profile') {
            initialIndex = 4;
          } else if (indexRaw != null) {
            initialIndex = int.tryParse(indexRaw) ?? 0;
          }

          return _fadePage(
            state,
            BottomNavScaffold(initialIndex: initialIndex),
          );
        },
      ),
      GoRoute(
        path: '/profile/:profileId',
        name: 'profile',
        pageBuilder: (context, state) {
          final profileId = state.pathParameters['profileId']!;
          return CupertinoPage<void>(
            key: state.pageKey,
            child: ViewProfilePage(profileId: profileId),
          );
        },
      ),
      GoRoute(
        path: '/post/:postId',
        name: 'postDetail',
        pageBuilder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return CupertinoPage<void>(
            key: state.pageKey,
            child: PostDetailPage(postId: postId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.postFeed,
        name: 'postFeed',
        pageBuilder: (context, state) {
          final extra = state.extra;
          var posts = <PostEntity>[];
          var initialIndex = 0;
          String? mapCenterLabel;
          double? visibleRadiusKm;

          if (extra is Map) {
            final maybePosts = extra['posts'];
            if (maybePosts is List<PostEntity>) {
              posts = maybePosts;
            }
            final maybeIndex = extra['initialIndex'];
            if (maybeIndex is int) {
              initialIndex = maybeIndex;
            }
            final maybeMapLabel = extra['mapCenterLabel'];
            if (maybeMapLabel is String) {
              mapCenterLabel = maybeMapLabel;
            }
            final maybeRadius = extra['visibleRadiusKm'];
            if (maybeRadius is double) {
              visibleRadiusKm = maybeRadius;
            }
          }

          return _fadePage(
            state,
            PostFeedPage(
              posts: posts,
              initialIndex: initialIndex,
              mapCenterLabel: mapCenterLabel,
              visibleRadiusKm: visibleRadiusKm,
            ),
          );
        },
      ),
      GoRoute(
        path: '/conversation/:conversationId',
        name: 'conversation',
        pageBuilder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final otherUserId = state.uri.queryParameters['otherUserId'];
          final otherProfileId = state.uri.queryParameters['otherProfileId'];
          final otherUserName = state.uri.queryParameters['otherUserName'];
          final otherUserPhoto = state.uri.queryParameters['otherUserPhoto'];
          return _fadePage(
            state,
            ChatNewPage(
              conversationId: conversationId,
              otherUid: otherUserId ?? '',
              otherProfileId: otherProfileId ?? '',
              otherName: otherUserName ?? '',
              otherPhotoUrl: otherUserPhoto ?? '',
            ),
          );
        },
      ),
      // ✅ NOVA ROTA: Notifications New (substituindo a antiga)
      GoRoute(
        path: '/notifications-new',
        name: 'notificationsNew',
        pageBuilder: (context, state) =>
            _slideLeftPage(state, const NotificationsNewPage()),
      ),
      GoRoute(
        path: AppRoutes.connections,
        name: 'connections',
        pageBuilder: (context, state) =>
            _slideLeftPage(state, const ConnectionsPage()),
      ),
      GoRoute(
        path: AppRoutes.connectionSuggestions,
        name: 'connectionSuggestions',
        pageBuilder: (context, state) =>
            _slideLeftPage(state, const ConnectionSuggestionsPage()),
      ),
      GoRoute(
        path: AppRoutes.networkActivity,
        name: 'networkActivity',
        pageBuilder: (context, state) =>
            _slideLeftPage(state, const NetworkActivityPage()),
      ),
      GoRoute(
        path: AppRoutes.pendingReceivedRequests,
        name: 'pendingReceivedRequests',
        pageBuilder: (context, state) => _slideLeftPage(
          state,
          const ConnectionRequestsPage.received(),
        ),
      ),
      GoRoute(
        path: AppRoutes.pendingSentRequests,
        name: 'pendingSentRequests',
        pageBuilder: (context, state) => _slideLeftPage(
          state,
          const ConnectionRequestsPage.sent(),
        ),
      ),
      // ✅ NOVA ROTA: Chat New (MensagensNew feature)
      GoRoute(
        path: '/chat-new/:conversationId',
        name: 'chatNew',
        pageBuilder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final otherUid = state.uri.queryParameters['otherUid'] ?? '';
          final otherProfileId =
              state.uri.queryParameters['otherProfileId'] ?? '';
          final isGroup =
              (state.uri.queryParameters['isGroup'] ?? '').trim() == 'true';
          final groupName = state.uri.queryParameters['groupName'] ?? '';
          final otherName =
              (isGroup ? groupName : state.uri.queryParameters['otherName']) ??
                  '';
          final otherPhotoUrl = state.uri.queryParameters['otherPhotoUrl'];
          final groupPhotoUrl = state.uri.queryParameters['groupPhotoUrl'];
          return _slideLeftPage(
            state,
            ChatNewPage(
              conversationId: conversationId,
              otherUid: otherUid,
              otherProfileId: otherProfileId,
              otherName: otherName,
              otherPhotoUrl: otherPhotoUrl,
              isGroup: isGroup,
              groupPhotoUrl: groupPhotoUrl,
            ),
          );
        },
      ),
      // ✅ NOVA ROTA: Settings com transição Slide
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) =>
            _slideLeftPage(state, const SettingsPage()),
      ),
      GoRoute(
        path: '/profile/:profileId/edit',
        name: 'editProfile',
        pageBuilder: (context, state) {
          final profileId = state.pathParameters['profileId']!;
          return _fadePage(
            state,
            EditProfilePage(profileIdToEdit: profileId),
          );
        },
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Página não encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Voltar ao Início'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 64,
          height: 64,
          child: AppRadioPulseLoader(
            size: 64,
          ),
        ),
      ),
    );
  }
}

// ============================================
// TYPE-SAFE NAVIGATION EXTENSIONS
// ============================================

/// Type-safe navigation extension methods
extension TypedNavigationExtension on BuildContext {
  /// Navigate to auth page
  void goToAuth() => go(AppRoutes.auth);

  /// Navigate to home page
  void goToHome() => go(AppRoutes.home);

  /// Navigate to create profile page
  void goToCreateProfile() => go(AppRoutes.createProfile);

  /// Navigate to profile page with type-safe parameters
  void goToProfile(String profileId) => go(AppRoutes.profile(profileId));

  /// Navigate to post detail page with type-safe parameters
  void goToPostDetail(String postId) => go(AppRoutes.postDetail(postId));

  /// Push to profile page (adds to stack)
  void pushProfile(String profileId) {
    _logNavigation('profile', {'profileId': profileId});
    push(AppRoutes.profile(profileId));
  }

  /// Push to post detail page (adds to stack)
  void pushPostDetail(String postId) {
    _logNavigation('post_detail', {'postId': postId});
    push(AppRoutes.postDetail(postId));
  }

  /// Push vertical post feed (carrossel)
  void pushPostFeed(
    List<PostEntity> posts, {
    int initialIndex = 0,
    String? mapCenterLabel,
    double? visibleRadiusKm,
  }) {
    _logNavigation('post_feed', {
      'initialIndex': initialIndex.toString(),
      'count': posts.length.toString(),
    });
    push(
      AppRoutes.postFeed,
      extra: {
        'posts': posts,
        'initialIndex': initialIndex,
        'mapCenterLabel': mapCenterLabel,
        'visibleRadiusKm': visibleRadiusKm,
      },
    );
  }

  /// Navigate to conversation/chat page
  void goToConversation(
    String conversationId, {
    String? otherUserId,
    String? otherProfileId,
    String? otherUserName,
    String? otherUserPhoto,
  }) {
    _logNavigation('conversation', {'conversationId': conversationId});
    final uri = Uri(
      path: AppRoutes.conversation(conversationId),
      queryParameters: {
        if (otherUserId != null) 'otherUserId': otherUserId,
        if (otherProfileId != null) 'otherProfileId': otherProfileId,
        if (otherUserName != null) 'otherUserName': otherUserName,
        if (otherUserPhoto != null) 'otherUserPhoto': otherUserPhoto,
      },
    );
    go(uri.toString());
  }

  /// Push to conversation/chat page (adds to stack)
  void pushConversation(
    String conversationId, {
    String? otherUserId,
    String? otherProfileId,
    String? otherUserName,
    String? otherUserPhoto,
  }) {
    _logNavigation('conversation', {'conversationId': conversationId});
    final uri = Uri(
      path: AppRoutes.conversation(conversationId),
      queryParameters: {
        if (otherUserId != null) 'otherUserId': otherUserId,
        if (otherProfileId != null) 'otherProfileId': otherProfileId,
        if (otherUserName != null) 'otherUserName': otherUserName,
        if (otherUserPhoto != null) 'otherUserPhoto': otherUserPhoto,
      },
    );
    push(uri.toString());
  }

  /// Navigate to chat new page (MensagensNew feature)
  void goToChatNew(
    String conversationId, {
    required String otherUid,
    required String otherProfileId,
    required String otherName,
    String? otherPhotoUrl,
  }) {
    _logNavigation('chat_new', {'conversationId': conversationId});
    final uri = Uri(
      path: AppRoutes.chatNew(conversationId),
      queryParameters: {
        'otherUid': otherUid,
        'otherProfileId': otherProfileId,
        'otherName': otherName,
        if (otherPhotoUrl != null) 'otherPhotoUrl': otherPhotoUrl,
      },
    );
    go(uri.toString());
  }

  /// Push to chat new page (MensagensNew feature - adds to stack)
  void pushChatNew(
    String conversationId, {
    required String otherUid,
    required String otherProfileId,
    required String otherName,
    String? otherPhotoUrl,
  }) {
    _logNavigation('chat_new', {'conversationId': conversationId});
    final uri = Uri(
      path: AppRoutes.chatNew(conversationId),
      queryParameters: {
        'otherUid': otherUid,
        'otherProfileId': otherProfileId,
        'otherName': otherName,
        if (otherPhotoUrl != null) 'otherPhotoUrl': otherPhotoUrl,
      },
    );
    push(uri.toString());
  }

  /// Push notifications inbox page
  void pushNotificationsNew() {
    _logNavigation('notifications_new', {});
    push(AppRoutes.notificationsNew);
  }

  /// Push dedicated connections page
  void pushConnections() {
    _logNavigation('connections', {});
    push(AppRoutes.connections);
  }

  /// Push dedicated connection suggestions page
  void pushConnectionSuggestions() {
    _logNavigation('connection_suggestions', {});
    push(AppRoutes.connectionSuggestions);
  }

  /// Push dedicated network activity page
  void pushNetworkActivity() {
    _logNavigation('network_activity', {});
    push(AppRoutes.networkActivity);
  }

  /// Push dedicated pending received requests page
  void pushPendingReceivedRequests() {
    _logNavigation('pending_received_requests', {});
    push(AppRoutes.pendingReceivedRequests);
  }

  /// Push dedicated pending sent requests page
  void pushPendingSentRequests() {
    _logNavigation('pending_sent_requests', {});
    push(AppRoutes.pendingSentRequests);
  }

  /// Push profile screen resolving from @username
  Future<void> pushProfileByUsername(String username) async {
    final sanitized = username.trim().replaceAll('@', '');
    if (sanitized.isEmpty) {
      AppSnackBar.showError(this, 'Perfil não encontrado');
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final container = ProviderScope.containerOf(this);
      final activeProfile = container.read(activeProfileProvider);

      final excludedProfileIds = (currentUser == null || activeProfile == null)
          ? const <String>[]
          : await BlockedRelations.getExcludedProfileIds(
              firestore: FirebaseFirestore.instance,
              profileId: activeProfile.profileId,
              uid: currentUser.uid,
            );

      final query = await FirebaseFirestore.instance
          .collection('profiles')
          .where(
            'usernameLowercase',
            isEqualTo: sanitized.toLowerCase(),
          )
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        AppSnackBar.showError(this, 'Perfil não encontrado');
        return;
      }

      final targetProfileId = query.docs.first.id;
      if (excludedProfileIds.contains(targetProfileId)) {
        AppSnackBar.showInfo(this, 'Perfil indisponível.');
        return;
      }

      pushProfile(targetProfileId);
    } catch (error, stackTrace) {
      debugPrint('pushProfileByUsername error: $error');
      debugPrintStack(stackTrace: stackTrace);
      AppSnackBar.showError(
        this,
        'Não conseguimos abrir esse perfil agora.',
      );
    }
  }

  /// Navigate to edit profile page
  void goToEditProfile(String profileId) {
    _logNavigation('edit_profile', {'profileId': profileId});
    go(AppRoutes.editProfile(profileId));
  }

  /// Push to edit profile page (adds to stack)
  void pushEditProfile(String profileId) {
    _logNavigation('edit_profile', {'profileId': profileId});
    push(AppRoutes.editProfile(profileId));
  }

  /// Log navigation event to Firebase Analytics
  /// CRITICAL: Includes active_profile_id for proper analytics segmentation
  void _logNavigation(String screenName, Map<String, String> parameters) {
    try {
      // Note: active_profile_id is set via setUserProperty in ProfileNotifier
      // Here we just log the navigation event
      FirebaseAnalytics.instance.logEvent(
        name: 'navigate_$screenName',
        parameters: parameters,
      );
      FirebaseAnalytics.instance.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }
}
