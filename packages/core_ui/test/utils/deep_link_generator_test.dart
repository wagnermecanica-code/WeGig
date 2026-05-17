import 'package:core_ui/utils/deep_link_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkGenerator', () {
    test('generateProfileLink uses the canonical profile route', () {
      final link = DeepLinkGenerator.generateProfileLink(
        userId: 'user_123',
        profileId: 'profile_456',
      );

      expect(
        link,
        equals('https://wegig.com.br/share.html?type=profile&id=profile_456'),
      );
    });

    test('profile share message keeps a raw link as the final line', () {
      final message = DeepLinkGenerator.generateProfileShareMessage(
        name: 'Banda Norte',
        isBand: true,
        city: 'Sao Paulo',
        userId: 'user_123',
        profileId: 'profile_456',
        instruments: ['Guitarra', 'Baixo', 'Bateria', 'Vocal', 'Teclado'],
        genres: ['Rock'],
      );

      expect(message, contains('Conheça Banda Norte no WeGig'));
      expect(message, contains('Guitarra, Baixo, Bateria, Vocal +1'));
      expect(message, isNot(contains('<https://')));
      expect(
        message.trim().split('\n').last,
        equals('https://wegig.com.br/share.html?type=profile&id=profile_456'),
      );
    });

    test('post share message is concise and links to post route', () {
      final longContent = List.filled(40, 'som').join(' ');
      final message = DeepLinkGenerator.generatePostShareMessage(
        postId: 'post_789',
        authorName: 'Lia',
        postType: 'musician',
        city: 'Rio de Janeiro',
        content: longContent,
        instruments: ['Voz'],
        genres: ['MPB'],
      );

      expect(message, contains('Lia está procurando banda'));
      expect(message, contains('Veja o post no WeGig:'));
      expect(message, contains('…'));
      expect(
        message.trim().split('\n').last,
        equals('https://wegig.com.br/share.html?type=post&id=post_789'),
      );
    });
  });
}
