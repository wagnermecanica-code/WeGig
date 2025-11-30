import 'package:core_ui/features/messages/domain/entities/message_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/features/messages/domain/usecases/send_message.dart';

import 'mock_messages_repository.dart';

void main() {
  late SendMessage useCase;
  late MockMessagesRepository mockRepository;

  setUp(() {
    mockRepository = MockMessagesRepository();
    useCase = SendMessage(mockRepository);
  });

  group('SendMessage - Success Cases', () {
    test('should send message when all data is valid', () async {
      // given
      const conversationId = 'conv-1';
      const senderId = 'user-1';
      const senderProfileId = 'profile-1';
      const text = 'Olá, tudo bem?';

      // when
      final result = await useCase(
        conversationId: conversationId,
        senderId: senderId,
        senderProfileId: senderProfileId,
        text: text,
      );

      // then
      expect(result.text, text);
      expect(result.senderProfileId, senderProfileId);
      expect(result.senderId, senderId);
      expect(mockRepository.sendMessageCalled, true);
      expect(mockRepository.lastSendMessageText, text);
    });

    test('should send message with reply', () async {
      // given
      const conversationId = 'conv-1';
      const senderId = 'user-1';
      const senderProfileId = 'profile-1';
      const text = 'Respondendo sua mensagem';
      const replyTo = MessageReplyEntity(
        messageId: 'msg-original',
        text: 'Mensagem original',
        senderId: 'user-2',
        senderProfileId: 'profile-2',
      );

      // when
      final result = await useCase(
        conversationId: conversationId,
        senderId: senderId,
        senderProfileId: senderProfileId,
        text: text,
        replyTo: replyTo,
      );

      // then
      expect(result.text, text);
      expect(result.replyTo, isNotNull);
      expect(result.replyTo?.messageId, 'msg-original');
      expect(mockRepository.sendMessageCalled, true);
    });
  });

  group('SendMessage - Text Validation', () {
    test('should throw when text is empty', () async {
      // given
      const conversationId = 'conv-1';
      const senderId = 'user-1';
      const senderProfileId = 'profile-1';
      const text = '';

      // when & then
      expect(
        () => useCase(
          conversationId: conversationId,
          senderId: senderId,
          senderProfileId: senderProfileId,
          text: text,
        ),
        throwsA(
          predicate(
              (e) => e.toString().contains('Mensagem não pode ser vazia')),
        ),
      );
    });

    test('should throw when text is only whitespace', () async {
      // given
      const conversationId = 'conv-1';
      const senderId = 'user-1';
      const senderProfileId = 'profile-1';
      const text = '   ';

      // when & then
      expect(
        () => useCase(
          conversationId: conversationId,
          senderId: senderId,
          senderProfileId: senderProfileId,
          text: text,
        ),
        throwsA(
          predicate(
              (e) => e.toString().contains('Mensagem não pode ser vazia')),
        ),
      );
    });

    test('should throw when text exceeds 1000 characters', () async {
      // given
      const conversationId = 'conv-1';
      const senderId = 'user-1';
      const senderProfileId = 'profile-1';
      final text = 'A' * 1001;

      // when & then
      expect(
        () => useCase(
          conversationId: conversationId,
          senderId: senderId,
          senderProfileId: senderProfileId,
          text: text,
        ),
        throwsA(
          predicate((e) => e.toString().contains('no máximo 1000 caracteres')),
        ),
      );
    });

    test('should accept text with exactly 1000 characters', () async {
      // given
      const conversationId = 'conv-1';
      const senderId = 'user-1';
      const senderProfileId = 'profile-1';
      final text = 'A' * 1000;

      // when
      final result = await useCase(
        conversationId: conversationId,
        senderId: senderId,
        senderProfileId: senderProfileId,
        text: text,
      );

      // then
      expect(result.text.length, 1000);
    });
  });

  group('SendMessage - Parameter Validation', () {
    test('should throw when conversationId is empty', () async {
      // given
      const conversationId = '';
      const senderId = 'user-1';
      const senderProfileId = 'profile-1';
      const text = 'Olá';

      // when & then
      expect(
        () => useCase(
          conversationId: conversationId,
          senderId: senderId,
          senderProfileId: senderProfileId,
          text: text,
        ),
        throwsA(
          predicate(
              (e) => e.toString().contains('ID da conversa é obrigatório')),
        ),
      );
    });

    test('should throw when senderId is empty', () async {
      // given
      const conversationId = 'conv-1';
      const senderId = '';
      const senderProfileId = 'profile-1';
      const text = 'Olá';

      // when & then
      expect(
        () => useCase(
          conversationId: conversationId,
          senderId: senderId,
          senderProfileId: senderProfileId,
          text: text,
        ),
        throwsA(
          predicate(
              (e) => e.toString().contains('ID do remetente é obrigatório')),
        ),
      );
    });

    test('should throw when senderProfileId is empty', () async {
      // given
      const conversationId = 'conv-1';
      const senderId = 'user-1';
      const senderProfileId = '';
      const text = 'Olá';

      // when & then
      expect(
        () => useCase(
          conversationId: conversationId,
          senderId: senderId,
          senderProfileId: senderProfileId,
          text: text,
        ),
        throwsA(
          predicate((e) =>
              e.toString().contains('ID do perfil remetente é obrigatório')),
        ),
      );
    });
  });

  group('SendMessage - Repository Failures', () {
    test('should propagate exception when repository fails', () async {
      // given
      const conversationId = 'conv-1';
      const senderId = 'user-1';
      const senderProfileId = 'profile-1';
      const text = 'Olá';
      mockRepository
          .setupSendMessageFailure('Erro ao enviar mensagem para o Firestore');

      // when & then
      expect(
        () => useCase(
          conversationId: conversationId,
          senderId: senderId,
          senderProfileId: senderProfileId,
          text: text,
        ),
        throwsA(
          predicate((e) => e
              .toString()
              .contains('Erro ao enviar mensagem para o Firestore')),
        ),
      );
    });
  });
}
