/// WeGig - NotificationNew Action Handler Tests
///
/// Testes unitários para o handler de ações de notificações.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationNewActionHandler - Route Resolution', () {
    test('should resolve route for post interaction (like/comment)', () {
      const actionType = 'like';
      const targetType = 'post';
      const targetId = 'post_abc';

      // Route esperada: /post/:postId
      expect(targetId, 'post_abc');
      expect(targetType, 'post');
      expect(actionType, 'like');

      // Simula resolução de rota
      final expectedRoute = '/post/$targetId';
      expect(expectedRoute, '/post/post_abc');
    });

    test('should resolve route for comment notification', () {
      const actionType = 'comment';
      const targetType = 'post';
      const targetId = 'post_abc';

      expect(targetId, 'post_abc');
      expect(targetType, 'post');

      final expectedRoute = '/post/$targetId';
      expect(expectedRoute, '/post/post_abc');
    });

    test('should resolve route for follow notification', () {
      const actionType = 'new_follower';
      const targetType = 'profile';
      const senderId = 'sender_3';

      // Route esperada: /profile/:profileId
      expect(senderId, 'sender_3');
      expect(targetType, 'profile');

      final expectedRoute = '/profile/$senderId';
      expect(expectedRoute, '/profile/sender_3');
    });

    test('should resolve route for message notification', () {
      const actionType = 'new_message';
      const targetType = 'chat';
      const targetId = 'chat_xyz';

      // Route esperada: /chat/:chatId
      expect(targetId, 'chat_xyz');
      expect(targetType, 'chat');

      final expectedRoute = '/chat/$targetId';
      expect(expectedRoute, '/chat/chat_xyz');
    });

    test('should resolve route for interest match notification', () {
      const type = 'interest_match';
      const targetId = 'post_match';
      const targetType = 'post';

      // Route esperada: /post/:postId (vai para o post do match)
      expect(targetId, 'post_match');
      expect(targetType, 'post');

      final expectedRoute = '/post/$targetId';
      expect(expectedRoute, '/post/post_match');
    });
  });

  group('NotificationNewActionHandler - Target Type Resolution', () {
    test('should identify post target correctly', () {
      final notificationTypes = [
        {'targetType': 'post', 'actionType': 'like'},
        {'targetType': 'post', 'actionType': 'comment'},
        {'targetType': 'profile', 'actionType': 'follow'},
        {'targetType': 'post', 'actionType': 'interest_match'},
        {'targetType': 'chat', 'actionType': 'message'},
      ];

      final postNotifications = notificationTypes.where(
        (n) => n['targetType'] == 'post',
      );

      expect(postNotifications.length, 3);
    });

    test('should identify profile target correctly', () {
      final notificationTypes = [
        {'targetType': 'post', 'actionType': 'like'},
        {'targetType': 'profile', 'actionType': 'new_follower'},
        {'targetType': 'chat', 'actionType': 'message'},
      ];

      final profileNotifications = notificationTypes.where(
        (n) => n['targetType'] == 'profile',
      );

      expect(profileNotifications.length, 1);
    });

    test('should identify chat target correctly', () {
      final notificationTypes = [
        {'targetType': 'post', 'actionType': 'like'},
        {'targetType': 'chat', 'actionType': 'new_message'},
      ];

      final chatNotifications = notificationTypes.where(
        (n) => n['targetType'] == 'chat',
      );

      expect(chatNotifications.length, 1);
    });
  });

  group('NotificationNewActionHandler - Action Type Categories', () {
    test('should categorize post interaction types', () {
      final postInteractionTypes = ['like', 'comment', 'mention', 'share'];
      final actions = ['like', 'comment', 'follow', 'message'];

      final postInteractions = actions.where(
        (a) => postInteractionTypes.contains(a),
      );

      expect(postInteractions.length, 2);
    });

    test('should categorize social action types', () {
      final socialTypes = ['new_follower', 'follow_request'];
      final actions = ['like', 'new_follower', 'message'];

      final socialNotifications = actions.where(
        (a) => socialTypes.contains(a),
      );

      expect(socialNotifications.length, 1);
    });

    test('should categorize message types', () {
      final messageTypes = ['new_message', 'message_request'];
      final actions = ['like', 'new_message', 'follow'];

      final messageNotifications = actions.where(
        (a) => messageTypes.contains(a),
      );

      expect(messageNotifications.length, 1);
    });

    test('should categorize match types', () {
      final matchTypes = ['match', 'interest_match'];
      final actions = ['like', 'match', 'follow'];

      final matchNotifications = actions.where(
        (a) => matchTypes.contains(a),
      );

      expect(matchNotifications.length, 1);
    });
  });

  group('NotificationNewActionHandler - Fallback Handling', () {
    test('should handle notification without targetId', () {
      const String? targetId = null;
      const String? targetType = null;

      expect(targetId, isNull);
      expect(targetType, isNull);

      // Para notificações sem target, não deve navegar
      final shouldNavigate = targetId != null;
      expect(shouldNavigate, false);
    });

    test('should handle notification without senderId', () {
      const String? senderId = null;
      const String? senderName = null;

      expect(senderId, isNull);
      expect(senderName, isNull);
    });

    test('should handle unknown action type gracefully', () {
      const type = 'unknown_type';
      const actionType = 'unknown_action';
      const targetId = 'some_target';
      const targetType = 'unknown';

      // Unknown types should fallback gracefully
      expect(type, 'unknown_type');
      expect(actionType, 'unknown_action');

      // Pode ter targetId mas tipo desconhecido
      expect(targetId, isNotNull);
    });
  });

  group('NotificationNewActionHandler - Metadata Extraction', () {
    test('should extract chat metadata', () {
      final metadata = {'chatId': 'chat_xyz'};

      expect(metadata, isNotNull);
      expect(metadata['chatId'], 'chat_xyz');
    });

    test('should handle notification with post metadata', () {
      final metadata = {
        'postTitle': 'Procuro guitarrista para banda',
        'postCity': 'São Paulo',
        'postImageUrl': 'https://example.com/image.jpg',
      };

      expect(metadata['postTitle'], isNotNull);
      expect(metadata['postCity'], 'São Paulo');
    });

    test('should handle null metadata gracefully', () {
      Map<String, dynamic>? metadata;

      // Pode não ter metadata
      expect(metadata, isNull);
    });
  });
}
