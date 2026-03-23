import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Helper para gerenciar a lista de UIDs bloqueados do usuário.
///
/// Armazenamento: `users/{uid}.blockedUids` (array de strings).
///
/// Observações importantes (Firestore):
/// - `whereNotIn` suporta no máximo 10 valores e não aceita lista vazia.
/// - `not-in` é um filtro de desigualdade e entra nas limitações de queries.
class BlockedUids {
  static const fieldName = 'blockedUids';

  static Future<List<String>> get({
    required FirebaseFirestore firestore,
    required String uid,
  }) async {
    final doc = await firestore.collection('users').doc(uid).get();
    final data = doc.data();
    final list = (data?[fieldName] as List?)?.cast<String>() ?? const <String>[];
    return _normalize(list);
  }

  static Stream<List<String>> watch({
    required FirebaseFirestore firestore,
    required String uid,
  }) {
    return firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          final list = (data?[fieldName] as List?)?.cast<String>() ??
              const <String>[];
          return _normalize(list);
        })
        .distinct(listEquals);
  }

  static List<String> forWhereNotIn(List<String> blockedUids) {
    final normalized = _normalize(blockedUids);
    if (normalized.isEmpty) return const <String>[];
    return normalized.take(10).toList(growable: false);
  }

  static List<String> _normalize(List<String> values) {
    final unique = values
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e.trim())
        .toSet()
        .toList(growable: false);
    unique.sort();
    return unique;
  }
}
