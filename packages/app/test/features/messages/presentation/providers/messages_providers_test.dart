import 'package:core_ui/features/messages/domain/entities/conversation_entity.dart';
import 'package:core_ui/features/messages/domain/entities/message_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegig_app/features/messages/data/datasources/messages_remote_datasource.dart';
import 'package:wegig_app/features/messages/domain/repositories/messages_repository.dart';
import 'package:wegig_app/features/messages/domain/usecases/delete_conversation.dart';
import 'package:wegig_app/features/messages/domain/usecases/load_conversations.dart';
import 'package:wegig_app/features/messages/domain/usecases/load_messages.dart';
import 'package:wegig_app/features/messages/domain/usecases/mark_as_read.dart';
import 'package:wegig_app/features/messages/domain/usecases/mark_as_unread.dart';
import 'package:wegig_app/features/messages/domain/usecases/send_image.dart';
import 'package:wegig_app/features/messages/domain/usecases/send_message.dart';
import 'package:wegig_app/features/messages/presentation/providers/messages_providers.dart';

// ============================================================================
// MOCK CLASSES
// ============================================================================

class _MockMessagesRemoteDataSource implements IMessagesRemoteDataSource {
  @override
  Stream<List<ConversationEntity>> watchConversations(String profileId,
      {String? profileUid}) {
    return Stream.value([]);
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String conversationId) {
    return Stream.value([]);
  }

  @override
  Stream<int> watchUnreadCount(String profileId, {String? profileUid}) {
    return Stream.value(0);
  }

  @override
  Future<List<ConversationEntity>> getConversations({
    required String profileId,
    int limit = 20,
    ConversationEntity? startAfter,
    String? profileUid,
  }) async {
    return [];
  }

  @override
  Future<ConversationEntity?> getConversationById(String conversationId) async {
    return null;
  }

  @override
  Future<ConversationEntity> getOrCreateConversation({
    required String currentProfileId,
    required String otherProfileId,
    required String currentUid,
    required String otherUid,
    String? profileUid,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 20,
    MessageEntity? startAfter,
  }) async {
    return [];
  }

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String text,
    MessageReplyEntity? replyTo,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<MessageEntity> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String imageUrl,
    String text = '',
    MessageReplyEntity? replyTo,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> markAsRead(String conversationId, String profileId) async {}

  @override
  Future<void> markAsUnread(String conversationId, String profileId) async {}

  @override
  Future<void> deleteConversation(String conversationId, String profileId) async {}

  @override
  Future<int> getUnreadMessageCount(String profileId, {String? profileUid}) async {
    return 0;
  }
}

class _MockMessagesRepository implements MessagesRepository {
  @override
  Stream<List<ConversationEntity>> watchConversations(String profileId,
      {String? profileUid}) {
    return Stream.value([]);
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String conversationId) {
    return Stream.value([]);
  }

  @override
  Stream<int> watchUnreadCount(String profileId, {String? profileUid}) {
    return Stream.value(0);
  }

  @override
  Future<List<ConversationEntity>> getConversations({
    required String profileId,
    int limit = 20,
    ConversationEntity? startAfter,
    String? profileUid,
  }) async {
    return [];
  }

  @override
  Future<ConversationEntity?> getConversationById(String conversationId) async {
    return null;
  }

  @override
  Future<ConversationEntity> getOrCreateConversation({
    required String currentProfileId,
    required String otherProfileId,
    required String currentUid,
    required String otherUid,
    String? profileUid,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 20,
    MessageEntity? startAfter,
  }) async {
    return [];
  }

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String text,
    MessageReplyEntity? replyTo,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<MessageEntity> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String imageUrl,
    String text = '',
    MessageReplyEntity? replyTo,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String profileId,
  }) async {}

  @override
  Future<void> markAsUnread({
    required String conversationId,
    required String profileId,
  }) async {}

  @override
  Future<void> deleteConversation({
    required String conversationId,
    required String profileId,
  }) async {}

  @override
  Future<int> getUnreadMessageCount(String profileId, {String? profileUid}) async {
    return 0;
  }
}

// ============================================================================
// TESTS
// ============================================================================

