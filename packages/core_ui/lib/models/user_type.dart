/// Representa os tipos de perfis suportados no app.
/// Inclui `sales` e `hiring` para colorir posts que não são perfis.
enum UserType { band, musician, sales, hiring }

extension UserTypeParsing on UserType {
  /// Valor em string usado pelos documentos do Firestore.
  String get firestoreValue {
    switch (this) {
      case UserType.band:
        return 'band';
      case UserType.sales:
        return 'sales';
      case UserType.hiring:
        return 'hiring';
      case UserType.musician:
        return 'musician';
    }
  }

  bool get isBand => this == UserType.band;
  bool get isMusician => this == UserType.musician;
  bool get isSales => this == UserType.sales;
  bool get isHiring => this == UserType.hiring;

  static UserType fromFirestore(String? value) {
    switch (value) {
      case 'band':
        return UserType.band;
      case 'sales':
        return UserType.sales;
      case 'hiring':
        return UserType.hiring;
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
    case 'hiring':
      return UserType.hiring;
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
    case UserType.hiring:
      return 'hiring';
    case UserType.musician:
      return 'musician';
  }
}
