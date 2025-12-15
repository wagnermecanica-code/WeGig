import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/features/mensagens_new/domain/entities/entities.dart';

void main() {
  group('MessageNewEntity', () {
    final now = DateTime.now();

    test('should create a text message correctly', () {
      final message = MessageNewEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderProfileId: 'profile-1',
        text: 'Hello, World!',
        type: MessageType.text,
        createdAt: now,
        status: MessageDeliveryStatus.sent,
      );

      expect(message.id, 'msg-1');
      expect(message.text, 'Hello, World!');
      expect(message.type, MessageType.text);
      expect(message.status, MessageDeliveryStatus.sent);
      expect(message.hasText, true);
      expect(message.hasImage, false);
      expect(message.isDeletedForEveryone, false);
    });

    test('should create an image message correctly', () {
      final message = MessageNewEntity(
        id: 'msg-2',
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderProfileId: 'profile-1',
        text: '',
        imageUrl: 'https://example.com/image.jpg',
        type: MessageType.image,
        createdAt: now,
        status: MessageDeliveryStatus.delivered,
      );

      expect(message.imageUrl, 'https://example.com/image.jpg');
      expect(message.hasImage, true);
      expect(message.hasText, false);
      expect(message.status, MessageDeliveryStatus.delivered);
      expect(message.preview, '📷 Foto');
    });

    test('should correctly identify deleted message', () {
      final message = MessageNewEntity(
        id: 'msg-3',
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderProfileId: 'profile-1',
        text: 'Deleted message',
        type: MessageType.deleted,
        createdAt: now,
        deletedForEveryone: true,
        status: MessageDeliveryStatus.read,
      );

      expect(message.isDeletedForEveryone, true);
      expect(message.preview, '🚫 Mensagem apagada');
    });

    test('should identify deleted for specific profile', () {
      final message = MessageNewEntity(
        id: 'msg-4',
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderProfileId: 'profile-1',
        text: 'Test',
        type: MessageType.text,
        createdAt: now,
        status: MessageDeliveryStatus.read,
        deletedForProfiles: const ['profile-2', 'profile-3'],
      );

      expect(message.isDeletedForProfile('profile-2'), true);
      expect(message.isDeletedForProfile('profile-1'), false);
    });

    test('should store reactions correctly', () {
      final message = MessageNewEntity(
        id: 'msg-5',
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderProfileId: 'profile-1',
        text: 'Test',
        type: MessageType.text,
        createdAt: now,
        status: MessageDeliveryStatus.read,
        reactions: const {'profile-1': '👍', 'profile-2': '❤️'},
      );

      expect(message.reactions['profile-1'], '👍');
      expect(message.reactions['profile-2'], '❤️');
      expect(message.reactions['profile-3'], null);
      expect(message.hasReactions, true);
    });

    test('should identify system message', () {
      final message = MessageNewEntity(
        id: 'msg-6',
        conversationId: 'conv-1',
        senderId: 'system',
        senderProfileId: 'system',
        text: 'User joined',
        type: MessageType.system,
        createdAt: now,
        status: MessageDeliveryStatus.sent,
      );

      expect(message.isSystemMessage, true);
    });

    test('should check if message is mine', () {
      final message = MessageNewEntity(
        id: 'msg-7',
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderProfileId: 'profile-1',
        text: 'Test',
        type: MessageType.text,
        createdAt: now,
        status: MessageDeliveryStatus.sent,
      );

      expect(message.isMine('profile-1'), true);
      expect(message.isMine('profile-2'), false);
    });

    test('should identify reply message', () {
      final message = MessageNewEntity(
        id: 'msg-8',
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderProfileId: 'profile-1',
        text: 'This is a reply',
        type: MessageType.text,
        createdAt: now,
        status: MessageDeliveryStatus.sent,
        replyTo: const MessageReplyData(
          messageId: 'msg-7',
          text: 'Original message',
          senderProfileId: 'profile-2',
          senderName: 'John',
        ),
      );

      expect(message.isReply, true);
      expect(message.replyTo?.messageId, 'msg-7');
      expect(message.replyTo?.text, 'Original message');
    });

    test('should truncate long preview', () {
      final message = MessageNewEntity(
        id: 'msg-9',
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderProfileId: 'profile-1',
        text: 'This is a very long message that should be truncated in the preview to keep it short and readable',
        type: MessageType.text,
        createdAt: now,
        status: MessageDeliveryStatus.sent,
      );

      expect(message.preview.length, lessThanOrEqualTo(53)); // 50 + "..."
      expect(message.preview.endsWith('...'), true);
    });
  });

  group('ConversationNewEntity', () {
    final now = DateTime.now();

    test('should create a conversation correctly', () {
      final conversation = ConversationNewEntity(
        id: 'conv-1',
        participants: const ['uid-1', 'uid-2'],
        participantProfiles: const ['profile-1', 'profile-2'],
        lastMessage: 'Hello!',
        lastMessageTimestamp: now,
        lastMessageSenderId: 'profile-1',
        unreadCount: const {'profile-2': 1},
        createdAt: now,
      );

      expect(conversation.id, 'conv-1');
      expect(conversation.participants.length, 2);
      expect(conversation.lastMessage, 'Hello!');
    });

    test('should get unread count for profile', () {
      final conversation = ConversationNewEntity(
        id: 'conv-1',
        participants: const ['uid-1', 'uid-2'],
        participantProfiles: const ['profile-1', 'profile-2'],
        lastMessage: '',
        lastMessageTimestamp: now,
        unreadCount: const {'profile-1': 3, 'profile-2': 0},
        createdAt: now,
      );

      expect(conversation.getUnreadCountForProfile('profile-1'), 3);
      expect(conversation.getUnreadCountForProfile('profile-2'), 0);
      expect(conversation.getUnreadCountForProfile('profile-3'), 0);
    });

    test('should check has unread messages', () {
      final conversation = ConversationNewEntity(
        id: 'conv-1',
        participants: const ['uid-1', 'uid-2'],
        participantProfiles: const ['profile-1', 'profile-2'],
        lastMessage: '',
        lastMessageTimestamp: now,
        unreadCount: const {'profile-1': 3, 'profile-2': 0},
        createdAt: now,
      );

      expect(conversation.hasUnreadMessages('profile-1'), true);
      expect(conversation.hasUnreadMessages('profile-2'), false);
    });

    test('should get other profile id', () {
      final conversation = ConversationNewEntity(
        id: 'conv-1',
        participants: const ['uid-1', 'uid-2'],
        participantProfiles: const ['profile-1', 'profile-2'],
        lastMessage: '',
        lastMessageTimestamp: now,
        unreadCount: const {},
        createdAt: now,
      );

      expect(conversation.getOtherProfileId('profile-1'), 'profile-2');
      expect(conversation.getOtherProfileId('profile-2'), 'profile-1');
    });

    test('should get other uid', () {
      final conversation = ConversationNewEntity(
        id: 'conv-1',
        participants: const ['uid-1', 'uid-2'],
        participantProfiles: const ['profile-1', 'profile-2'],
        lastMessage: '',
        lastMessageTimestamp: now,
        unreadCount: const {},
        createdAt: now,
      );

      expect(conversation.getOtherUid('uid-1'), 'uid-2');
      expect(conversation.getOtherUid('uid-2'), 'uid-1');
    });

    test('should check if archived for profile', () {
      final conversation = ConversationNewEntity(
        id: 'conv-1',
        participants: const ['uid-1', 'uid-2'],
        participantProfiles: const ['profile-1', 'profile-2'],
        lastMessage: '',
        lastMessageTimestamp: now,
        unreadCount: const {},
        createdAt: now,
        archivedByProfiles: const ['profile-1'],
      );

      expect(conversation.isArchivedForProfile('profile-1'), true);
      expect(conversation.isArchivedForProfile('profile-2'), false);
    });

    test('should check if muted for profile', () {
      final conversation = ConversationNewEntity(
        id: 'conv-1',
        participants: const ['uid-1', 'uid-2'],
        participantProfiles: const ['profile-1', 'profile-2'],
        lastMessage: '',
        lastMessageTimestamp: now,
        unreadCount: const {},
        createdAt: now,
        mutedByProfiles: const ['profile-1'],
      );

      expect(conversation.isMutedForProfile('profile-1'), true);
      expect(conversation.isMutedForProfile('profile-2'), false);
    });

    test('should check if pinned for profile', () {
      final conversation = ConversationNewEntity(
        id: 'conv-1',
        participants: const ['uid-1', 'uid-2'],
        participantProfiles: const ['profile-1', 'profile-2'],
        lastMessage: '',
        lastMessageTimestamp: now,
        unreadCount: const {},
        createdAt: now,
        pinnedByProfiles: const ['profile-1'],
      );

      expect(conversation.isPinnedForProfile('profile-1'), true);
      expect(conversation.isPinnedForProfile('profile-2'), false);
    });

    test('should get other participant data', () {
      final conversation = ConversationNewEntity(
        id: 'conv-1',
        participants: const ['uid-1', 'uid-2'],
        participantProfiles: const ['profile-1', 'profile-2'],
        lastMessage: '',
        lastMessageTimestamp: now,
        unreadCount: const {},
        createdAt: now,
        participantsData: const [
          ParticipantData(
            profileId: 'profile-1',
            uid: 'uid-1',
            name: 'User 1',
          ),
          ParticipantData(
            profileId: 'profile-2',
            uid: 'uid-2',
            name: 'User 2',
            photoUrl: 'https://example.com/photo.jpg',
          ),
        ],
      );

      final other = conversation.getOtherParticipantData('profile-1');
      expect(other?.profileId, 'profile-2');
      expect(other?.name, 'User 2');
      expect(other?.photoUrl, 'https://example.com/photo.jpg');
    });
  });

  group('MessageDeliveryStatus', () {
    test('should have correct values', () {
      expect(MessageDeliveryStatus.values.length, 5);
      expect(MessageDeliveryStatus.sending.name, 'sending');
      expect(MessageDeliveryStatus.sent.name, 'sent');
      expect(MessageDeliveryStatus.delivered.name, 'delivered');
      expect(MessageDeliveryStatus.read.name, 'read');
      expect(MessageDeliveryStatus.failed.name, 'failed');
    });
  });

  group('MessageType', () {
    test('should have correct values', () {
      expect(MessageType.values.length, 4);
      expect(MessageType.text.name, 'text');
      expect(MessageType.image.name, 'image');
      expect(MessageType.system.name, 'system');
      expect(MessageType.deleted.name, 'deleted');
    });
  });

  group('ParticipantData', () {
    test('should create participant data correctly', () {
      const participant = ParticipantData(
        profileId: 'profile-1',
        uid: 'uid-1',
        name: 'John Doe',
        photoUrl: 'https://example.com/photo.jpg',
      );

      expect(participant.profileId, 'profile-1');
      expect(participant.uid, 'uid-1');
      expect(participant.name, 'John Doe');
      expect(participant.photoUrl, 'https://example.com/photo.jpg');
    });

    test('should work without optional photoUrl', () {
      const participant = ParticipantData(
        profileId: 'profile-1',
        uid: 'uid-1',
        name: 'John Doe',
      );

      expect(participant.photoUrl, isNull);
    });
  });

  group('MessageReplyData', () {
    test('should create reply data correctly', () {
      const reply = MessageReplyData(
        messageId: 'msg-1',
        text: 'Original message',
        senderProfileId: 'profile-1',
        senderName: 'John',
        imageUrl: 'https://example.com/image.jpg',
      );

      expect(reply.messageId, 'msg-1');
      expect(reply.text, 'Original message');
      expect(reply.senderProfileId, 'profile-1');
      expect(reply.senderName, 'John');
      expect(reply.imageUrl, 'https://example.com/image.jpg');
    });

    test('should work with minimal data', () {
      const reply = MessageReplyData(
        messageId: 'msg-1',
        text: 'Message',
        senderProfileId: 'profile-1',
        senderName: 'User',
      );

      expect(reply.imageUrl, isNull);
    });
  });
}