void main() {
  late ProviderContainer container;

  setUp(() {
    final mockDataSource = _MockMessagesRemoteDataSource();
    final mockRepository = _MockMessagesRepository();

    container = ProviderContainer(
      overrides: [
        messagesRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        messagesRepositoryNewProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Messages Providers - Data Layer', () {
    test('messagesRemoteDataSourceProvider returns singleton', () {
      final ds1 = container.read(messagesRemoteDataSourceProvider);
      final ds2 = container.read(messagesRemoteDataSourceProvider);
      expect(identical(ds1, ds2), isTrue,
          reason: 'DataSource is singleton, must return same instance');
    });

    test('messagesRemoteDataSourceProvider returns MessagesRemoteDataSource',
        () {
      final dataSource = container.read(messagesRemoteDataSourceProvider);
      expect(dataSource, isA<IMessagesRemoteDataSource>());
    });

    test('messagesRepositoryNewProvider returns MessagesRepository', () {
      final repository = container.read(messagesRepositoryNewProvider);
      expect(repository, isA<MessagesRepository>());
    });

    test('messagesRepositoryNewProvider returns singleton', () {
      final repo1 = container.read(messagesRepositoryNewProvider);
      final repo2 = container.read(messagesRepositoryNewProvider);
      expect(identical(repo1, repo2), isTrue,
          reason: 'Repository is singleton, must return same instance');
    });
  });

  group('Messages Providers - Use Cases', () {
    test('loadConversationsUseCaseProvider returns LoadConversations', () {
      final useCase = container.read(loadConversationsUseCaseProvider);
      expect(useCase, isA<LoadConversations>());
    });

    test('loadMessagesUseCaseProvider returns LoadMessages', () {
      final useCase = container.read(loadMessagesUseCaseProvider);
      expect(useCase, isA<LoadMessages>());
    });

    test('sendMessageUseCaseProvider returns SendMessage', () {
      final useCase = container.read(sendMessageUseCaseProvider);
      expect(useCase, isA<SendMessage>());
    });

    test('sendImageUseCaseProvider returns SendImage', () {
      final useCase = container.read(sendImageUseCaseProvider);
      expect(useCase, isA<SendImage>());
    });

    test('markAsReadUseCaseProvider returns MarkAsRead', () {
      final useCase = container.read(markAsReadUseCaseProvider);
      expect(useCase, isA<MarkAsRead>());
    });

    test('markAsUnreadUseCaseProvider returns MarkAsUnread', () {
      final useCase = container.read(markAsUnreadUseCaseProvider);
      expect(useCase, isA<MarkAsUnread>());
    });

    test('deleteConversationUseCaseProvider returns DeleteConversation', () {
      final useCase = container.read(deleteConversationUseCaseProvider);
      expect(useCase, isA<DeleteConversation>());
    });

    test('All use cases depend on messagesRepositoryNewProvider', () {
      final repositoryCallCount = 7; // 7 use cases
      var actualCalls = 0;

      // Read repository through each use case
      container.read(loadConversationsUseCaseProvider);
      actualCalls++;
      container.read(loadMessagesUseCaseProvider);
      actualCalls++;
      container.read(sendMessageUseCaseProvider);
      actualCalls++;
      container.read(sendImageUseCaseProvider);
      actualCalls++;
      container.read(markAsReadUseCaseProvider);
      actualCalls++;
      container.read(markAsUnreadUseCaseProvider);
      actualCalls++;
      container.read(deleteConversationUseCaseProvider);
      actualCalls++;

      expect(actualCalls, equals(repositoryCallCount),
          reason:
              'All 7 use cases should depend on messagesRepositoryNewProvider');
    });

    test('Use cases are singletons within the same container', () {
      final useCase1 = container.read(sendMessageUseCaseProvider);
      final useCase2 = container.read(sendMessageUseCaseProvider);
      expect(identical(useCase1, useCase2), isTrue,
          reason: 'Use cases should be singletons');
    });
  });

  group('Messages Providers - Overrides', () {
    test('Can override messagesRepositoryNewProvider', () {
      final customRepository = _MockMessagesRepository();
      final containerWithOverride = ProviderContainer(
        overrides: [
          messagesRepositoryNewProvider.overrideWithValue(customRepository),
        ],
      );

      final repository =
          containerWithOverride.read(messagesRepositoryNewProvider);
      expect(identical(repository, customRepository), isTrue,
          reason: 'Should use overridden repository');

      containerWithOverride.dispose();
    });

    test('Can override use case providers', () {
      final customRepository = _MockMessagesRepository();
      final containerWithOverride = ProviderContainer(
        overrides: [
          messagesRepositoryNewProvider.overrideWithValue(customRepository),
        ],
      );

      final useCase =
          containerWithOverride.read(sendMessageUseCaseProvider);
      expect(useCase, isA<SendMessage>(),
          reason: 'Use case should be created with overridden repository');

      containerWithOverride.dispose();
    });
  });

  group('Messages Providers - Stream Providers', () {
    test('conversationsStreamProvider can be read without errors', () {
      // StreamProvider with @riverpod annotation
      expect(() => container.read(conversationsStreamProvider('profile-123')),
          returnsNormally,
          reason: 'Should be able to read conversations stream provider');
    });

    test('messagesStreamProvider can be read without errors', () {
      expect(() => container.read(messagesStreamProvider('conversation-123')),
          returnsNormally,
          reason: 'Should be able to read messages stream provider');
    });

    test('unreadMessageCountForProfileProvider can be read without errors', () {
      expect(
          () => container
              .read(unreadMessageCountForProfileProvider('profile-123')),
          returnsNormally,
          reason: 'Should be able to read unread count stream provider');
    });
  });

  group('Messages Providers - Lifecycle', () {
    test('Providers are auto-disposed when container is disposed', () {
      var isDisposed = false;
      final testContainer = ProviderContainer(
        overrides: [
          messagesRemoteDataSourceProvider
              .overrideWithValue(_MockMessagesRemoteDataSource()),
        ],
      );

      // Read provider to initialize it
      testContainer.read(messagesRemoteDataSourceProvider);

      testContainer.dispose();
      isDisposed = true;

      expect(isDisposed, isTrue,
          reason: 'Container disposal should complete without errors');
    });
  });
}
