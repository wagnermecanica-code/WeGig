import 'package:core_ui/utils/objectionable_content_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ObjectionableContentFilter', () {
    test('returns empty for clean text', () {
      final matches = ObjectionableContentFilter.findMatches('Procuro banda de rock em SP');
      expect(matches, isEmpty);
    });

    test('detects obvious profanity', () {
      final matches = ObjectionableContentFilter.findMatches('Isso é uma porra');
      expect(matches, isNotEmpty);
    });

    test('detects spaced obfuscation', () {
      final matches = ObjectionableContentFilter.findMatches('c a r a l h o');
      expect(matches, isNotEmpty);
    });

    test('does not false-positive on substrings', () {
      // "cultura" should not match "cu".
      final matches = ObjectionableContentFilter.findMatches('cultura musical');
      expect(matches, isEmpty);
    });
  });
}
