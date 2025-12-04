// lib/app/router/app_router.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/navigation/bottom_nav_scaffold.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/features/auth/presentation/pages/auth_page.dart';
import 'package:wegig_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:wegig_app/features/messages/presentation/pages/chat_detail_page.dart';
import 'package:wegig_app/features/post/presentation/pages/post_detail_page.dart';
import 'package:wegig_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:wegig_app/features/profile/presentation/pages/view_profile_page.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

part 'app_router.g.dart';

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

  /// Conversation/chat route template
  static String conversation(String conversationId) =>
      '/conversation/$conversationId';

  /// Edit profile route template
  static String editProfile(String profileId) => '/profile/$profileId/edit';
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
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    barrierColor: Colors.transparent,
    maintainState: true,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final Animation<double> fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final Animation<Offset> slideAnimation = fadeAnimation.drive(slideTween);
      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
  );
}

@riverpod
GoRouter goRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);
  final profileState = authState.valueOrNull != null ? ref.watch(profileProvider) : AsyncValue<ProfileState>.data(ProfileState());

  return GoRouter(
    initialLocation: AppRoutes.auth,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final isGoingToAuth = state.matchedLocation == AppRoutes.auth;
      final isGoingToSplash = state.matchedLocation == AppRoutes.splash;
      final isGoingToCreateProfile =
          state.matchedLocation == AppRoutes.createProfile;

      debugPrint('Router: location=${state.matchedLocation}, isLoggedIn=$isLoggedIn, isGoingToAuth=$isGoingToAuth, isGoingToSplash=$isGoingToSplash, isGoingToCreateProfile=$isGoingToCreateProfile');

      final profileData = profileState.valueOrNull;
      final hasProfileData = profileState is AsyncData<ProfileState>;
      final hasAnyProfile = (profileData?.profiles.isNotEmpty ?? false);
      final hasActiveProfile = profileData?.activeProfile != null;
      final isCheckingAuth = authState.isLoading ||
          (isLoggedIn && profileState.isLoading);

      debugPrint('Router: authState.isLoading=${authState.isLoading}, authState.hasError=${authState.hasError}, user=$user');
      debugPrint('Router: isCheckingAuth=$isCheckingAuth, hasProfileData=$hasProfileData, hasAnyProfile=$hasAnyProfile, hasActiveProfile=$hasActiveProfile');

      if (isCheckingAuth) {
        debugPrint('Router: isCheckingAuth, returning splash');
        return AppRoutes.splash;
      }

      if (!isLoggedIn) {
        debugPrint('Router: not logged in, returning auth');
        return AppRoutes.auth;
      }

      // Agora sabemos que está logado
      if (hasProfileData && !hasAnyProfile) {
        debugPrint('Router: logged in but no profiles, returning createProfile');
        return AppRoutes.createProfile;
      }

      debugPrint('Router: logged in with profiles, returning home');
      return AppRoutes.home;
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
        pageBuilder: (context, state) =>
            _fadePage(state, const BottomNavScaffold()),
      ),
      GoRoute(
        path: '/profile/:profileId',
        name: 'profile',
        pageBuilder: (context, state) {
          final profileId = state.pathParameters['profileId']!;
          return _fadePage(state, ViewProfilePage(profileId: profileId));
        },
      ),
      GoRoute(
        path: '/post/:postId',
        name: 'postDetail',
        pageBuilder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return _fadePage(state, PostDetailPage(postId: postId));
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
            ChatDetailPage(
              conversationId: conversationId,
              otherUserId: otherUserId ?? '',
              otherProfileId: otherProfileId ?? '',
              otherUserName: otherUserName ?? '',
              otherUserPhoto: otherUserPhoto ?? '',
            ),
          );
        },
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
          width: 48,
          height: 48,
          child: CircularProgressIndicator(),
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

  /// Push profile screen resolving from @username
  Future<void> pushProfileByUsername(String username) async {
    final sanitized = username.trim().replaceAll('@', '');
    if (sanitized.isEmpty) {
      AppSnackBar.showError(this, 'Perfil não encontrado');
      return;
    }

    try {
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

      pushProfile(query.docs.first.id);
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
  void _logNavigation(String screenName, Map<String, String> parameters) {
    try {
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
