import 'package:core_ui/utils/utf16_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Utf16Sanitizer', () {
    test('preserves valid surrogate pairs', () {
      const input = 'Ola 😀 musica';

      expect(Utf16Sanitizer.removeInvalidSurrogates(input), input);
    });

    test('removes unpaired high surrogates', () {
      final input = String.fromCharCodes(<int>[0x0041, 0xD83D, 0x0042]);

      expect(Utf16Sanitizer.removeInvalidSurrogates(input), 'AB');
    });

    test('removes unpaired low surrogates', () {
      final input = String.fromCharCodes(<int>[0x0041, 0xDE00, 0x0042]);

      expect(Utf16Sanitizer.removeInvalidSurrogates(input), 'AB');
    });
  });
}
