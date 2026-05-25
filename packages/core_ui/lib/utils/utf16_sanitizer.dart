/// Utilities for making user-provided text safe for Flutter text layout.
class Utf16Sanitizer {
  const Utf16Sanitizer._();

  /// Removes unpaired UTF-16 surrogate code units while preserving valid emoji
  /// and other supplementary-plane characters.
  static String removeInvalidSurrogates(String input) {
    if (input.isEmpty) return input;

    final outputCodePoints = <int>[];
    final units = input.codeUnits;

    for (var index = 0; index < units.length; index++) {
      final unit = units[index];

      if (_isHighSurrogate(unit)) {
        if (index + 1 < units.length && _isLowSurrogate(units[index + 1])) {
          outputCodePoints.add(_decodeSurrogatePair(unit, units[index + 1]));
          index++;
        }
        continue;
      }

      if (_isLowSurrogate(unit)) {
        continue;
      }

      outputCodePoints.add(unit);
    }

    if (outputCodePoints.length == units.length) return input;
    return String.fromCharCodes(outputCodePoints);
  }

  static String? removeInvalidSurrogatesOrNull(String? input) {
    if (input == null) return null;
    return removeInvalidSurrogates(input);
  }

  static List<String>? removeInvalidSurrogatesFromList(List<String>? input) {
    if (input == null) return null;
    return input.map(removeInvalidSurrogates).toList(growable: false);
  }

  static bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

  static bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;

  static int _decodeSurrogatePair(int high, int low) {
    return 0x10000 + ((high - 0xD800) << 10) + (low - 0xDC00);
  }
}
