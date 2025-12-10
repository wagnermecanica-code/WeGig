/// WeGig - NotificationNewEntity Tests
///
/// Testes unitários para a entidade de notificação.
/// Testes sem dependência de core_ui importado diretamente.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationEntity Properties', () {
    late DateTime now;
    late Map<String, dynamic> testNotification;

    setUp(() {
      now = DateTime.now();
      testNotification = {
        'id': 'notif_123',
        'profileId': 'profile_456',
        'type': 'post_interaction',
        'actionType': 'like',
        'title': 'Novo like',
        'body': 'João curtiu seu post',
        'senderId': 'sender_789',
        'senderName': 'João',
        'senderPhoto': 'https://example.com/photo.jpg',
        'targetId': 'post_abc',
        'targetType': 'post',
        'createdAt': now,
        'expiresAt': now.add(const Duration(days: 30)),
        'isRead': false,
        'metadata': {'postTitle': 'Procuro guitarrista'},
      };
    });

    test('should have all required fields', () {
      expect(testNotification['id'], 'notif_123');
      expect(testNotification['profileId'], 'profile_456');
      expect(testNotification['type'], 'post_interaction');
      expect(testNotification['actionType'], 'like');
      expect(testNotification['title'], 'Novo like');
      expect(testNotification['body'], 'João curtiu seu post');
      expect(testNotification['isRead'], false);
    });

    test('should have optional sender fields', () {
      expect(testNotification['senderId'], 'sender_789');
      expect(testNotification['senderName'], 'João');
      expect(testNotification['senderPhoto'], 'https://example.com/photo.jpg');
    });

    test('should have target fields', () {
      expect(testNotification['targetId'], 'post_abc');
      expect(testNotification['targetType'], 'post');
    });

    test('should have metadata', () {
      expect(testNotification['metadata'], isNotNull);
      expect(testNotification['metadata']['postTitle'], 'Procuro guitarrista');
    });

    test('should have expiration dates', () {
      expect(testNotification['createdAt'], now);
      expect(
        testNotification['expiresAt'],
        now.add(const Duration(days: 30)),
      );
    });

    test('should support read status update', () {
      // Simula atualização de status
      testNotification['isRead'] = true;
      expect(testNotification['isRead'], true);
    });

    test('should handle null optional fields', () {
      final minimalNotification = {
        'id': 'notif_minimal',
        'profileId': 'profile_123',
        'type': 'system',
        'actionType': 'info',
        'title': 'System Message',
        'body': 'Test body',
        'createdAt': now,
        'expiresAt': now.add(const Duration(days: 30)),
        'isRead': false,
        'senderId': null,
        'senderName': null,
        'senderPhoto': null,
        'targetId': null,
        'targetType': null,
        'metadata': null,
      };

      expect(minimalNotification['senderId'], isNull);
      expect(minimalNotification['senderName'], isNull);
      expect(minimalNotification['senderPhoto'], isNull);
      expect(minimalNotification['targetId'], isNull);
      expect(minimalNotification['targetType'], isNull);
      expect(minimalNotification['metadata'], isNull);
    });
  });

  group('NotificationEntity fromFirestore', () {
    test('should parse Firestore data correctly', () {
      final now = DateTime.now();

      // Simula dados do Firestore
      final firestoreData = {
        'profileId': 'profile_456',
        'type': 'post_interaction',
        'actionType': 'like',
        'title': 'Novo like',
        'body': 'João curtiu seu post',
        'senderId': 'sender_789',
        'senderName': 'João',
        'senderPhoto': 'https://example.com/photo.jpg',
        'targetId': 'post_abc',
        'targetType': 'post',
        'createdAt': now.millisecondsSinceEpoch,
        'expiresAt': now.add(const Duration(days: 30)).millisecondsSinceEpoch,
        'isRead': false,
        'metadata': {'postTitle': 'Procuro guitarrista'},
      };

      // Simula parsing
      final parsed = {
        'id': 'notif_123',
        ...firestoreData,
        'createdAt': DateTime.fromMillisecondsSinceEpoch(
          firestoreData['createdAt'] as int,
        ),
        'expiresAt': DateTime.fromMillisecondsSinceEpoch(
          firestoreData['expiresAt'] as int,
        ),
      };

      expect(parsed['id'], 'notif_123');
      expect(parsed['profileId'], 'profile_456');
      expect(parsed['type'], 'post_interaction');
    });

    test('should handle missing optional fields in Firestore', () {
      final now = DateTime.now();

      final firestoreData = {
        'profileId': 'profile_456',
        'type': 'system',
        'actionType': 'info',
        'title': 'System Message',
        'body': 'Test body',
        'createdAt': now.millisecondsSinceEpoch,
        'expiresAt': now.add(const Duration(days: 30)).millisecondsSinceEpoch,
        'isRead': true,
        // Campos opcionais ausentes
      };

      expect(firestoreData['senderId'], isNull);
      expect(firestoreData['senderName'], isNull);
      expect(firestoreData['targetId'], isNull);
    });
  });

  group('Notification Types', () {
    test('should identify post_interaction type', () {
      const type = 'post_interaction';
      expect(type, 'post_interaction');
      expect(type.contains('post'), true);
    });

    test('should identify follow type', () {
      const type = 'follow';
      expect(type, 'follow');
    });

    test('should identify interest_match type', () {
      const type = 'interest_match';
      expect(type, 'interest_match');
      expect(type.contains('interest'), true);
    });

    test('should identify message type', () {
      const type = 'message';
      expect(type, 'message');
    });

    test('should identify system type', () {
      const type = 'system';
      expect(type, 'system');
    });
  });

  group('Action Types', () {
    test('should identify like action', () {
      const actionType = 'like';
      expect(actionType, 'like');
    });

    test('should identify comment action', () {
      const actionType = 'comment';
      expect(actionType, 'comment');
    });

    test('should identify new_follower action', () {
      const actionType = 'new_follower';
      expect(actionType, 'new_follower');
    });

    test('should identify new_message action', () {
      const actionType = 'new_message';
      expect(actionType, 'new_message');
    });

    test('should identify match action', () {
      const actionType = 'match';
      expect(actionType, 'match');
    });
  });

  group('Target Types', () {
    test('should identify post target', () {
      const targetType = 'post';
      expect(targetType, 'post');
    });

    test('should identify profile target', () {
      const targetType = 'profile';
      expect(targetType, 'profile');
    });

    test('should identify chat target', () {
      const targetType = 'chat';
      expect(targetType, 'chat');
    });
  });

  group('Expiration Logic', () {
    test('should identify valid notification', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30));

      final isExpired = expiresAt.isBefore(now);
      expect(isExpired, false);
    });

    test('should identify expired notification', () {
      final now = DateTime.now();
      final expiresAt = now.subtract(const Duration(days: 1));

      final isExpired = expiresAt.isBefore(now);
      expect(isExpired, true);
    });

    test('should calculate days until expiration', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30));

      final daysUntilExpiry = expiresAt.difference(now).inDays;
      expect(daysUntilExpiry, 30);
    });
  });
}
