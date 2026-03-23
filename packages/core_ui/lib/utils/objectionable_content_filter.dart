import 'dart:math';

/// Simple, offline objectionable-content filter (PT-BR focused).
///
/// Goals:
/// - Fast, deterministic, no network.
/// - Avoid obvious false-positives via word-boundary matching.
/// - Catch common obfuscations by also checking a "smashed" version
///   of the input (removing non-alphanumerics).
///
/// This is not a perfect moderation system; it's a pragmatic first-line guard.
class ObjectionableContentFilter {
  static const List<String> _badWords = <String>[
    // Profanity / sexual terms (PT-BR)
    'porra',
    'caralho',
    'cacete',
    'merda',
    'bosta',
    'foder',
    'foda',
    'fodase',
    'foda-se',
    'puta',
    'puto',
    'buceta',
    'pau',
    'pinto',
    'piranha',
    // Common insults / slurs (kept minimal; expand cautiously)
    'vadia',
    'arrombado',
    'desgraça',
    'desgraca',
    'idiota',
    'imbecil',
  ];

  /// Returns the set of matched canonical words.
  static Set<String> findMatches(String? input) {
    final text = (input ?? '').trim();
    if (text.isEmpty) return <String>{};

    final normalized = _normalize(text);
    if (normalized.isEmpty) return <String>{};

    // Word-boundary scan.
    final matches = <String>{};
    for (final word in _badWords) {
      final w = _normalize(word);
      if (w.isEmpty) continue;

      final boundary = RegExp(
        r'(^|[^\p{L}\p{N}])' + RegExp.escape(w) + r'($|[^\p{L}\p{N}])',
        caseSensitive: false,
        unicode: true,
      );
      if (boundary.hasMatch(normalized)) {
        matches.add(word);
      }
    }

    // Obfuscation scan: remove non-alphanumerics and re-check.
    // Restrict to words length >= 4 to reduce false positives.
    final smashed = _smashed(normalized);
    if (smashed.isNotEmpty) {
      for (final word in _badWords) {
        final w = _smashed(_normalize(word));
        if (w.length < 4) continue;
        if (smashed.contains(w)) {
          matches.add(word);
        }
      }
    }

    return matches;
  }

  static bool containsObjectionable(String? input) {
    return findMatches(input).isNotEmpty;
  }

  /// Returns a user-friendly message if the text is objectionable, else null.
  static String? validate(String fieldLabel, String? input) {
    final matches = findMatches(input);
    if (matches.isEmpty) return null;

    // Keep message generic (don’t echo the matched words back to the user).
    return 'O campo "$fieldLabel" contém termos ofensivos. Ajuste o texto e tente novamente.';
  }

  static String _normalize(String input) {
    var s = input.toLowerCase();

    // Basic leetspeak normalization.
    s = s
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('3', 'e')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll('7', 't');

    // Remove diacritics (limited map; enough for PT-BR).
    s = s
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c');

    // Collapse repeated whitespace.
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static String _smashed(String input) {
    // Remove anything that is not a letter/number.
    // Use unicode-aware character classes; fallback safely.
    final smashed = input.replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '');
    // Guard against pathological sizes.
    return smashed.substring(0, min(smashed.length, 5000));
  }
}
