import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'blocked_profiles.dart';

/// Helper para lidar com bloqueios em ambos os sentidos (POR PERFIL).
///
/// - Fonte de verdade (enforcement local): `profiles/{profileId}.blockedProfileIds` (quem EU bloqueei)
/// - Edge compartilhável para o bloqueado poder saber que está bloqueado (e filtrar):
///   `blocks/{blockId}` com campos { blockedByProfileId, blockedProfileId, blockedByUid, blockedUid }
///
/// Importante:
/// - Firestore rules não conseguem aplicar bloqueio em queries públicas (posts/profiles),
///   então o enforcement aqui é client-side no app.
/// - O bloqueio é por PERFIL, não por USUÁRIO. Cada perfil tem sua própria lista de bloqueados.
class BlockedRelations {
  static const collectionName = 'blocks';
  static const _blockedByProfileIdsField = 'blockedByProfileIds';

  static bool _loggedFirestoreContext = false;

  static final Map<String, List<String>> _lastBlockedByByProfileId = <String, List<String>>{};

  static void _logContext(FirebaseFirestore firestore) {
    if (!kDebugMode) return;
    if (_loggedFirestoreContext) return;
    _loggedFirestoreContext = true;

    try {
      final projectId = firestore.app.options.projectId;
      debugPrint('🧩 [BLOCKS] Firestore context: projectId=$projectId');
    } catch (e) {
      debugPrint('🧩 [BLOCKS] Firestore context: (failed to read projectId) $e');
    }
  }

  static void _logError(String label, Object error, [StackTrace? stack]) {
    if (!kDebugMode) return;

    if (error is FirebaseException) {
      debugPrint(
        '❌ [BLOCKS] $label: FirebaseException(code=${error.code}, message=${error.message})',
      );
    } else {
      debugPrint('❌ [BLOCKS] $label: $error');
    }

    if (stack != null) {
      debugPrint('   Stack: $stack');
    }
  }

  static Future<List<String>> _getBlockedByFromProfileDoc({
    required FirebaseFirestore firestore,
    required String profileId,
  }) async {
    final id = profileId.trim();
    if (id.isEmpty) return const <String>[];
    try {
      final doc = await firestore.collection('profiles').doc(id).get();
      final data = doc.data();
      final raw = data?[_blockedByProfileIdsField];
      if (raw is List) {
        final values = raw
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .cast<String>()
            .toList(growable: false);
        final normalized = _normalize(values);
        if (kDebugMode) {
          debugPrint('🧩 [BLOCKS] profileDoc blockedByProfileIds($id) -> $normalized');
        }
        return normalized;
      }
      if (kDebugMode) {
        debugPrint('🧩 [BLOCKS] profileDoc blockedByProfileIds($id) -> [] (missing/empty)');
      }
      return const <String>[];
    } catch (e, st) {
      _logError('profileDoc blockedByProfileIds read failed (non-critical)', e, st);
      return const <String>[];
    }
  }

  static Stream<List<String>> _watchBlockedByFromProfileDoc({
    required FirebaseFirestore firestore,
    required String profileId,
  }) {
    final id = profileId.trim();
    if (id.isEmpty) return Stream.value(const <String>[]);

    return firestore
        .collection('profiles')
        .doc(id)
        .snapshots()
        .map((snap) {
          final data = snap.data();
          final raw = data?[_blockedByProfileIdsField];
          if (raw is List) {
            final values = raw
                .map((e) => e?.toString().trim() ?? '')
                .where((e) => e.isNotEmpty)
                .cast<String>()
                .toList(growable: false);
            return _normalize(values);
          }
          return const <String>[];
        })
        .doOnData((v) {
          if (kDebugMode) {
            debugPrint('🧩 [BLOCKS] watch profileDoc blockedByProfileIds($id) -> $v');
          }
        })
        .doOnError((e, st) => _logError('watch profileDoc blockedByProfileIds error', e, st))
        .onErrorReturn(const <String>[])
        .distinct(listEquals);
  }

  // Best-effort self-healing: garante que todo profileId em `profiles/{profileId}.blockedProfileIds`
  // tenha o edge compartilhado correspondente em `blocks/{blockerProfileId_blockedProfileId}`.
  // Isso é essencial para reverse visibility (o bloqueado conseguir saber que foi bloqueado).
  static final Map<String, Set<String>> _syncedEdgesByBlockerProfileId = <String, Set<String>>{};

