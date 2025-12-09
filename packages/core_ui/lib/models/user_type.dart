import 'package:flutter/foundation.dart';

/// Representa os tipos de perfis suportados no app.
enum UserType { band, musician, sales }

extension UserTypeParsing on UserType {
  /// Valor em string usado pelos documentos do Firestore.
  String get firestoreValue {
    switch (this) {
      case UserType.band:
        return 'band';
      case UserType.sales:
        return 'sales';
      case UserType.musician:
        return 'musician';
    }
  }

  bool get isBand => this == UserType.band;
  bool get isMusician => this == UserType.musician;
  bool get isSales => this == UserType.sales;

  static UserType fromFirestore(String? value) {
    switch (value) {
      case 'band':
        return UserType.band;
      case 'sales':
        return UserType.sales;
      default:
        return UserType.musician;
    }
  }
}

/// Helpers estáticos sem depender de [extension] externa.
UserType userTypeFromPostType(String type) {
  switch (type) {
    case 'band':
      return UserType.band;
    case 'sales':
      return UserType.sales;
    default:
      return UserType.musician;
  }
}

String userTypeToPostType(UserType type) {
  switch (type) {
    case UserType.band:
      return 'band';
    case UserType.sales:
      return 'sales';
    case UserType.musician:
      return 'musician';
  }
}
