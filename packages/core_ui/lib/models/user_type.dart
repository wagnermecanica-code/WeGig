import 'package:flutter/foundation.dart';

/// Representa os tipos de perfis suportados no app.
enum UserType { band, musician }

extension UserTypeParsing on UserType {
  /// Valor em string usado pelos documentos do Firestore.
  String get firestoreValue => this == UserType.band ? 'band' : 'musician';

  bool get isBand => this == UserType.band;
  bool get isMusician => this == UserType.musician;

  static UserType fromFirestore(String? value) {
    return value == 'band' ? UserType.band : UserType.musician;
  }
}

/// Helpers estáticos sem depender de [extension] externa.
UserType userTypeFromPostType(String type) {
  return type == 'band' ? UserType.band : UserType.musician;
}

String userTypeToPostType(UserType type) {
  return describeEnum(type) == 'band' ? 'band' : 'musician';
}
