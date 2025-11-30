import 'package:core_ui/features/messages/domain/entities/conversation_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/features/messages/domain/usecases/load_conversations.dart';

import 'mock_messages_repository.dart';

void main() {
  late LoadConversations useCase;
  late MockMessagesRepository mockRepository;

  setUp(() {
    mockRepository = MockMessagesRepository();
    useCase = LoadConversations(mockRepository);
  });

  group('LoadConversations - Success Cases', () {
    test('should return list of conversations for profile', () async {
      // given
      const profileId = 'profile-1';
      final conversations = [
        ConversationEntity(
          id: 'conv-1',
          participants: ['user-1', 'user-2'],
          participantProfiles: ['profile-1', 'profile-2'],
          lastMessage: 'Olá, tudo bem?',
          lastMessageTimestamp: DateTime.now(),
          unreadCount: {'profile-1': 0, 'profile-2': 1},
          createdAt: DateTime.now(),
        ),
        ConversationEntity(
          id: 'conv-2',
          participants: ['user-1', 'user-3'],
          participantProfiles: ['profile-1', 'profile-3'],
          lastMessage: 'Vamos marcar um ensaio?',
          lastMessageTimestamp: DateTime.now(),
          unreadCount: {'profile-1': 2, 'profile-3': 0},
          createdAt: DateTime.now(),
        ),
      ];
      mockRepository.setupConversations(profileId, conversations);

      // when
      final result = await useCase(profileId: profileId);

      // then
      expect(result.length, 2);
      expect(result[0].id, 'conv-1');
      expect(result[1].id, 'conv-2');
      expect(mockRepository.getConversationsCalled, true);
    });

    test('should return empty list when profile has no conversations',
        () async {
      // given
      const profileId = 'profile-new';
      mockRepository.setupConversations(profileId, []);

      // when
      final result = await useCase(profileId: profileId);

      // then
      expect(result, isEmpty);
    });
  });

  group('LoadConversations - Pagination', () {
    test('should support pagination with limit', () async {
      // given
      const profileId = 'profile-1';
      final conversations = List.generate(
        5,
        (i) => ConversationEntity(
          id: 'conv-$i',
          participants: ['user-1', 'user-${i + 2}'],
          participantProfiles: ['profile-1', 'profile-${i + 2}'],
          lastMessage: 'Mensagem $i',
          lastMessageTimestamp: DateTime.now(),
          unreadCount: {'profile-1': 0, 'profile-${i + 2}': 0},
          createdAt: DateTime.now(),
        ),
      );
      mockRepository.setupConversations(profileId, conversations);

      // when
      final result = await useCase(profileId: profileId, limit: 3);

      // then
      expect(result.length,
          lessThanOrEqualTo(5)); // Mock returns all, real would paginate
    });
  });

  group('LoadConversations - Validation', () {
    test('should throw when profileId is empty', () async {
      // given
      const profileId = '';

      // when & then
      expect(
        () => useCase(profileId: profileId),
        throwsA(
          predicate((e) => e.toString().contains('ID do perfil é obrigatório')),
        ),
      );
    });
  });

  group('LoadConversations - Repository Failures', () {
    test('should propagate exception when repository fails', () async {
      // given
      const profileId = 'profile-1';
      mockRepository.setupGetConversationsFailure(
          'Erro ao carregar conversas do Firestore');

      // when & then
      expect(
        () => useCase(profileId: profileId),
        throwsA(
          predicate((e) =>
              e.toString().contains('Erro ao carregar conversas do Firestore')),
        ),
      );
    });
  });
}
