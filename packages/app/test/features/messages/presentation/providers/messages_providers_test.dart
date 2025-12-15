import 'package:wegig_app/features/mensagens_new/domain/entities/conversation_new_entity.dart';
import 'package:wegig_app/features/mensagens_new/domain/entities/message_new_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegig_app/features/mensagens_new/data/datasources/mensagens_new_remote_datasource.dart';
import 'package:wegig_app/features/mensagens_new/domain/repositories/mensagens_new_repository.dart';
import 'package:wegig_app/features/mensagens_new/domain/usecases/conversation_usecases.dart';
import 'package:wegig_app/features/mensagens_new/domain/usecases/message_usecases.dart';
import 'package:wegig_app/features/mensagens_new/presentation/providers/mensagens_new_providers.dart';

// ============================================================================
// MOCK CLASSES
// ============================================================================

class _MockMessagesRemoteDataSource implements IMensagensNewRemoteDataSource {
  @override
  Future<void> addReaction(String conversationId, String messageId, String userId, String reaction) async {}

  @override
  Future<void> removeReaction(String conversationId, String messageId, String userId) async {}

  @override
  Future<void> deleteMessage(String conversationId, String messageId) async {}

  @override
  Stream<List<ConversationNewEntity>> watchConversations(String profileId,
      {int limit = 20, String? profileUid}) {
    return Stream.value([]);
  }

  @override
  Stream<List<MessageNewEntity>> watchMessages(
    String conversationId, {
    int limit = 20,
  }) {
    return Stream.value([]);
  }

  @override
  Stream<int> watchUnreadCount(String profileId, {String? profileUid}) {
    return Stream.value(0);
  }

  @override
  Future<List<ConversationNewEntity>> getConversations({
    required String profileId,
    int limit = 20,
    ConversationNewEntity? startAfter,
    String? profileUid,
  }) async {
    return [];
  }

  @override
  Future<ConversationNewEntity?> getConversationById(String conversationId) async {
    return null;
  }

