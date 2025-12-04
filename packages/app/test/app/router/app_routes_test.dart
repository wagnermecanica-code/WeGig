import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/app/router/app_router.dart';

void main() {
  group('AppRoutes', () {
    test('auth route should be /auth', () {
      expect(AppRoutes.auth, '/auth');
    });

    test('home route should be /home', () {
      expect(AppRoutes.home, '/home');
    });

    test('createProfile route should be /profiles/new', () {
      expect(AppRoutes.createProfile, '/profiles/new');
    });

    test('profile route should include profileId', () {
      const testId = 'profile123';
      expect(AppRoutes.profile(testId), '/profile/$testId');
    });

    test('postDetail route should include postId', () {
      const testId = 'post456';
      expect(AppRoutes.postDetail(testId), '/post/$testId');
    });

    test('conversation route should include conversationId', () {
      const testId = 'conv789';
      expect(AppRoutes.conversation(testId), '/conversation/$testId');
    });

    test('editProfile route should include profileId', () {
      const testId = 'profile123';
      expect(AppRoutes.editProfile(testId), '/profile/$testId/edit');
    });

    test('profile route should handle special characters', () {
      const testId = 'profile-with-dashes_123';
      expect(AppRoutes.profile(testId), '/profile/$testId');
    });

    test('postDetail route should handle UUID format', () {
      const testId = '550e8400-e29b-41d4-a716-446655440000';
      expect(AppRoutes.postDetail(testId), '/post/$testId');
    });

    test('all route constants should start with /', () {
      expect(AppRoutes.auth.startsWith('/'), isTrue);
      expect(AppRoutes.home.startsWith('/'), isTrue);
      expect(AppRoutes.createProfile.startsWith('/'), isTrue);
    });

    test('all route factories should return absolute paths', () {
      expect(AppRoutes.profile('test').startsWith('/'), isTrue);
      expect(AppRoutes.postDetail('test').startsWith('/'), isTrue);
      expect(AppRoutes.conversation('test').startsWith('/'), isTrue);
      expect(AppRoutes.editProfile('test').startsWith('/'), isTrue);
    });

    test('route factories should not add trailing slashes', () {
      expect(AppRoutes.profile('test').endsWith('/'), isFalse);
      expect(AppRoutes.postDetail('test').endsWith('/'), isFalse);
    });

    // editProfile route not implemented yet
    // Uncomment when added to AppRoutes class
  });

  group('TypedNavigationExtension', () {
    // Note: Extension methods can't be directly unit tested without a BuildContext
    // These tests verify the route generation logic that powers the extensions

    test('goToProfile should use correct route', () {
      const profileId = 'profile123';
      const expectedRoute = '/profile/$profileId';

      expect(AppRoutes.profile(profileId), expectedRoute);
    });

    test('goToPostDetail should use correct route', () {
      const postId = 'post456';
      const expectedRoute = '/post/$postId';

      expect(AppRoutes.postDetail(postId), expectedRoute);
    });

    test('goToConversation should use correct route', () {
      const conversationId = 'conv789';
      const expectedRoute = '/conversation/$conversationId';

      expect(AppRoutes.conversation(conversationId), expectedRoute);
    });

    test('goToEditProfile should use correct route', () {
      const profileId = 'profile123';
      const expectedRoute = '/profile/$profileId/edit';

      expect(AppRoutes.editProfile(profileId), expectedRoute);
    });
  });

  group('Route Path Validation', () {
    test('no routes should have double slashes', () {
      expect(AppRoutes.auth.contains('//'), isFalse);
      expect(AppRoutes.home.contains('//'), isFalse);
      expect(AppRoutes.profile('test').contains('//'), isFalse);
      expect(AppRoutes.postDetail('test').contains('//'), isFalse);
    });

    test('no routes should have spaces', () {
      expect(AppRoutes.auth.contains(' '), isFalse);
      expect(AppRoutes.home.contains(' '), isFalse);
      expect(AppRoutes.createProfile.contains(' '), isFalse);
    });

    test('route factories should handle empty strings safely', () {
      // Empty IDs should still produce valid paths
      expect(AppRoutes.profile(''), '/profile/');
      expect(AppRoutes.postDetail(''), '/post/');
    });

    test('route factories should handle very long IDs', () {
      final longId = 'a' * 500;
      final route = AppRoutes.profile(longId);

      expect(route.startsWith('/profile/'), isTrue);
      expect(route.length, 509); // '/profile/' (9) + 500 chars
    });
  });

  group('Route Consistency', () {
    test('editProfile route should have correct structure', () {
      const profileId = 'profile123';
      final route = AppRoutes.editProfile(profileId);

      expect(route, '/profile/$profileId/edit');
      expect(route.startsWith('/profile/'), isTrue);
      expect(route.endsWith('/edit'), isTrue);
    });

    test('all parameterized routes should follow pattern', () {
      const testId = 'test123';

      // Pattern: /entity/:id or /entity/:id/action
      expect(AppRoutes.profile(testId), matches(r'^/profile/.+$'));
      expect(AppRoutes.postDetail(testId), matches(r'^/post/.+$'));
      expect(AppRoutes.conversation(testId), matches(r'^/conversation/.+$'));
      expect(AppRoutes.editProfile(testId), matches(r'^/profile/.+/edit$'));
    });
  });
}
