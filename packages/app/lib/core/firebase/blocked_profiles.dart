import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Helper para gerenciar a lista de ProfileIds bloqueados por um perfil.
///
/// Armazenamento: `profiles/{profileId}.blockedProfileIds` (array de strings).
///
/// Observações importantes (Firestore):
/// - `whereNotIn` suporta no máximo 10 valores e não aceita lista vazia.
/// - `not-in` é um filtro de desigualdade e entra nas limitações de queries.
class BlockedProfiles {
  static const fieldName = 'blockedProfileIds';

  /// Obtém a lista de profileIds bloqueados por um perfil específico.
  static Future<List<String>> get({
    required FirebaseFirestore firestore,
    required String profileId,
  }) async {
    final id = profileId.trim();
    if (id.isEmpty) return const <String>[];

    final doc = await firestore.collection('profiles').doc(id).get();
    final data = doc.data();
    final list = (data?[fieldName] as List?)?.cast<String>() ?? const <String>[];
    return _normalize(list);
  }

  /// Observa a lista de profileIds bloqueados por um perfil específico.
  static Stream<List<String>> watch({
    required FirebaseFirestore firestore,
    required String profileId,
  }) {
    final id = profileId.trim();
    if (id.isEmpty) return Stream.value(const <String>[]);

    return firestore
        .collection('profiles')
        .doc(id)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          final list = (data?[fieldName] as List?)?.cast<String>() ??
              const <String>[];
          return _normalize(list);
        })
        .distinct(listEquals);
  }

  /// Adiciona um profileId à lista de bloqueados.
  static Future<void> add({
    required FirebaseFirestore firestore,
    required String blockerProfileId,
    required String blockedProfileId,
  }) async {
    final blocker = blockerProfileId.trim();
    final blocked = blockedProfileId.trim();
    if (blocker.isEmpty || blocked.isEmpty) return;

    await firestore.collection('profiles').doc(blocker).update({
      fieldName: FieldValue.arrayUnion([blocked]),
      'blockedUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove um profileId da lista de bloqueados.
  static Future<void> remove({
    required FirebaseFirestore firestore,
    required String blockerProfileId,
    required String blockedProfileId,
  }) async {
    final blocker = blockerProfileId.trim();
    final blocked = blockedProfileId.trim();
    if (blocker.isEmpty || blocked.isEmpty) return;

    await firestore.collection('profiles').doc(blocker).update({
      fieldName: FieldValue.arrayRemove([blocked]),
      'blockedUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Retorna lista limitada para uso em whereNotIn (máximo 10 valores).
  static List<String> forWhereNotIn(List<String> blockedProfileIds) {
    final normalized = _normalize(blockedProfileIds);
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