  // Guard para evitar race condition: múltiplas chamadas concorrentes aguardam
  // a mesma operação de escrita ao invés de cada uma disparar sua própria.
  static final Map<String, Completer<void>> _selfHealInFlight = <String, Completer<void>>{};

  static Future<void> _ensureEdgesForBlockedProfiles({
    required FirebaseFirestore firestore,
    required String blockedByProfileId,
    String? blockedByUid,
    required List<String> blockedProfileIds,
  }) async {
    _logContext(firestore);
    final by = blockedByProfileId.trim();
    if (by.isEmpty) return;

    final normalized = _normalize(blockedProfileIds);
    if (normalized.isEmpty) {
      _syncedEdgesByBlockerProfileId[by] = <String>{};
      return;
    }

    final already = _syncedEdgesByBlockerProfileId[by] ?? <String>{};
    final missing = normalized.where((p) => !already.contains(p)).toList(growable: false);
    if (missing.isEmpty) return;

    // Se já existe uma operação em andamento para este profileId, aguarda ela.
    final existing = _selfHealInFlight[by];
    if (existing != null && !existing.isCompleted) {
      await existing.future;
      return;
    }
    final completer = Completer<void>();
    _selfHealInFlight[by] = completer;

    // Sem blockedByUid, o edge pode se tornar ilegível para o próprio bloqueador
    // (dependendo das rules/legados), gerando ruído de permission-denied.
    // Como esse self-heal é best-effort, preferimos não escrever nesses casos.
    final trimmedBlockedByUid = blockedByUid?.trim() ?? '';
    if (trimmedBlockedByUid.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '🧩 [BLOCKS] _ensureEdgesForBlockedProfiles: skipped (missing blockedByUid) blockerProfileId=$by missingEdges=${missing.length}/${normalized.length}',
        );
      }
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '🧩 [BLOCKS] _ensureEdgesForBlockedProfiles: blockerProfileId=$by blockedByUid=$trimmedBlockedByUid missingEdges=${missing.length}/${normalized.length}',
      );
    }

    try {
      // CRÍTICO: Resolver UIDs dos perfis bloqueados para garantir que
      // as Security Rules permitam reverse visibility.
      final profileUids = <String, String>{};
      final profileIdsToResolve = missing.take(450).toList(growable: false);
      
      // Batch read para resolver UIDs (máximo 10 por vez para whereIn)
      for (var i = 0; i < profileIdsToResolve.length; i += 10) {
        final chunk = profileIdsToResolve.skip(i).take(10).toList();
        try {
          final snap = await firestore
              .collection('profiles')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          for (final doc in snap.docs) {
            final uid = (doc.data()['uid'] as String?)?.trim();
            if (uid != null && uid.isNotEmpty) {
              profileUids[doc.id] = uid;
            }
          }
        } catch (e) {
          debugPrint('⚠️ BlockedRelations: Falha ao resolver UIDs chunk (non-critical): $e');
        }
      }

      final batch = firestore.batch();
      for (final to in profileIdsToResolve) {
        final ref = _docRef(firestore: firestore, blockedByProfileId: by, blockedProfileId: to);
        final resolvedUid = profileUids[to];
        batch.set(
          ref,
          {
            'blockedByProfileId': by,
            'blockedProfileId': to,
            'blockedByUid': trimmedBlockedByUid,
            if (resolvedUid != null && resolvedUid.isNotEmpty)
              'blockedUid': resolvedUid,
            'blockedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();

      final updated = <String>{...already, ...missing};
      _syncedEdgesByBlockerProfileId[by] = updated;
      debugPrint('✅ BlockedRelations: Self-heal criou ${missing.length} edges com UIDs resolvidos');
      completer.complete();
    } catch (e, st) {
      _logError('Edge self-heal failed (non-critical)', e, st);
      completer.complete(); // Não propaga erro — é best-effort
    } finally {
      _selfHealInFlight.remove(by);
    }
  }

  /// Gera o ID do documento de bloqueio no formato: blockerProfileId_blockedProfileId
  static String docId({required String blockedByProfileId, required String blockedProfileId}) {
    final a = blockedByProfileId.trim();
    final b = blockedProfileId.trim();
    return '${a}_$b';
  }

  static DocumentReference<Map<String, dynamic>> _docRef({
    required FirebaseFirestore firestore,
    required String blockedByProfileId,
    required String blockedProfileId,
  }) {
    return firestore.collection(collectionName).doc(docId(blockedByProfileId: blockedByProfileId, blockedProfileId: blockedProfileId));
  }

  /// Cria um edge de bloqueio na coleção `blocks`.
  /// 
  /// [blockedByProfileId] - ProfileId de quem está bloqueando
  /// [blockedProfileId] - ProfileId de quem está sendo bloqueado
  /// [blockedByUid] - UID opcional do bloqueador (para Cloud Functions verificarem)
  /// [blockedUid] - UID opcional do bloqueado (para Cloud Functions verificarem e Security Rules)
  /// 
  /// IMPORTANTE: Se blockedUid não for fornecido, tentará resolver automaticamente
  /// consultando profiles/{blockedProfileId}.uid. Isso é CRÍTICO para que as
  /// Security Rules permitam que o perfil bloqueado consulte quem o bloqueou.
  static Future<void> create({
    required FirebaseFirestore firestore,
    required String blockedByProfileId,
    required String blockedProfileId,
    String? blockedByUid,
    String? blockedUid,
    Timestamp? blockedAt,
  }) async {
    _logContext(firestore);
    final by = blockedByProfileId.trim();
    final to = blockedProfileId.trim();
    if (by.isEmpty || to.isEmpty) {
      debugPrint('⚠️ BlockedRelations.create: profileId vazio (by=$by, to=$to)');
      return;
    }

    // CRÍTICO: Resolver blockedUid se não fornecido
    // Sem este campo, as Security Rules podem impedir que o bloqueado
    // consulte a coleção blocks (reverse visibility falha).
    String? resolvedBlockedUid = blockedUid?.trim();
    if (resolvedBlockedUid == null || resolvedBlockedUid.isEmpty) {
      try {
        final profileDoc = await firestore.collection('profiles').doc(to).get();
        final profileData = profileDoc.data();
        resolvedBlockedUid = (profileData?['uid'] as String?)?.trim();
        debugPrint('🧩 [BLOCKS] create: resolved blockedUid=$resolvedBlockedUid for blockedProfileId=$to');
      } catch (e, st) {
        _logError('create: failed to resolve blockedUid (non-critical)', e, st);
      }
    }

    final data = <String, dynamic>{
      'blockedByProfileId': by,
      'blockedProfileId': to,
      'blockedAt': blockedAt ?? FieldValue.serverTimestamp(),
    };
    
    if (blockedByUid != null && blockedByUid.trim().isNotEmpty) {
      data['blockedByUid'] = blockedByUid.trim();
    }
    if (resolvedBlockedUid != null && resolvedBlockedUid.isNotEmpty) {
      data['blockedUid'] = resolvedBlockedUid;
    }

    debugPrint(
      '🧩 [BLOCKS] create: writing edgeId=${docId(blockedByProfileId: by, blockedProfileId: to)} by=$by to=$to blockedByUid=${blockedByUid?.trim()} blockedUid=${resolvedBlockedUid ?? ""}',
    );

    try {
      await _docRef(firestore: firestore, blockedByProfileId: by, blockedProfileId: to).set(
        data,
        SetOptions(merge: true),
      );
      debugPrint('✅ [BLOCKS] create: edge write success');
    } catch (e, st) {
      _logError('create: edge write failed', e, st);
      rethrow;
    }
  }

  /// Remove um edge de bloqueio da coleção `blocks`.
  static Future<void> delete({
    required FirebaseFirestore firestore,
    required String blockedByProfileId,
    required String blockedProfileId,
  }) async {
    _logContext(firestore);
    final by = blockedByProfileId.trim();
    final to = blockedProfileId.trim();
    if (by.isEmpty || to.isEmpty) return;
    final edgeId = docId(blockedByProfileId: by, blockedProfileId: to);
    debugPrint('🧩 [BLOCKS] delete: edgeId=$edgeId by=$by to=$to');
    try {
      await _docRef(firestore: firestore, blockedByProfileId: by, blockedProfileId: to).delete();
      debugPrint('✅ [BLOCKS] delete: edge delete success');
    } catch (e, st) {
      _logError('delete: edge delete failed', e, st);
      rethrow;
    }
  }

  /// ProfileIds que bloquearam o perfil atual (blockedBy).
  static Future<List<String>> getBlockedByProfileIds({
    required FirebaseFirestore firestore,
    required String profileId,
    String? uid,
  }) async {
    _logContext(firestore);
    final currentProfileId = profileId.trim();
    if (currentProfileId.isEmpty) {
      debugPrint('⚠️ BlockedRelations.getBlockedByProfileIds: profileId vazio');
      return const <String>[];
    }

    debugPrint(
      '🧩 [BLOCKS] getBlockedByProfileIds: blockedProfileId==$currentProfileId uid=${uid?.trim()}',
    );

    // IMPORTANT:
    // Não consultamos a coleção `blocks` aqui.
    // Em runtime, leituras/listens em `blocks` podem falhar com permission-denied;
    // para evitar inconsistências e ruído de logs, usamos somente o índice reverso
    // server-maintained `profiles/{profileId}.blockedByProfileIds`.
    final fromProfileDoc = await _getBlockedByFromProfileDoc(
      firestore: firestore,
      profileId: currentProfileId,
    );
    debugPrint(
      '🔍 BlockedRelations.getBlockedByProfileIds: Resultado final (profileDoc) = $fromProfileDoc',
    );
    return fromProfileDoc;
  }

  /// Stream de profileIds que bloquearam o perfil atual.
  static Stream<List<String>> watchBlockedByProfileIds({
    required FirebaseFirestore firestore,
    required String profileId,
    String? uid,
  }) {
    _logContext(firestore);
    final currentProfileId = profileId.trim();
    if (currentProfileId.isEmpty) return Stream.value(const <String>[]);

    debugPrint(
      '🧩 [BLOCKS] watchBlockedByProfileIds: start blockedProfileId==$currentProfileId uid=${uid?.trim()}',
    );
    final byProfileDoc$ = _watchBlockedByFromProfileDoc(
      firestore: firestore,
      profileId: currentProfileId,
    );

    // IMPORTANT:
    // Não fazemos listen em `blocks` aqui.
    // Em runtime, esse listen frequentemente falha com permission-denied e o fallback
    // por cache (lastKnown) pode reintroduzir bloqueios antigos (falso positivo),
    // quebrando UX (ex.: tentar iniciar conversa com perfil já desbloqueado).
    // Para stream contínuo, usamos o índice reverso server-maintained
    // `profiles/{profileId}.blockedByProfileIds`, que é a fonte confiável.
    return byProfileDoc$;
  }

  /// União de:
  /// - quem EU bloqueei (`profiles/{profileId}.blockedProfileIds`)
  /// - quem ME bloqueou (`profiles/{profileId}.blockedByProfileIds`)
  /// 
  /// Retorna lista de profileIds que devem ser excluídos/filtrados.
  static Future<List<String>> getExcludedProfileIds({
    required FirebaseFirestore firestore,
    required String profileId,
    String? uid,
  }) async {
    _logContext(firestore);
    final currentProfileId = profileId.trim();
    if (currentProfileId.isEmpty) {
      debugPrint('⚠️ BlockedRelations.getExcludedProfileIds: profileId vazio');
      return const <String>[];
    }

    debugPrint('🔍 BlockedRelations.getExcludedProfileIds: Calculando exclusões para profileId=$currentProfileId');

    final blocked = await BlockedProfiles.get(firestore: firestore, profileId: currentProfileId);
    debugPrint('   📋 Bloqueados por mim (blocked): $blocked');

    // Best-effort: garante que edges existam para reverse visibility.
    await _ensureEdgesForBlockedProfiles(
      firestore: firestore,
      blockedByProfileId: currentProfileId,
      blockedByUid: uid,
      blockedProfileIds: blocked,
    );

    List<String> blockedBy = const <String>[];
    try {
      blockedBy = await getBlockedByProfileIds(
        firestore: firestore,
        profileId: currentProfileId,
        uid: uid,
      );
      debugPrint('   📋 Quem me bloqueou (blockedBy): $blockedBy');
    } catch (e) {
      debugPrint('⚠️ BlockedRelations: Falha ao carregar blockedByProfileIds (non-critical): $e');
    }

    final result = _normalize([...blocked, ...blockedBy]);
    debugPrint('🔍 BlockedRelations.getExcludedProfileIds: Resultado final (blocked ∪ blockedBy) = $result');
    return result;
  }

  // Cache de streams compartilhados por profileId.
  // Evita criar múltiplos snapshot listeners para o mesmo perfil.
  // Usa BehaviorSubject via shareReplay para que novos subscribers
  // recebam o último valor emitido imediatamente.
  static final Map<String, Stream<List<String>>> _sharedExcludedStreams = <String, Stream<List<String>>>{};

  /// Limpa o cache de streams compartilhados.
  /// Chamar ao trocar de perfil ativo para forçar re-criação dos listeners.
  static void clearStreamCache() {
    _sharedExcludedStreams.clear();
  }

  /// Stream de profileIds excluídos (bloqueados + quem me bloqueou).
  static Stream<List<String>> watchExcludedProfileIds({
    required FirebaseFirestore firestore,
    required String profileId,
    String? uid,
  }) {
    _logContext(firestore);
    final currentProfileId = profileId.trim();
    if (currentProfileId.isEmpty) return Stream.value(const <String>[]);

    // Retorna stream compartilhado se já existir para este profileId.
    final cached = _sharedExcludedStreams[currentProfileId];
    if (cached != null) return cached;

    debugPrint('🔍 BlockedRelations.watchExcludedProfileIds: Criando stream compartilhado para profileId=$currentProfileId');

    final blocked$ = BlockedProfiles.watch(firestore: firestore, profileId: currentProfileId)
        .doOnData((blocked) {
          debugPrint('   📋 watchExcludedProfileIds.blocked\$: $blocked');
          // Best-effort side-effect: mantém edges sincronizados sem depender
          // de chamadas explícitas em todos os fluxos de bloqueio.
          _ensureEdgesForBlockedProfiles(
            firestore: firestore,
            blockedByProfileId: currentProfileId,
            blockedByUid: uid,
            blockedProfileIds: blocked,
          );
        })
        .doOnError((e, st) => _logError('watchExcludedProfileIds: blockedProfiles stream error', e, st))
        .onErrorReturn(const <String>[]);
    final blockedBy$ = watchBlockedByProfileIds(
      firestore: firestore,
      profileId: currentProfileId,
      uid: uid,
    )
        .doOnData((blockedBy) {
          debugPrint('   📋 watchExcludedProfileIds.blockedBy\$: $blockedBy');
        })
        .doOnError((e, st) => _logError('watchExcludedProfileIds: blockedBy stream error', e, st))
        .onErrorReturn(const <String>[]);

    final shared = Rx.combineLatest2<List<String>, List<String>, List<String>>(
      blocked$,
      blockedBy$,
      (a, b) {
        final result = _normalize([...a, ...b]);
        debugPrint('🔍 BlockedRelations.watchExcludedProfileIds: Combinado (blocked=$a + blockedBy=$b) = $result');
        return result;
      },
    ).distinct(listEquals).shareReplay(maxSize: 1);

    _sharedExcludedStreams[currentProfileId] = shared;
    return shared;
  }

  /// Retorna lista limitada para uso em whereNotIn (máximo 10 valores).
  static List<String> forWhereNotIn(List<String> profileIds) {
    final normalized = _normalize(profileIds);
    if (normalized.isEmpty) return const <String>[];
    return normalized.take(10).toList(growable: false);
  }

  /// Repara edges existentes que não têm blockedUid preenchido.
  /// 
  /// Esta função deve ser chamada uma vez para corrigir bloqueios antigos
  /// que foram criados sem o campo blockedUid.
  /// 
  /// Retorna o número de edges reparados.
  static Future<int> repairMissingBlockedUids({
    required FirebaseFirestore firestore,
    List<String>? limitToProfileIds,
  }) async {
    _logContext(firestore);
    debugPrint('🔧 BlockedRelations.repairMissingBlockedUids: Iniciando reparo...');
    
    try {
      final normalizedLimit = limitToProfileIds == null
          ? const <String>[]
          : _normalize(limitToProfileIds);

      // Buscar edges (idealmente apenas os relevantes para o usuário atual).
      // IMPORTANTE: evitamos varrer a coleção inteira em produção.
      final edgesById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      if (normalizedLimit.isEmpty) {
        debugPrint('🧩 [BLOCKS] repairMissingBlockedUids: normalizedLimit EMPTY -> would scan entire collection; aborting for safety');
        return 0;
      } else {
        // Como o app permite até 5 perfis por usuário, dá pra usar whereIn.
        // Fazemos 2 queries (blockedProfileId e blockedByProfileId) e unimos.
        for (var i = 0; i < normalizedLimit.length; i += 10) {
          final chunk = normalizedLimit.skip(i).take(10).toList(growable: false);

          try {
            final blockedSnap = await firestore
                .collection(collectionName)
                .where('blockedProfileId', whereIn: chunk)
                .get();
            debugPrint('🧩 [BLOCKS] repairMissingBlockedUids: query blockedProfileId in $chunk -> ${blockedSnap.docs.length} docs');
            for (final doc in blockedSnap.docs) {
              edgesById[doc.id] = doc;
            }
          } catch (e, st) {
            _logError('repairMissingBlockedUids: query blockedProfileId whereIn failed', e, st);
          }

          try {
            final blockedBySnap = await firestore
                .collection(collectionName)
                .where('blockedByProfileId', whereIn: chunk)
                .get();
            debugPrint('🧩 [BLOCKS] repairMissingBlockedUids: query blockedByProfileId in $chunk -> ${blockedBySnap.docs.length} docs');
            for (final doc in blockedBySnap.docs) {
              edgesById[doc.id] = doc;
            }
          } catch (e, st) {
            _logError('repairMissingBlockedUids: query blockedByProfileId whereIn failed', e, st);
          }
        }
      }

      final edgesToRepair = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final doc in edgesById.values) {
        final data = doc.data();
        final blockedUid = (data['blockedUid'] as String?)?.trim();
        if (blockedUid == null || blockedUid.isEmpty) {
          edgesToRepair.add(doc);
        }
      }
      
      if (edgesToRepair.isEmpty) {
        debugPrint('✅ BlockedRelations.repairMissingBlockedUids: Nenhum edge para reparar');
        return 0;
      }
      
      debugPrint('🔧 BlockedRelations.repairMissingBlockedUids: ${edgesToRepair.length} edges para reparar');
      
      // Coletar profileIds únicos que precisam ser resolvidos
      final profileIdsToResolve = edgesToRepair
          .map((d) => (d.data()['blockedProfileId'] as String?)?.trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList(growable: false);
      
      // Resolver UIDs em batches
      final profileUids = <String, String>{};
      for (var i = 0; i < profileIdsToResolve.length; i += 10) {
        final chunk = profileIdsToResolve.skip(i).take(10).toList();
        try {
          final profileSnap = await firestore
              .collection('profiles')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          for (final doc in profileSnap.docs) {
            final uid = (doc.data()['uid'] as String?)?.trim();
            if (uid != null && uid.isNotEmpty) {
              profileUids[doc.id] = uid;
            }
          }
        } catch (e) {
          debugPrint('⚠️ BlockedRelations.repairMissingBlockedUids: Falha ao resolver chunk: $e');
        }
      }
      
      // Atualizar edges em batches (máximo 500 por batch)
      var repaired = 0;
      for (var i = 0; i < edgesToRepair.length; i += 500) {
        final batch = firestore.batch();
        final chunk = edgesToRepair.skip(i).take(500);
        
        for (final doc in chunk) {
          final blockedProfileId = (doc.data()['blockedProfileId'] as String?)?.trim() ?? '';
          final resolvedUid = profileUids[blockedProfileId];
          
          if (resolvedUid != null && resolvedUid.isNotEmpty) {
            batch.update(doc.reference, {'blockedUid': resolvedUid});
            repaired++;
          }
        }
        
        try {
          await batch.commit();
        } catch (e, st) {
          _logError('repairMissingBlockedUids: batch.commit failed', e, st);
          rethrow;
        }
      }
      
      debugPrint('✅ BlockedRelations.repairMissingBlockedUids: $repaired edges reparados');
      return repaired;
    } catch (e, st) {
      _logError('repairMissingBlockedUids: failed', e, st);
      return 0;
    }
  }

  /// Garante que cada perfil do usuário tenha edges na coleção `blocks`
  /// correspondentes a sua lista `blockedProfileIds`.
  /// Útil para backfill de bloqueios antigos criados antes do edge compartilhado.
  static Future<int> syncEdgesForBlockedLists({
    required FirebaseFirestore firestore,
    required List<String> blockerProfileIds,
    String? blockerUid,
  }) async {
    var createdOrUpdated = 0;

    for (final profileId in blockerProfileIds) {
      final blocked = await BlockedProfiles.get(
        firestore: firestore,
        profileId: profileId,
      );
      if (blocked.isEmpty) continue;

      final before = _syncedEdgesByBlockerProfileId[profileId]?.length ?? 0;
      await _ensureEdgesForBlockedProfiles(
        firestore: firestore,
        blockedByProfileId: profileId,
        blockedByUid: blockerUid,
        blockedProfileIds: blocked,
      );
      final after = _syncedEdgesByBlockerProfileId[profileId]?.length ?? before;
      createdOrUpdated += (after - before).clamp(0, blocked.length);
    }

    return createdOrUpdated;
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