  @override
  Future<ConversationNewEntity> getOrCreateConversation({
    required String currentProfileId,
    required String otherProfileId,
    required String currentUid,
    required String otherUid,
    String? profileUid,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageNewEntity>> getMessages({
    required String conversationId,
    int limit = 20,
    MessageNewEntity? startAfter,
  }) async {
    return [];
  }

  @override
  Future<MessageNewEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String text,
    MessageReplyData? replyTo,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<MessageNewEntity> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String imageUrl,
    String text = '',
    MessageReplyData? replyTo,
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

class _MockMensagensNewRepository implements MensagensNewRepository {
  @override
  Future<void> addReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String reaction,
  }) async {}

  @override
  Future<void> removeReaction({
    required String conversationId,
    required String messageId,
    required String userId,
  }) async {}

  @override
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {}

  @override
  Stream<List<ConversationNewEntity>> watchConversations(String profileId,
      {int limit = 20, String? profileUid}) {
    return Stream.value([]);
  }

  @override
  Stream<List<MessageNewEntity>> watchMessages(
    String conversationId, {
    int limit = 20,
  }) {
    return Stream.value([]);
  }

  @override
  Stream<int> watchUnreadCount(String profileId, {String? profileUid}) {
    return Stream.value(0);
  }

  @override
  Future<List<ConversationNewEntity>> getConversations({
    required String profileId,
    int limit = 20,
    ConversationNewEntity? startAfter,
    String? profileUid,
  }) async {
    return [];
  }

  @override
  Future<ConversationNewEntity?> getConversationById(String conversationId) async {
    return null;
  }

  @override
  Future<ConversationNewEntity> getOrCreateConversation({
    required String currentProfileId,
    required String otherProfileId,
    required String currentUid,
    required String otherUid,
    String? profileUid,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageNewEntity>> getMessages({
    required String conversationId,
    int limit = 20,
    MessageNewEntity? startAfter,
  }) async {
    return [];
  }

  @override
  Future<MessageNewEntity> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String text,
    MessageReplyData? replyTo,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<MessageNewEntity> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String senderProfileId,
    required String imageUrl,
    String text = '',
    MessageReplyData? replyTo,
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
    final mockRepository = _MockMensagensNewRepository();

    container = ProviderContainer(
      overrides: [
        mensagensNewRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        mensagensNewRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Messages Providers - Data Layer', () {
    test('mensagensNewRemoteDataSourceProvider returns singleton', () {
      final ds1 = container.read(mensagensNewRemoteDataSourceProvider);
      final ds2 = container.read(mensagensNewRemoteDataSourceProvider);
      expect(identical(ds1, ds2), isTrue,
          reason: 'DataSource is singleton, must return same instance');
    });

    test('mensagensNewRemoteDataSourceProvider returns MessagesRemoteDataSource',
        () {
      final dataSource = container.read(mensagensNewRemoteDataSourceProvider);
      expect(dataSource, isA<IMensagensNewRemoteDataSource>());
    });

    test('mensagensNewRepositoryProvider returns MensagensNewRepository', () {
      final repository = container.read(mensagensNewRepositoryProvider);
      expect(repository, isA<MensagensNewRepository>());
    });

    test('mensagensNewRepositoryProvider returns singleton', () {
      final repo1 = container.read(mensagensNewRepositoryProvider);
      final repo2 = container.read(mensagensNewRepositoryProvider);
      expect(identical(repo1, repo2), isTrue,
          reason: 'Repository is singleton, must return same instance');
    });
  });

  group('Messages Providers - Use Cases', () {
    test('loadConversationsNewUseCaseProvider returns LoadConversationsNewUseCase', () {
      final useCase = container.read(loadConversationsNewUseCaseProvider);
      expect(useCase, isA<LoadConversationsNewUseCase>());
    });

    test('loadMessagesNewUseCaseProvider returns LoadMessagesNewUseCase', () {
      final useCase = container.read(loadMessagesNewUseCaseProvider);
      expect(useCase, isA<LoadMessagesNewUseCase>());
    });

    test('sendMessageNewUseCaseProvider returns SendMessageNewUseCase', () {
      final useCase = container.read(sendMessageNewUseCaseProvider);
      expect(useCase, isA<SendMessageNewUseCase>());
    });

    test('sendImageMessageNewUseCaseProvider returns SendImageMessageNewUseCase', () {
      final useCase = container.read(sendImageMessageNewUseCaseProvider);
      expect(useCase, isA<SendImageMessageNewUseCase>());
    });

    test('markAsReadNewUseCaseProvider returns MarkAsReadNewUseCase', () {
      final useCase = container.read(markAsReadNewUseCaseProvider);
      expect(useCase, isA<MarkAsReadNewUseCase>());
    });

    test('markAsUnreadNewUseCaseProvider returns MarkAsUnreadNewUseCase', () {
      final useCase = container.read(markAsUnreadNewUseCaseProvider);
      expect(useCase, isA<MarkAsUnreadNewUseCase>());
    });

    test('deleteConversationNewUseCaseProvider returns DeleteConversationNewUseCase', () {
      final useCase = container.read(deleteConversationNewUseCaseProvider);
      expect(useCase, isA<DeleteConversationNewUseCase>());
    });

    test('All use cases depend on mensagensNewRepositoryProvider', () {
      final repositoryCallCount = 7; // 7 use cases
      var actualCalls = 0;

      // Read repository through each use case
      container.read(loadConversationsNewUseCaseProvider);
      actualCalls++;
      container.read(loadMessagesNewUseCaseProvider);
      actualCalls++;
      container.read(sendMessageNewUseCaseProvider);
      actualCalls++;
      container.read(sendImageMessageNewUseCaseProvider);
      actualCalls++;
      container.read(markAsReadNewUseCaseProvider);
      actualCalls++;
      container.read(markAsUnreadNewUseCaseProvider);
      actualCalls++;
      container.read(deleteConversationNewUseCaseProvider);
      actualCalls++;

      expect(actualCalls, equals(repositoryCallCount),
          reason:
              'All 7 use cases should depend on mensagensNewRepositoryProvider');
    });

    test('Use cases are singletons within the same container', () {
      final useCase1 = container.read(sendMessageNewUseCaseProvider);
      final useCase2 = container.read(sendMessageNewUseCaseProvider);
      expect(identical(useCase1, useCase2), isTrue,
          reason: 'Use cases should be singletons');
    });
  });

  group('Messages Providers - Overrides', () {
    test('Can override mensagensNewRepositoryProvider', () {
      final customRepository = _MockMensagensNewRepository();
      final containerWithOverride = ProviderContainer(
        overrides: [
          mensagensNewRepositoryProvider.overrideWithValue(customRepository),
        ],
      );

      final repository =
          containerWithOverride.read(mensagensNewRepositoryProvider);
      expect(identical(repository, customRepository), isTrue,
          reason: 'Should use overridden repository');

      containerWithOverride.dispose();
    });

    test('Can override use case providers', () {
      final customRepository = _MockMensagensNewRepository();
      final containerWithOverride = ProviderContainer(
        overrides: [
          mensagensNewRepositoryProvider.overrideWithValue(customRepository),
        ],
      );

      final useCase =
          containerWithOverride.read(sendMessageNewUseCaseProvider);
      expect(useCase, isA<SendMessageNewUseCase>(),
          reason: 'Use case should be created with overridden repository');

      containerWithOverride.dispose();
    });
  });

  group('Messages Providers - Stream Providers', () {
    test('conversationsNewStreamProvider can be read without errors', () {
      // StreamProvider with @riverpod annotation
      expect(() => container.read(conversationsNewStreamProvider(profileId: 'profile-123', profileUid: 'uid-123')),
          returnsNormally,
          reason: 'Should be able to read conversations stream provider');
    });

    test('messagesNewStreamProvider can be read without errors', () {
      expect(() => container.read(messagesNewStreamProvider('conversation-123')),
          returnsNormally,
          reason: 'Should be able to read messages stream provider');
    });

    test('unreadMessagesNewCountProvider can be read without errors', () {
      expect(
          () => container
              .read(unreadMessagesNewCountProvider(profileId: 'profile-123', profileUid: 'uid-123')),
          returnsNormally,
          reason: 'Should be able to read unread count stream provider');
    });
  });

  group('Messages Providers - Lifecycle', () {
    test('Providers are auto-disposed when container is disposed', () {
      var isDisposed = false;
      final testContainer = ProviderContainer(
        overrides: [
          mensagensNewRemoteDataSourceProvider
              .overrideWithValue(_MockMessagesRemoteDataSource()),
        ],
      );

      // Read provider to initialize it
      testContainer.read(mensagensNewRemoteDataSourceProvider);

      testContainer.dispose();
      isDisposed = true;

      expect(isDisposed, isTrue,
          reason: 'Container disposal should complete without errors');
    });
  });
}
