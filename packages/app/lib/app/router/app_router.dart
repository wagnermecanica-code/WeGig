// lib/app/router/app_router.dart
import 'package:core_ui/navigation/bottom_nav_scaffold.dart';
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

  /// Create profile route path
  static const String createProfile = '/create-profile';

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
@riverpod
GoRouter goRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);
  final profileState = ref.watch(profileProvider);

  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authState.value != null;
      final isGoingToAuth = state.matchedLocation == '/auth';
      final isGoingToCreateProfile = state.matchedLocation == '/create-profile';
      final hasProfile = profileState.value?.activeProfile != null;

      // Se não está logado e não vai para auth, redireciona para auth
      if (!isLoggedIn && !isGoingToAuth) {
        return '/auth';
      }

      // Se está logado e vai para auth, redireciona para home
      if (isLoggedIn && isGoingToAuth) {
        return '/home';
      }

      // Se está logado, mas não tem perfil e não está indo para criar perfil
      if (isLoggedIn && !hasProfile && !isGoingToCreateProfile) {
        return '/create-profile';
      }

      // Caso contrário, permite navegação
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (BuildContext context, GoRouterState state) =>
            const AuthPage(),
      ),
      GoRoute(
        path: '/create-profile',
        name: 'createProfile',
        builder: (BuildContext context, GoRouterState state) =>
            const EditProfilePage(isNewProfile: true),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (BuildContext context, GoRouterState state) =>
            const BottomNavScaffold(),
      ),
      GoRoute(
        path: '/profile/:profileId',
        name: 'profile',
        builder: (BuildContext context, GoRouterState state) {
          final profileId = state.pathParameters['profileId']!;
          return ViewProfilePage(profileId: profileId);
        },
      ),
      GoRoute(
        path: '/post/:postId',
        name: 'postDetail',
        builder: (BuildContext context, GoRouterState state) {
          final postId = state.pathParameters['postId']!;
          return PostDetailPage(postId: postId);
        },
      ),
      GoRoute(
        path: '/conversation/:conversationId',
        name: 'conversation',
        builder: (BuildContext context, GoRouterState state) {
          final conversationId = state.pathParameters['conversationId']!;
          final otherUserId = state.uri.queryParameters['otherUserId'];
          final otherProfileId = state.uri.queryParameters['otherProfileId'];
          final otherUserName = state.uri.queryParameters['otherUserName'];
          final otherUserPhoto = state.uri.queryParameters['otherUserPhoto'];
          return ChatDetailPage(
            conversationId: conversationId,
            otherUserId: otherUserId ?? '',
            otherProfileId: otherProfileId ?? '',
            otherUserName: otherUserName ?? '',
            otherUserPhoto: otherUserPhoto ?? '',
          );
        },
      ),
      GoRoute(
        path: '/profile/:profileId/edit',
        name: 'editProfile',
        builder: (BuildContext context, GoRouterState state) {
          final profileId = state.pathParameters['profileId']!;
          return EditProfilePage(profileIdToEdit: profileId);
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
