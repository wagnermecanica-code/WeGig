import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/utils/geo_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';

import '../../domain/entities/entities.dart';

abstract class IConnectionsRemoteDataSource {
  Future<ConnectionRequestEntity> sendConnectionRequest({
    required String requesterProfileId,
    required String requesterUid,
    required String requesterName,
    String? requesterPhotoUrl,
    required String recipientProfileId,
    required String recipientUid,
    required String recipientName,
    String? recipientPhotoUrl,
  });

  Future<void> acceptConnectionRequest({
    required String requestId,
    required String responderProfileId,
  });

  Future<void> declineConnectionRequest({
    required String requestId,
    required String responderProfileId,
  });

  Future<void> cancelConnectionRequest({
    required String requestId,
    required String requesterProfileId,
  });

  Future<void> removeConnection({
    required String connectionId,
    required String currentProfileId,
  });

  Stream<List<ConnectionEntity>> watchConnections({
    required String profileId,
    required String profileUid,
    int limit,
  });

  Future<ConnectionPageEntity> loadConnectionsPage({
    required String profileId,
    required String profileUid,
    String? startAfterConnectionId,
    int limit,
  });

  Stream<List<ConnectionRequestEntity>> watchPendingReceivedRequests({
    required String profileId,
    required String profileUid,
    int limit,
  });

  Stream<List<ConnectionRequestEntity>> watchPendingSentRequests({
    required String profileId,
    required String profileUid,
    int limit,
  });

  Stream<ConnectionStatsEntity> watchConnectionStats({
    required String profileId,
  });

  Stream<List<PostEntity>> watchNetworkActivity({
    required String profileId,
    required String profileUid,
    int limit,
  });

  Future<NetworkActivityPageEntity> loadNetworkActivityPage({
    required String profileId,
    required String profileUid,
    NetworkActivityCursorEntity? startAfter,
    int limit,
  });

  Future<List<CommonConnectionEntity>> loadCommonConnections({
    required String profileId,
    required String profileUid,
    required String otherProfileId,
    required String otherProfileUid,
    int limit,
  });

  Future<List<ConnectionSuggestionEntity>> loadConnectionSuggestions({
    required String profileId,
    required String profileUid,
    required String currentCity,
    required String currentProfileType,
    required String? currentLevel,
    required List<String> currentInstruments,
    required List<String> currentGenres,
    int limit,
    List<String> filterProfileTypes,
    List<String> filterInstruments,
    List<String> filterGenres,
    bool filterSameCity,
    bool filterWithCommonConnections,
  });

  Future<ConnectionStatusEntity> getConnectionStatus({
    required String profileId,
    required String profileUid,
    required String otherProfileId,
  });
}

class _SuggestionScoreBreakdown {
  const _SuggestionScoreBreakdown({
    required this.baseScore,
    required this.postAffinityScore,
  });

  final int baseScore;
  final int postAffinityScore;

  bool get hasPostAffinity => postAffinityScore > 0;

  bool get isEligible => baseScore > 0 || hasPostAffinity;

  int compareTo(_SuggestionScoreBreakdown other) {
    if (hasPostAffinity != other.hasPostAffinity) {
      return hasPostAffinity ? 1 : -1;
    }

    final postScoreCompare =
        postAffinityScore.compareTo(other.postAffinityScore);
    if (postScoreCompare != 0) {
      return postScoreCompare;
    }

    return baseScore.compareTo(other.baseScore);
  }

  int totalScore({required int commonConnectionsCount}) {
    final commonConnectionsScore = commonConnectionsCount * 30;
    if (hasPostAffinity) {
      return 1000 +
          (postAffinityScore * 4) +
          baseScore +
          commonConnectionsScore;
    }

    return baseScore + commonConnectionsScore;
  }
}

class _CachedAvailableProfile {
  const _CachedAvailableProfile({
    required this.fetchedAt,
    required this.profile,
  });

  final DateTime fetchedAt;
  final ProfileEntity? profile;
}

class ConnectionsRemoteDataSource implements IConnectionsRemoteDataSource {
  ConnectionsRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int _connectionsPageFetchMultiplier = 3;
  static const int _networkActivityPageFetchMultiplier = 3;
  static const Duration _requestCooldown = Duration(days: 7);
  static const Duration _suggestionsCacheTtl = Duration(hours: 6);
  static const Duration _availableProfileCacheTtl = Duration(minutes: 5);
  static const int _suggestionsCacheVersion = 4;
  static const int _suggestionsEvaluationBuffer = 12;
  static const int _suggestionsCommonConnectionsFloor = 18;
  static const int _suggestionsCandidatePoolFloor = 120;
  static const int _dailyRequestLimit = 15;
  static const int _requestAttemptsBeforeCooldown = 5;
  static const Duration _postSendServerRecheckDelay = Duration(seconds: 4);

  final FirebaseFirestore _firestore;
  final Map<String, _CachedAvailableProfile> _availableProfileCache =
      <String, _CachedAvailableProfile>{};

  CollectionReference<Map<String, dynamic>> get _requestsRef =>
      _firestore.collection('connectionRequests');

  CollectionReference<Map<String, dynamic>> get _connectionsRef =>
      _firestore.collection('connections');

  CollectionReference<Map<String, dynamic>> get _statsRef =>
      _firestore.collection('connectionStats');

  CollectionReference<Map<String, dynamic>> get _suggestionsRef =>
      _firestore.collection('connectionSuggestions');

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid?.trim();

  @override
  Future<ConnectionRequestEntity> sendConnectionRequest({
    required String requesterProfileId,
    required String requesterUid,
    required String requesterName,
    String? requesterPhotoUrl,
    required String recipientProfileId,
    required String recipientUid,
    required String recipientName,
    String? recipientPhotoUrl,
  }) async {
    debugPrint(
      '🤝 ConnectionsDS.send: start requester=$requesterProfileId/$requesterUid '
      'recipient=$recipientProfileId/$recipientUid',
    );

    if (requesterProfileId == recipientProfileId) {
      throw StateError('Nao e permitido conectar um perfil com ele mesmo.');
    }

    // Cross-check auth.uid vs requester uid passed from UI.
    // Em alguns cenários de troca de perfil/sessão, o activeProfile pode
    // carregar um uid stale. Tentamos auto-corrigir sem perder segurança.
    final authUid = _currentUid;
    if (authUid == null || authUid.isEmpty) {
      throw StateError('Nao autenticado. Faca login novamente.');
    }

    var effectiveRequesterUid = requesterUid.trim();
    if (authUid != effectiveRequesterUid) {
      debugPrint(
        '⚠️ ConnectionsDS.send: uid mismatch authUid=$authUid requesterUid=$requesterUid — tentando autocorrecao',
      );

      final requesterProfileSnapshot =
          await _firestore.collection('profiles').doc(requesterProfileId).get();
      final requesterProfileUid =
          (requesterProfileSnapshot.data()?['uid'] as String? ?? '').trim();

      if (requesterProfileUid == authUid) {
        // Perfil pertence ao usuário autenticado; corrige uid stale local.
        effectiveRequesterUid = authUid;
        debugPrint(
          '✅ ConnectionsDS.send: uid autocorrigido para authUid no requesterProfileId=$requesterProfileId',
        );
      } else {
        debugPrint(
          '❌ ConnectionsDS.send: requester profile ownership mismatch profileUid=$requesterProfileUid authUid=$authUid',
        );
        throw StateError(
          'Sua sessao esta inconsistente. Saia e entre novamente para continuar.',
        );
      }
    }

    final requesterProfile = await _requireAvailableProfile(
      profileId: requesterProfileId,
      unavailableMessage: 'Seu perfil nao esta disponivel para conexoes agora.',
    );
    final recipientProfile = await _requireAvailableProfile(
      profileId: recipientProfileId,
      unavailableMessage:
          'Este perfil nao esta disponivel para conexoes agora.',
    );

    final effectiveRequesterName = requesterProfile.name.trim().isNotEmpty
        ? requesterProfile.name
        : requesterName.trim();
    final effectiveRequesterPhotoUrl =
        requesterProfile.photoUrl ?? requesterPhotoUrl;
    final effectiveRecipientUid = recipientProfile.uid.trim();
    final effectiveRecipientName = recipientProfile.name.trim().isNotEmpty
        ? recipientProfile.name
        : recipientName.trim();
    final effectiveRecipientPhotoUrl =
        recipientProfile.photoUrl ?? recipientPhotoUrl;

    if (effectiveRecipientUid != recipientUid.trim()) {
      debugPrint(
        '⚠️ ConnectionsDS.send: recipientUid stale payload=$recipientUid canonical=$effectiveRecipientUid',
      );
    }

    await _enforceRequestRateLimit(
      requesterProfileId: requesterProfileId,
      requesterUid: effectiveRequesterUid,
    );

    await _assertProfilesNotBlocked(
      profileId: requesterProfileId,
      otherProfileId: recipientProfileId,
      uid: effectiveRequesterUid,
    );

    await _assertRecipientAllowsConnectionRequests(
      recipientProfileId: recipientProfileId,
    );

    final requestId = _requestDocId(requesterProfileId, recipientProfileId);
    final inverseRequestId =
        _requestDocId(recipientProfileId, requesterProfileId);
    final connectionId =
        _connectionDocId(requesterProfileId, recipientProfileId);
    final requestRef = _requestsRef.doc(requestId);
    final inverseRequestRef = _requestsRef.doc(inverseRequestId);
    final connectionRef = _connectionsRef.doc(connectionId);

    try {
      await _firestore.runTransaction((transaction) async {
        final connectionSnapshot = await transaction.get(connectionRef);
        if (connectionSnapshot.exists) {
          throw StateError('Esses perfis ja estao conectados.');
        }

        final requestSnapshot = await transaction.get(requestRef);
        final inverseRequestSnapshot = await transaction.get(inverseRequestRef);

        // Self-heal: se existe um request terminal (accepted/declined/cancelled)
        // mas NAO existe connections/ doc, consideramos histórico órfão e
        // descartamos para permitir novo envio sem cooldown.
        final hasConnection = connectionSnapshot.exists;
        final directIsOrphanTerminal = _isOrphanTerminalRequest(
          snapshot: requestSnapshot,
          connectionExists: hasConnection,
        );
        final inverseIsOrphanTerminal = _isOrphanTerminalRequest(
          snapshot: inverseRequestSnapshot,
          connectionExists: hasConnection,
        );

        if (requestSnapshot.exists && !directIsOrphanTerminal) {
          final existingStatus = connectionRequestStatusFromString(
            requestSnapshot.data()?['status'] as String? ?? '',
          );
          if (existingStatus == ConnectionRequestStatus.pending) {
            throw StateError('Ja existe um convite pendente para esse perfil.');
          }

          _assertCooldownSatisfied(
            data: requestSnapshot.data(),
            requesterProfileId: requesterProfileId,
            recipientProfileId: recipientProfileId,
          );
        }

        if (inverseRequestSnapshot.exists && !inverseIsOrphanTerminal) {
          final inverseStatus = connectionRequestStatusFromString(
            inverseRequestSnapshot.data()?['status'] as String? ?? '',
          );
          if (inverseStatus == ConnectionRequestStatus.pending) {
            throw StateError('Ja existe um convite recebido desse perfil.');
          }

          _assertCooldownSatisfied(
            data: inverseRequestSnapshot.data(),
            requesterProfileId: requesterProfileId,
            recipientProfileId: recipientProfileId,
          );
        }

        final pairRequestHistory = _mergeRequestHistory(
          primaryData: directIsOrphanTerminal ? null : requestSnapshot.data(),
          secondaryData:
              inverseIsOrphanTerminal ? null : inverseRequestSnapshot.data(),
        );

        _assertCooldownSatisfied(
          data: pairRequestHistory,
          requesterProfileId: requesterProfileId,
          recipientProfileId: recipientProfileId,
        );

        // Limpa registros órfãos no mesmo commit atômico.
        if (directIsOrphanTerminal) {
          transaction.delete(requestRef);
        }
        if (inverseIsOrphanTerminal) {
          transaction.delete(inverseRequestRef);
        }

        transaction.set(requestRef, {
          'requesterProfileId': requesterProfileId,
          'requesterUid': effectiveRequesterUid,
          'requesterName': effectiveRequesterName,
          'requesterPhotoUrl': effectiveRequesterPhotoUrl,
          'recipientProfileId': recipientProfileId,
          'recipientUid': effectiveRecipientUid,
          'recipientName': effectiveRecipientName,
          'recipientPhotoUrl': effectiveRecipientPhotoUrl,
          'status': ConnectionRequestStatus.pending.name,
          'requestAttemptCount': _nextRequestAttemptCount(
            currentData: pairRequestHistory,
          ),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'respondedAt': null,
        });

        _applyStatsDelta(
          transaction,
          profileId: requesterProfileId,
          pendingSentDelta: 1,
        );
        _applyStatsDelta(
          transaction,
          profileId: recipientProfileId,
          pendingReceivedDelta: 1,
        );
      });
    } catch (error, stackTrace) {
      debugPrint(
          '❌ ConnectionsDS.send: transaction FAILED ${error.runtimeType}: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }

    // Verificação pós-commit a partir do SERVIDOR (evita ler cache local
    // stale em caso de falha silenciosa de transação).
    final snapshot = await requestRef.get(
      const GetOptions(source: Source.server),
    );
    if (!snapshot.exists) {
      debugPrint(
        '❌ ConnectionsDS.send: post-commit verify FAILED — doc ausente em $requestId',
      );
      throw StateError(
        'Falha ao registrar o convite. Verifique sua conexao e tente novamente.',
      );
    }

    // A Cloud Function pode remover o convite segundos após o create
    // (rate limit/cooldown/bloqueio). Revalidamos no servidor para evitar
    // manter estado otimista incorreto no cliente.
    await Future<void>.delayed(_postSendServerRecheckDelay);
    final recheckSnapshot = await requestRef.get(
      const GetOptions(source: Source.server),
    );
    if (!recheckSnapshot.exists) {
      debugPrint(
        '❌ ConnectionsDS.send: post-send recheck FAILED — doc removido em $requestId',
      );
      throw StateError(
        'Nao foi possivel enviar o convite. Tente novamente mais tarde.',
      );
    }

    final recheckStatus = connectionRequestStatusFromString(
      recheckSnapshot.data()?['status'] as String? ?? '',
    );
    if (recheckStatus != ConnectionRequestStatus.pending) {
      debugPrint(
        '❌ ConnectionsDS.send: post-send recheck FAILED — status=$recheckStatus requestId=$requestId',
      );
      throw StateError(
        'Nao foi possivel enviar o convite. Tente novamente mais tarde.',
      );
    }

    debugPrint('🤝 ConnectionsDS: convite enviado $requestId');
    return ConnectionRequestEntity.fromFirestore(recheckSnapshot);
  }

  /// Um request terminal (accepted/declined/cancelled) é considerado órfão
  /// quando não existe mais um documento `connections/` associado. Esse
  /// limbo ocorria quando `removeConnection` apagava somente `connections/`
  /// sem limpar o request correspondente. Sem essa limpeza, uma nova
  /// tentativa ficava presa em cooldown ou era silenciosamente rejeitada.
  bool _isOrphanTerminalRequest({
    required DocumentSnapshot<Map<String, dynamic>> snapshot,
    required bool connectionExists,
  }) {
    if (!snapshot.exists) {
      return false;
    }
    final status = connectionRequestStatusFromString(
      snapshot.data()?['status'] as String? ?? '',
    );
    if (status == ConnectionRequestStatus.pending) {
      return false;
    }
    // Se está aceito mas não existe connections/, é órfão.
    if (status == ConnectionRequestStatus.accepted) {
      return !connectionExists;
    }
    // Para declined/cancelled, não há par em connections/: nunca são órfãos.
    return false;
  }

  @override
  Future<void> acceptConnectionRequest({
    required String requestId,
    required String responderProfileId,
  }) async {
    final requestRef = _requestsRef.doc(requestId);

    final requestSnapshot = await requestRef.get();
    if (!requestSnapshot.exists) {
      throw StateError('Convite nao encontrado.');
    }

    final requestData = requestSnapshot.data() ?? <String, dynamic>{};
    final requesterProfileId =
        requestData['requesterProfileId'] as String? ?? '';
    final recipientProfileId =
        requestData['recipientProfileId'] as String? ?? '';

    await _requireAvailableProfile(
      profileId: requesterProfileId,
      unavailableMessage: 'Este perfil nao esta mais disponivel para conexoes.',
    );
    await _requireAvailableProfile(
      profileId: recipientProfileId,
      unavailableMessage: 'Seu perfil nao esta disponivel para conexoes agora.',
    );

    await _assertProfilesNotBlocked(
      profileId: responderProfileId,
      otherProfileId: requesterProfileId,
      uid: _currentUid ?? requestData['recipientUid'] as String? ?? '',
    );

    await _firestore.runTransaction((transaction) async {
      final transactionRequestSnapshot = await transaction.get(requestRef);
      if (!transactionRequestSnapshot.exists) {
        throw StateError('Convite nao encontrado.');
      }

      final data = transactionRequestSnapshot.data() ?? <String, dynamic>{};
      final status =
          connectionRequestStatusFromString(data['status'] as String? ?? '');
      if (status != ConnectionRequestStatus.pending) {
        throw StateError('Esse convite nao esta mais pendente.');
      }
      if (recipientProfileId != responderProfileId) {
        throw StateError('Somente o destinatario pode aceitar esse convite.');
      }

      final connectionId =
          _connectionDocId(requesterProfileId, recipientProfileId);
      final connectionRef = _connectionsRef.doc(connectionId);

      transaction.update(requestRef, {
        'status': ConnectionRequestStatus.accepted.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'respondedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(connectionRef, {
        'profileIds': _sortedProfileIds(requesterProfileId, recipientProfileId),
        'profileUids': [
          data['requesterUid'] as String? ?? '',
          data['recipientUid'] as String? ?? '',
        ],
        'profileNames': {
          requesterProfileId: data['requesterName'] as String? ?? '',
          recipientProfileId: data['recipientName'] as String? ?? '',
        },
        'profilePhotoUrls': {
          requesterProfileId: data['requesterPhotoUrl'] as String? ?? '',
          recipientProfileId: data['recipientPhotoUrl'] as String? ?? '',
        },
        'initiatedByProfileId': requesterProfileId,
        'requestId': requestId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _applyStatsDelta(
        transaction,
        profileId: requesterProfileId,
        totalConnectionsDelta: 1,
        pendingSentDelta: -1,
      );
      _applyStatsDelta(
        transaction,
        profileId: recipientProfileId,
        totalConnectionsDelta: 1,
        pendingReceivedDelta: -1,
      );
    });

    debugPrint('🤝 ConnectionsDS: convite aceito $requestId');
  }

  @override
  Future<void> declineConnectionRequest({
    required String requestId,
    required String responderProfileId,
  }) async {
    await _finishPendingRequest(
      requestId: requestId,
      actingProfileId: responderProfileId,
      terminalStatus: ConnectionRequestStatus.declined,
      mustMatchRecipient: true,
    );
  }

  @override
  Future<void> cancelConnectionRequest({
    required String requestId,
    required String requesterProfileId,
  }) async {
    await _finishPendingRequest(
      requestId: requestId,
      actingProfileId: requesterProfileId,
      terminalStatus: ConnectionRequestStatus.cancelled,
      mustMatchRecipient: false,
    );
  }

  Future<void> _finishPendingRequest({
    required String requestId,
    required String actingProfileId,
    required ConnectionRequestStatus terminalStatus,
    required bool mustMatchRecipient,
  }) async {
    final requestRef = _requestsRef.doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw StateError('Convite nao encontrado.');
      }

      final data = requestSnapshot.data() ?? <String, dynamic>{};
      final requesterProfileId = data['requesterProfileId'] as String? ?? '';
      final recipientProfileId = data['recipientProfileId'] as String? ?? '';
      final status =
          connectionRequestStatusFromString(data['status'] as String? ?? '');

      if (status != ConnectionRequestStatus.pending) {
        throw StateError('Esse convite nao esta mais pendente.');
      }

      if (mustMatchRecipient && recipientProfileId != actingProfileId) {
        throw StateError('Somente o destinatario pode concluir esse convite.');
      }

      if (!mustMatchRecipient && requesterProfileId != actingProfileId) {
        throw StateError('Somente o solicitante pode cancelar esse convite.');
      }

      transaction.update(requestRef, {
        'status': terminalStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'respondedAt': FieldValue.serverTimestamp(),
      });

      _applyStatsDelta(
        transaction,
        profileId: requesterProfileId,
        pendingSentDelta: -1,
      );
      _applyStatsDelta(
        transaction,
        profileId: recipientProfileId,
        pendingReceivedDelta: -1,
      );
    });

    debugPrint(
        '🤝 ConnectionsDS: convite finalizado $requestId -> ${terminalStatus.name}');
  }

  @override
  Future<void> removeConnection({
    required String connectionId,
    required String currentProfileId,
  }) async {
    final connectionRef = _connectionsRef.doc(connectionId);

    await _firestore.runTransaction((transaction) async {
      final connectionSnapshot = await transaction.get(connectionRef);
      if (!connectionSnapshot.exists) {
        throw StateError('Conexao nao encontrada.');
      }

      final data = connectionSnapshot.data() ?? <String, dynamic>{};
      final profileIds =
          (data['profileIds'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>();

      if (!profileIds.contains(currentProfileId) || profileIds.length != 2) {
        throw StateError('Somente participantes podem remover a conexao.');
      }

      // Também remove os documentos de connectionRequests do par
      // (direto e inverso) para evitar limbo: sem isso, um novo convite
      // entre os mesmos perfis encontra o request antigo "accepted" e
      // cai em cooldown ou falha silenciosa.
      final directRequestRef =
          _requestsRef.doc(_requestDocId(profileIds[0], profileIds[1]));
      final inverseRequestRef =
          _requestsRef.doc(_requestDocId(profileIds[1], profileIds[0]));
      final directRequestSnap = await transaction.get(directRequestRef);
      final inverseRequestSnap = await transaction.get(inverseRequestRef);

      transaction.delete(connectionRef);
      if (directRequestSnap.exists) {
        transaction.delete(directRequestRef);
      }
      if (inverseRequestSnap.exists) {
        transaction.delete(inverseRequestRef);
      }
      for (final profileId in profileIds) {
        _applyStatsDelta(
          transaction,
          profileId: profileId,
          totalConnectionsDelta: -1,
        );
      }
    });

    debugPrint('🤝 ConnectionsDS: conexao removida $connectionId');
  }

  @override
  Stream<List<ConnectionEntity>> watchConnections({
    required String profileId,
    required String profileUid,
    int limit = 50,
  }) {
    // Query por profileUids (UIDs) para alinhar com Security Rules
    // que validam request.auth.uid in resource.data.profileUids.
    // Filtro por profileId específico é feito client-side abaixo.
    final connectionsStream = _connectionsRef
        .where('profileUids', arrayContains: profileUid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
    final excludedProfileIdsStream = BlockedRelations.watchExcludedProfileIds(
      firestore: _firestore,
      profileId: profileId,
      uid: profileUid,
    );

    return Rx.combineLatest2(
      connectionsStream,
      excludedProfileIdsStream,
      (QuerySnapshot<Map<String, dynamic>> snapshot, List<String> excludedIds) {
        return snapshot.docs
            .where(
              (doc) {
                final ids = doc.data()['profileIds'] as List<dynamic>? ??
                    const <dynamic>[];
                return ids.contains(profileId);
              },
            )
            .map(ConnectionEntity.fromFirestore)
            .where(
              (connection) =>
                  _hasAvailableConnectionCounterpart(
                    connection,
                    currentProfileId: profileId,
                  ) &&
                  !excludedIds
                      .contains(connection.getOtherProfileId(profileId)),
            )
            .toList();
      },
    );
  }

  @override
  Future<ConnectionPageEntity> loadConnectionsPage({
    required String profileId,
    required String profileUid,
    String? startAfterConnectionId,
    int limit = 20,
  }) async {
    final excludedProfileIds = await BlockedRelations.getExcludedProfileIds(
      firestore: _firestore,
      profileId: profileId,
      uid: profileUid,
    );

    final pageSize = limit <= 0 ? 20 : limit;
    final fetchSize =
        (pageSize * _connectionsPageFetchMultiplier).clamp(pageSize, 60);

    DocumentSnapshot<Map<String, dynamic>>? cursorSnapshot;
    if (startAfterConnectionId != null && startAfterConnectionId.isNotEmpty) {
      final document = await _connectionsRef.doc(startAfterConnectionId).get();
      if (document.exists) {
        cursorSnapshot = document;
      }
    }

    final connections = <ConnectionEntity>[];
    String? nextCursor;
    var hasMore = false;

    while (connections.length < pageSize) {
      var query = _connectionsRef
          .where('profileUids', arrayContains: profileUid)
          .orderBy('createdAt', descending: true)
          .limit(fetchSize);

      if (cursorSnapshot != null) {
        query = query.startAfterDocument(cursorSnapshot);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        hasMore = false;
        nextCursor = null;
        break;
      }

      cursorSnapshot = snapshot.docs.last;
      nextCursor = cursorSnapshot.id;
      hasMore = snapshot.docs.length == fetchSize;

      for (final doc in snapshot.docs) {
        final ids =
            (doc.data()['profileIds'] as List<dynamic>? ?? const <dynamic>[])
                .cast<String>();
        if (!ids.contains(profileId)) {
          continue;
        }

        final connection = ConnectionEntity.fromFirestore(doc);
        final otherProfileId = connection.getOtherProfileId(profileId);
        if (!_hasAvailableConnectionCounterpart(
          connection,
          currentProfileId: profileId,
        )) {
          continue;
        }
        if (excludedProfileIds.contains(otherProfileId)) {
          continue;
        }

        connections.add(connection);
        if (connections.length == pageSize) {
          break;
        }
      }

      if (!hasMore) {
        break;
      }
    }

    return ConnectionPageEntity(
      connections: connections,
      hasMore: hasMore,
      nextCursor: hasMore ? nextCursor : null,
    );
  }

  @override
  Stream<List<ConnectionRequestEntity>> watchPendingReceivedRequests({
    required String profileId,
    required String profileUid,
    int limit = 25,
  }) {
    debugPrint(
      '📥 [CONNECTIONS] subscribe received profileId=$profileId '
      'profileUid=$profileUid',
    );
    final requestsStream = _requestsRef
        .where('recipientProfileId', isEqualTo: profileId)
        .where('recipientUid', isEqualTo: profileUid)
        .where('status', isEqualTo: ConnectionRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((Object error, StackTrace st) {
      debugPrint(
        '❌ [CONNECTIONS] watchPendingReceivedRequests error '
        'profileId=$profileId profileUid=$profileUid: '
        '${error.runtimeType}: $error',
      );
    }).map((snapshot) {
      debugPrint(
        '📥 [CONNECTIONS] received snapshot profileId=$profileId '
        'profileUid=$profileUid docs=${snapshot.docs.length}',
      );
      return snapshot;
    });
    final excludedProfileIdsStream = BlockedRelations.watchExcludedProfileIds(
      firestore: _firestore,
      profileId: profileId,
      uid: profileUid,
    );

    return Rx.combineLatest2(
      requestsStream,
      excludedProfileIdsStream,
      (QuerySnapshot<Map<String, dynamic>> snapshot, List<String> excludedIds) {
        final parsed =
            snapshot.docs.map(ConnectionRequestEntity.fromFirestore).toList();
        final filtered = parsed
            .where(
              (request) =>
                  _hasAvailableRequestCounterpart(
                    request,
                    isReceived: true,
                  ) &&
                  !excludedIds.contains(request.requesterProfileId),
            )
            .toList();
        if (parsed.length != filtered.length) {
          debugPrint(
            '🔎 [CONNECTIONS] received filter dropped '
            '${parsed.length - filtered.length}/${parsed.length} '
            '(excluded=${excludedIds.length}) profileId=$profileId',
          );
        }
        return filtered;
      },
    );
  }

  @override
  Stream<List<ConnectionRequestEntity>> watchPendingSentRequests({
    required String profileId,
    required String profileUid,
    int limit = 25,
  }) {
    debugPrint(
      '📤 [CONNECTIONS] subscribe sent profileId=$profileId '
      'profileUid=$profileUid',
    );
    final requestsStream = _requestsRef
        .where('requesterProfileId', isEqualTo: profileId)
        .where('requesterUid', isEqualTo: profileUid)
        .where('status', isEqualTo: ConnectionRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((Object error, StackTrace st) {
      debugPrint(
        '❌ [CONNECTIONS] watchPendingSentRequests error '
        'profileId=$profileId profileUid=$profileUid: '
        '${error.runtimeType}: $error',
      );
    }).map((snapshot) {
      debugPrint(
        '📤 [CONNECTIONS] sent snapshot profileId=$profileId '
        'profileUid=$profileUid docs=${snapshot.docs.length}',
      );
      return snapshot;
    });
    final excludedProfileIdsStream = BlockedRelations.watchExcludedProfileIds(
      firestore: _firestore,
      profileId: profileId,
      uid: profileUid,
    );

    return Rx.combineLatest2(
      requestsStream,
      excludedProfileIdsStream,
      (QuerySnapshot<Map<String, dynamic>> snapshot, List<String> excludedIds) {
        final parsed =
            snapshot.docs.map(ConnectionRequestEntity.fromFirestore).toList();
        final filtered = parsed
            .where(
              (request) =>
                  _hasAvailableRequestCounterpart(
                    request,
                    isReceived: false,
                  ) &&
                  !excludedIds.contains(request.recipientProfileId),
            )
            .toList();
        if (parsed.length != filtered.length) {
          debugPrint(
            '🔎 [CONNECTIONS] sent filter dropped '
            '${parsed.length - filtered.length}/${parsed.length} '
            '(excluded=${excludedIds.length}) profileId=$profileId',
          );
        }
        return filtered;
      },
    );
  }

  @override
  Stream<ConnectionStatsEntity> watchConnectionStats({
    required String profileId,
  }) {
    return _statsRef.doc(profileId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return ConnectionStatsEntity.empty(profileId);
      }
      return ConnectionStatsEntity.fromFirestore(snapshot);
    });
  }

  @override
  Stream<List<PostEntity>> watchNetworkActivity({
    required String profileId,
    required String profileUid,
    int limit = 10,
  }) {
    return watchConnections(
      profileId: profileId,
      profileUid: profileUid,
      limit: 20,
    )
        .map(
          (connections) =>
              _normalizedConnectedProfileIds(connections, profileId),
        )
        .distinct(_sameProfileIdList)
        .switchMap(
          (connectedProfileIds) => _watchNetworkActivityForConnectedProfiles(
            profileId: profileId,
            connectedProfileIds: connectedProfileIds,
            limit: limit,
          ),
        );
  }

  @override
  Future<NetworkActivityPageEntity> loadNetworkActivityPage({
    required String profileId,
    required String profileUid,
    NetworkActivityCursorEntity? startAfter,
    int limit = 20,
  }) async {
    final connectedProfileIds = await _loadConnectedProfileIds(
      profileId: profileId,
      profileUid: profileUid,
    );

    if (connectedProfileIds.isEmpty) {
      return const NetworkActivityPageEntity(
        posts: <PostEntity>[],
        hasMore: false,
      );
    }

    final pageSize = limit <= 0 ? 20 : limit;
    final fetchSize =
        (pageSize * _networkActivityPageFetchMultiplier).clamp(pageSize, 60);
    final cursorTimestamp =
        startAfter != null ? Timestamp.fromDate(startAfter.createdAt) : null;
    final boundaryPostIds = startAfter?.boundaryPostIds.toSet() ?? <String>{};

    final connectedProfileChunks = _chunkProfileIds(connectedProfileIds);
    final postSnapshots = await Future.wait(
      connectedProfileChunks.map((chunk) {
        var query = _firestore
            .collection('posts')
            .where('authorProfileId', whereIn: chunk)
            .orderBy('createdAt', descending: true)
            .limit(fetchSize);

        if (cursorTimestamp != null) {
          query = query.where(
            'createdAt',
            isLessThanOrEqualTo: cursorTimestamp,
          );
        }

        return query.get();
      }),
    );

    final postsById = <String, PostEntity>{};
    var touchedFetchCeiling = false;
    for (final snapshot in postSnapshots) {
      if (snapshot.docs.length == fetchSize) {
        touchedFetchCeiling = true;
      }

      for (final doc in snapshot.docs) {
        final post = PostEntity.fromFirestore(doc);
        if (post.authorProfileId.trim().isEmpty || post.isExpired) {
          continue;
        }

        if (startAfter != null &&
            post.createdAt.isAtSameMomentAs(startAfter.createdAt) &&
            boundaryPostIds.contains(post.id)) {
          continue;
        }

        postsById[post.id] = post;
      }
    }

    if (postsById.isEmpty) {
      return const NetworkActivityPageEntity(
        posts: <PostEntity>[],
        hasMore: false,
      );
    }

    final currentProfile = await _loadAvailableProfileById(profileId);
    final currentLocation = currentProfile?.location;
    final hasCurrentLocation =
        currentLocation != null && _hasValidGeoPoint(currentLocation);
    final availableProfilesById = await _loadProfilesByIds(
      postsById.values
          .map((post) => post.authorProfileId)
          .toSet()
          .toList(growable: false),
    );

    final enrichedPosts = postsById.values
        .where(
      (post) => availableProfilesById.containsKey(post.authorProfileId),
    )
        .map((post) {
      final authorProfile = availableProfilesById[post.authorProfileId]!;
      final distanceKm = hasCurrentLocation && _hasValidGeoPoint(post.location)
          ? calculateDistanceBetweenGeoPoints(
              currentLocation,
              post.location,
            )
          : post.distanceKm;
      return post.copyWith(
        authorName: post.authorName ?? authorProfile.name,
        authorPhotoUrl: post.authorPhotoUrl ?? authorProfile.photoUrl,
        distanceKm: distanceKm,
      );
    }).toList(growable: false)
      ..sort((left, right) {
        final createdAtCompare = right.createdAt.compareTo(left.createdAt);
        if (createdAtCompare != 0) {
          return createdAtCompare;
        }

        return right.id.compareTo(left.id);
      });

    final pagePosts = enrichedPosts.take(pageSize).toList(growable: false);
    final hasOverflowCandidates = enrichedPosts.length > pageSize;
    final hasMore =
        pagePosts.isNotEmpty && (hasOverflowCandidates || touchedFetchCeiling);

    NetworkActivityCursorEntity? nextCursor;
    if (hasMore && pagePosts.isNotEmpty) {
      final boundaryCreatedAt = pagePosts.last.createdAt;
      nextCursor = NetworkActivityCursorEntity(
        createdAt: boundaryCreatedAt,
        boundaryPostIds: pagePosts
            .where((post) => post.createdAt.isAtSameMomentAs(boundaryCreatedAt))
            .map((post) => post.id)
            .toList(growable: false),
      );
    }

    return NetworkActivityPageEntity(
      posts: pagePosts,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  @override
  Future<List<CommonConnectionEntity>> loadCommonConnections({
    required String profileId,
    required String profileUid,
    required String otherProfileId,
    required String otherProfileUid,
    int limit = 3,
  }) async {
    final results = await Future.wait([
      _connectionsRef
          .where('profileIds', arrayContains: profileId)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get(),
      _connectionsRef
          .where('profileIds', arrayContains: otherProfileId)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get(),
      BlockedRelations.getExcludedProfileIds(
        firestore: _firestore,
        profileId: profileId,
        uid: profileUid,
      ),
      BlockedRelations.getExcludedProfileIds(
        firestore: _firestore,
        profileId: otherProfileId,
        uid: otherProfileUid,
      ),
    ]);

    final currentSnapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final otherSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final currentExcluded = results[2] as List<String>;
    final otherExcluded = results[3] as List<String>;

    final excludedProfileIds = {
      ...currentExcluded,
      ...otherExcluded,
      profileId,
      otherProfileId,
    };

    final currentConnectionsByProfileId = <String, CommonConnectionEntity>{};
    for (final doc in currentSnapshot.docs) {
      final connection = ConnectionEntity.fromFirestore(doc);
      final sharedProfileId = connection.getOtherProfileId(profileId);
      if (sharedProfileId.isEmpty ||
          excludedProfileIds.contains(sharedProfileId)) {
        continue;
      }

      currentConnectionsByProfileId[sharedProfileId] = CommonConnectionEntity(
        profileId: sharedProfileId,
        uid: connection.getOtherProfileUid(profileId),
        name: connection.getOtherProfileName(profileId),
        photoUrl: connection.getOtherProfilePhotoUrl(profileId),
      );
    }

    final commonConnections = <CommonConnectionEntity>[];
    for (final doc in otherSnapshot.docs) {
      final connection = ConnectionEntity.fromFirestore(doc);
      final sharedProfileId = connection.getOtherProfileId(otherProfileId);
      if (sharedProfileId.isEmpty ||
          excludedProfileIds.contains(sharedProfileId)) {
        continue;
      }

      final commonConnection = currentConnectionsByProfileId[sharedProfileId];
      if (commonConnection == null) {
        continue;
      }

      commonConnections.add(commonConnection);
    }

    final availableProfilesById = await _loadProfilesByIds(
      commonConnections
          .map((connection) => connection.profileId)
          .toList(growable: false),
    );

    final filteredCommonConnections = commonConnections
        .where((connection) =>
            availableProfilesById.containsKey(connection.profileId))
        .map((connection) {
      final profile = availableProfilesById[connection.profileId]!;
      return CommonConnectionEntity(
        profileId: profile.profileId,
        uid: profile.uid,
        name: profile.name,
        photoUrl: profile.photoUrl,
        username: profile.username,
      );
    }).toList(growable: false);

    filteredCommonConnections.sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );

    return filteredCommonConnections.take(limit).toList(growable: false);
  }

  Future<List<String>> _loadConnectedProfileIds({
    required String profileId,
    required String profileUid,
  }) async {
    final excludedProfileIds = await BlockedRelations.getExcludedProfileIds(
      firestore: _firestore,
      profileId: profileId,
      uid: profileUid,
    );

    final snapshot = await _connectionsRef
        .where('profileUids', arrayContains: profileUid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .where((doc) {
          final ids =
              doc.data()['profileIds'] as List<dynamic>? ?? const <dynamic>[];
          return ids.contains(profileId);
        })
        .map(ConnectionEntity.fromFirestore)
        .where(
          (connection) =>
              _hasAvailableConnectionCounterpart(
                connection,
                currentProfileId: profileId,
              ) &&
              !excludedProfileIds.contains(
                connection.getOtherProfileId(profileId),
              ),
        )
        .map((connection) => connection.getOtherProfileId(profileId).trim())
        .where((otherProfileId) => otherProfileId.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  @override
  Future<List<ConnectionSuggestionEntity>> loadConnectionSuggestions({
    required String profileId,
    required String profileUid,
    required String currentCity,
    required String currentProfileType,
    required String? currentLevel,
    required List<String> currentInstruments,
    required List<String> currentGenres,
    int limit = 6,
    List<String> filterProfileTypes = const <String>[],
    List<String> filterInstruments = const <String>[],
    List<String> filterGenres = const <String>[],
    bool filterSameCity = false,
    bool filterWithCommonConnections = false,
  }) async {
    final normalizedCity = currentCity.trim();
    final currentLevelRank = _levelRank(currentLevel);
    final normalizedInstruments = currentInstruments
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
    final normalizedGenres = currentGenres
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
    final normalizedFilterProfileTypes = filterProfileTypes
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
    final normalizedFilterInstruments = filterInstruments
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
    final normalizedFilterGenres = filterGenres
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
    final hasSuggestionFilters = normalizedFilterProfileTypes.isNotEmpty ||
        normalizedFilterInstruments.isNotEmpty ||
        normalizedFilterGenres.isNotEmpty ||
        filterSameCity ||
        filterWithCommonConnections;

    // Query por profileUids para alinhar com Security Rules
    final currentConnectionsSnapshot = await _connectionsRef
        .where('profileUids', arrayContains: profileUid)
        .limit(500)
        .get();
    final pendingSentSnapshot = await _requestsRef
        .where('requesterProfileId', isEqualTo: profileId)
        .where('requesterUid', isEqualTo: profileUid)
        .where('status', isEqualTo: ConnectionRequestStatus.pending.name)
        .limit(100)
        .get();
    final pendingReceivedSnapshot = await _requestsRef
        .where('recipientProfileId', isEqualTo: profileId)
        .where('recipientUid', isEqualTo: profileUid)
        .where('status', isEqualTo: ConnectionRequestStatus.pending.name)
        .limit(100)
        .get();
    // Query por participants (UIDs) para alinhar com Security Rules
    final conversationsSnapshot = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: profileUid)
        .limit(200)
        .get();
    final sentInterestsSnapshot = await _firestore
        .collection('interests')
        .where('interestedProfileId', isEqualTo: profileId)
        .limit(200)
        .get();
    final receivedInterestsSnapshot = await _firestore
        .collection('interests')
        .where('postAuthorProfileId', isEqualTo: profileId)
        .limit(200)
        .get();
    final excludedProfileIds = (await BlockedRelations.getExcludedProfileIds(
      firestore: _firestore,
      profileId: profileId,
      uid: profileUid,
    ))
        .toSet();
    final currentProfile = await _loadAvailableProfileById(profileId);
    if (currentProfile == null || !currentProfile.allowConnectionSuggestions) {
      return const <ConnectionSuggestionEntity>[];
    }
    final currentActivePosts = await _loadActivePostsByAuthorProfileId(
      profileId: profileId,
    );
    final suggestionsContextSignature =
        _suggestionsContextSignature(currentActivePosts);
    final currentYearsOfExperience = currentProfile.ageOrYearsSinceFormation;
    final currentMusicPlatformCount = _musicPlatformCount(currentProfile);

    final connectedProfileIds = currentConnectionsSnapshot.docs
        .map(ConnectionEntity.fromFirestore)
        .where((connection) => connection.profileIds.contains(profileId))
        .map((connection) => connection.getOtherProfileId(profileId))
        .where((candidateProfileId) => candidateProfileId.isNotEmpty)
        .toSet();
    final pendingProfileIds = {
      ...pendingSentSnapshot.docs
          .map((doc) => doc.data()['recipientProfileId'] as String? ?? '')
          .where((candidateProfileId) => candidateProfileId.isNotEmpty),
      ...pendingReceivedSnapshot.docs
          .map((doc) => doc.data()['requesterProfileId'] as String? ?? '')
          .where((candidateProfileId) => candidateProfileId.isNotEmpty),
    };
    final chattedProfileIds = conversationsSnapshot.docs
        .map((doc) => doc.data())
        .where((data) {
          final participantProfiles =
              (data['participantProfiles'] as List<dynamic>? ??
                      const <dynamic>[])
                  .cast<String>();
          return participantProfiles.length == 2 &&
              participantProfiles.contains(profileId) &&
              (data['isGroup'] as bool? ?? false) != true;
        })
        .map((data) {
          final participantProfiles =
              (data['participantProfiles'] as List<dynamic>? ??
                      const <dynamic>[])
                  .cast<String>();
          return participantProfiles.firstWhere(
            (candidateProfileId) => candidateProfileId != profileId,
            orElse: () => '',
          );
        })
        .where((candidateProfileId) => candidateProfileId.isNotEmpty)
        .toSet();
    final sentInterestProfileIds = sentInterestsSnapshot.docs
        .map((doc) => doc.data()['postAuthorProfileId'] as String? ?? '')
        .where((candidateProfileId) => candidateProfileId.isNotEmpty)
        .toSet();
    final receivedInterestProfileIds = receivedInterestsSnapshot.docs
        .map((doc) => doc.data()['interestedProfileId'] as String? ?? '')
        .where((candidateProfileId) => candidateProfileId.isNotEmpty)
        .toSet();

    if (!hasSuggestionFilters) {
      final cachedSuggestions = await _loadSuggestionsFromCache(
        profileId: profileId,
        profileUid: profileUid,
        excludedProfileIds: excludedProfileIds,
        connectedProfileIds: connectedProfileIds,
        pendingProfileIds: pendingProfileIds,
        contextSignature: suggestionsContextSignature,
        limit: limit,
      );
      if (cachedSuggestions != null) {
        return cachedSuggestions;
      }
    }

    final profileDocsById = <String, DocumentSnapshot<Map<String, dynamic>>>{};

    Future<void> collectProfiles(Query<Map<String, dynamic>> query) async {
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        profileDocsById[doc.id] = doc;
      }
    }

    final candidateQueryLimit = hasSuggestionFilters
        ? math.min(
            math.max(limit * 10, _suggestionsCandidatePoolFloor * 2),
            500,
          )
        : math.max(
            limit * 6,
            _suggestionsCandidatePoolFloor,
          );

    if (normalizedCity.isNotEmpty) {
      await collectProfiles(
        _firestore
            .collection('profiles')
            .where('city', isEqualTo: normalizedCity)
            .limit(candidateQueryLimit),
      );
    }

    if (normalizedFilterProfileTypes.isNotEmpty) {
      await collectProfiles(
        _firestore
            .collection('profiles')
            .where(
              'profileType',
              whereIn: normalizedFilterProfileTypes.take(10).toList(),
            )
            .limit(candidateQueryLimit),
      );
    }

    if (normalizedFilterInstruments.isNotEmpty) {
      await collectProfiles(
        _firestore
            .collection('profiles')
            .where(
              'instruments',
              arrayContainsAny: normalizedFilterInstruments.take(10).toList(),
            )
            .limit(candidateQueryLimit),
      );
    }

    if (normalizedFilterGenres.isNotEmpty) {
      await collectProfiles(
        _firestore
            .collection('profiles')
            .where(
              'genres',
              arrayContainsAny: normalizedFilterGenres.take(10).toList(),
            )
            .limit(candidateQueryLimit),
      );
    }

    if (profileDocsById.length < limit * 3) {
      await collectProfiles(
        _firestore
            .collection('profiles')
            .orderBy('createdAt', descending: true)
            .limit(candidateQueryLimit),
      );
    }

    final candidateProfiles = profileDocsById.values
        .map(ProfileEntity.fromFirestore)
        .where((candidate) {
      if (candidate.profileId == profileId) {
        return false;
      }
      if (!_isProfileAvailable(candidate)) {
        return false;
      }
      if (candidate.uid == profileUid) {
        return false;
      }
      if (excludedProfileIds.contains(candidate.profileId)) {
        return false;
      }
      if (connectedProfileIds.contains(candidate.profileId)) {
        return false;
      }
      if (pendingProfileIds.contains(candidate.profileId)) {
        return false;
      }
      if (!_allowsConnectionSuggestions(candidate)) {
        return false;
      }
      if (!_allowsConnectionRequests(candidate)) {
        return false;
      }
      if (normalizedFilterProfileTypes.isNotEmpty &&
          !normalizedFilterProfileTypes.contains(candidate.profileType.value)) {
        return false;
      }
      if (filterSameCity &&
          normalizedCity.isNotEmpty &&
          candidate.city.trim().toLowerCase() != normalizedCity.toLowerCase()) {
        return false;
      }
      if (normalizedFilterInstruments.isNotEmpty) {
        final candidateInstruments = (candidate.instruments ?? const <String>[])
            .map((item) => item.trim().toLowerCase())
            .where((item) => item.isNotEmpty)
            .toSet();
        if (candidateInstruments
            .intersection(normalizedFilterInstruments)
            .isEmpty) {
          return false;
        }
      }
      if (normalizedFilterGenres.isNotEmpty) {
        final candidateGenres = (candidate.genres ?? const <String>[])
            .map((item) => item.trim().toLowerCase())
            .where((item) => item.isNotEmpty)
            .toSet();
        if (candidateGenres.intersection(normalizedFilterGenres).isEmpty) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);

    final preScored = candidateProfiles
        .map(
          (candidate) {
            final postAffinityScore = _postDrivenSuggestionScore(
              candidate: candidate,
              currentActivePosts: currentActivePosts,
            );
            final baseScore = _baseSuggestionScore(
              candidate: candidate,
              currentCity: normalizedCity,
              currentProfileType: currentProfileType,
              currentLevelRank: currentLevelRank,
              currentYearsOfExperience: currentYearsOfExperience,
              currentMusicPlatformCount: currentMusicPlatformCount,
              normalizedInstruments: normalizedInstruments,
              normalizedGenres: normalizedGenres,
              chattedProfileIds: chattedProfileIds,
              sentInterestProfileIds: sentInterestProfileIds,
              receivedInterestProfileIds: receivedInterestProfileIds,
            );

            return MapEntry(
              candidate,
              _SuggestionScoreBreakdown(
                baseScore: baseScore,
                postAffinityScore: postAffinityScore,
              ),
            );
          },
        )
        .where((entry) => entry.value.isEligible)
        .toList()
      ..sort((left, right) => right.value.compareTo(left.value));

    final evaluationLimit = filterWithCommonConnections
        ? preScored.length
        : math.min(
            preScored.length,
            math.max(limit + _suggestionsEvaluationBuffer, limit),
          );

    final evaluationEntries =
        preScored.take(evaluationLimit).toList(growable: false);
    final commonConnectionsByProfileId = <String, int>{};

    final commonConnectionsWindow = filterWithCommonConnections
        ? evaluationEntries.length
        : math.min(
            evaluationEntries.length,
            math.max(limit, _suggestionsCommonConnectionsFloor),
          );

    final commonConnectionsEntries =
        evaluationEntries.take(commonConnectionsWindow).toList(growable: false);

    const commonConnectionsLookupBatchSize = 12;
    for (var start = 0;
        start < commonConnectionsEntries.length;
        start += commonConnectionsLookupBatchSize) {
      final batchEntries = commonConnectionsEntries
          .skip(start)
          .take(commonConnectionsLookupBatchSize)
          .toList(growable: false);
      final commonConnectionsResults = await Future.wait(
        batchEntries.map((entry) async {
          final candidate = entry.key;
          final commonConnections = await loadCommonConnections(
            profileId: profileId,
            profileUid: profileUid,
            otherProfileId: candidate.profileId,
            otherProfileUid: candidate.uid,
            limit: 10,
          );

          return MapEntry(candidate.profileId, commonConnections.length);
        }),
      );

      for (final result in commonConnectionsResults) {
        commonConnectionsByProfileId[result.key] = result.value;
      }
    }

    final suggestions = <ConnectionSuggestionEntity>[];
    for (final entry in evaluationEntries) {
      final candidate = entry.key;
      final scoreBreakdown = entry.value;
      final commonConnectionsCount =
          commonConnectionsByProfileId[candidate.profileId] ?? 0;

      if (filterWithCommonConnections && commonConnectionsCount <= 0) {
        continue;
      }

      suggestions.add(
        ConnectionSuggestionEntity(
          profile: candidate,
          score: scoreBreakdown.totalScore(
            commonConnectionsCount: commonConnectionsCount,
          ),
          reason: _buildSuggestionReason(
            candidate: candidate,
            hasPostAffinity: scoreBreakdown.hasPostAffinity,
            currentCity: normalizedCity,
            currentProfileType: currentProfileType,
            currentLevel: currentLevel,
            currentLevelRank: currentLevelRank,
            currentYearsOfExperience: currentYearsOfExperience,
            currentMusicPlatformCount: currentMusicPlatformCount,
            normalizedInstruments: normalizedInstruments,
            normalizedGenres: normalizedGenres,
            commonConnectionsCount: commonConnectionsCount,
            chattedProfileIds: chattedProfileIds,
            sentInterestProfileIds: sentInterestProfileIds,
            receivedInterestProfileIds: receivedInterestProfileIds,
          ),
          commonConnectionsCount: commonConnectionsCount,
        ),
      );
    }

    suggestions.sort((left, right) => right.score.compareTo(left.score));
    final finalSuggestions = suggestions.take(limit).toList(growable: false);
    if (!hasSuggestionFilters) {
      try {
        await _storeSuggestionsInCache(
          profileId: profileId,
          contextSignature: suggestionsContextSignature,
          suggestions: finalSuggestions,
        );
      } catch (_) {
        // Cache write is best-effort — don't break suggestions on failure
      }
    }
    return finalSuggestions;
  }

  @override
  Future<ConnectionStatusEntity> getConnectionStatus({
    required String profileId,
    required String profileUid,
    required String otherProfileId,
  }) async {
    final otherProfile = await _loadAvailableProfileById(otherProfileId);
    if (otherProfile == null) {
      return ConnectionStatusEntity(
        status: ConnectionRelationshipStatus.none,
        otherProfileId: otherProfileId,
      );
    }

    final isBlocked = await _areProfilesBlocked(
      profileId: profileId,
      otherProfileId: otherProfileId,
      uid: profileUid,
    );
    if (isBlocked) {
      return ConnectionStatusEntity(
        status: ConnectionRelationshipStatus.none,
        otherProfileId: otherProfileId,
      );
    }

    final connectionId = _connectionDocId(profileId, otherProfileId);
    final connectionSnapshot = await _connectionsRef.doc(connectionId).get();

    if (connectionSnapshot.exists) {
      final profileUids =
          (connectionSnapshot.data()?['profileUids'] as List<dynamic>? ??
                  const <dynamic>[])
              .cast<String>();
      if (profileUids.contains(profileUid)) {
        return ConnectionStatusEntity(
          status: ConnectionRelationshipStatus.connected,
          connectionId: connectionId,
          otherProfileId: otherProfileId,
        );
      }
    }

    final outgoingRequestId = _requestDocId(profileId, otherProfileId);
    final outgoingRequestSnapshot =
        await _requestsRef.doc(outgoingRequestId).get();
    if (outgoingRequestSnapshot.exists) {
      final status = connectionRequestStatusFromString(
        outgoingRequestSnapshot.data()?['status'] as String? ?? '',
      );
      if (status == ConnectionRequestStatus.pending) {
        return ConnectionStatusEntity(
          status: ConnectionRelationshipStatus.pendingSent,
          requestId: outgoingRequestId,
          otherProfileId: otherProfileId,
        );
      }
    }

    final incomingRequestId = _requestDocId(otherProfileId, profileId);
    final incomingRequestSnapshot =
        await _requestsRef.doc(incomingRequestId).get();
    if (incomingRequestSnapshot.exists) {
      final data = incomingRequestSnapshot.data() ?? <String, dynamic>{};
      final status =
          connectionRequestStatusFromString(data['status'] as String? ?? '');
      if (status == ConnectionRequestStatus.pending &&
          data['recipientUid'] == profileUid) {
        return ConnectionStatusEntity(
          status: ConnectionRelationshipStatus.pendingReceived,
          requestId: incomingRequestId,
          otherProfileId: otherProfileId,
        );
      }
    }

    return ConnectionStatusEntity(
      status: ConnectionRelationshipStatus.none,
      otherProfileId: otherProfileId,
    );
  }

  void _applyStatsDelta(
    Transaction transaction, {
    required String profileId,
    int totalConnectionsDelta = 0,
    int pendingReceivedDelta = 0,
    int pendingSentDelta = 0,
  }) {
    final ref = _statsRef.doc(profileId);
    transaction.set(
      ref,
      {
        'profileId': profileId,
        'totalConnections': FieldValue.increment(totalConnectionsDelta),
        'pendingReceived': FieldValue.increment(pendingReceivedDelta),
        'pendingSent': FieldValue.increment(pendingSentDelta),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  List<String> _sortedProfileIds(
      String firstProfileId, String secondProfileId) {
    final ids = <String>[firstProfileId, secondProfileId];
    ids.sort();
    return ids;
  }

  String _requestDocId(String requesterProfileId, String recipientProfileId) {
    return '${requesterProfileId}_$recipientProfileId';
  }

  String _connectionDocId(String firstProfileId, String secondProfileId) {
    return _sortedProfileIds(firstProfileId, secondProfileId).join('__');
  }

  int _baseSuggestionScore({
    required ProfileEntity candidate,
    required String currentCity,
    required String currentProfileType,
    required int? currentLevelRank,
    required int? currentYearsOfExperience,
    required int currentMusicPlatformCount,
    required Set<String> normalizedInstruments,
    required Set<String> normalizedGenres,
    required Set<String> chattedProfileIds,
    required Set<String> sentInterestProfileIds,
    required Set<String> receivedInterestProfileIds,
  }) {
    var score = 0;

    if (currentCity.isNotEmpty && candidate.city.trim() == currentCity) {
      score += 25;
    }

    final candidateInstruments = (candidate.instruments ?? const <String>[])
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
    final candidateGenres = (candidate.genres ?? const <String>[])
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();

    score +=
        _intersectionSize(normalizedInstruments, candidateInstruments) * 18;
    score += _intersectionSize(normalizedGenres, candidateGenres) * 14;

    final candidateProfileType = candidate.profileType.value;
    if (candidateProfileType == currentProfileType) {
      score += 10;
    } else if ((currentProfileType == 'musician' &&
            candidateProfileType == 'band') ||
        (currentProfileType == 'band' && candidateProfileType == 'musician')) {
      score += 8;
    } else if (currentProfileType == 'space' ||
        candidateProfileType == 'space') {
      score += 6;
    }

    final candidateLevelRank = _levelRank(candidate.level);
    if (currentLevelRank != null && candidateLevelRank != null) {
      final levelDistance = (currentLevelRank - candidateLevelRank).abs();
      if (levelDistance == 0) {
        score += 12;
      } else if (levelDistance == 1) {
        score += 7;
      } else if (levelDistance == 2) {
        score += 3;
      }
    }

    final candidateYearsOfExperience = candidate.ageOrYearsSinceFormation;
    if (candidateProfileType == currentProfileType &&
        currentYearsOfExperience != null &&
        candidateYearsOfExperience != null) {
      final yearsDistance =
          (currentYearsOfExperience - candidateYearsOfExperience).abs();
      if (yearsDistance <= 2) {
        score += 8;
      } else if (yearsDistance <= 5) {
        score += 4;
      }
    }

    final candidateMusicPlatformCount = _musicPlatformCount(candidate);
    if (currentMusicPlatformCount > 0 && candidateMusicPlatformCount > 0) {
      final sharedPlatformCount =
          currentMusicPlatformCount < candidateMusicPlatformCount
              ? currentMusicPlatformCount
              : candidateMusicPlatformCount;
      score += sharedPlatformCount * 4;
      if (sharedPlatformCount >= 2) {
        score += 4;
      }
    }

    if (chattedProfileIds.contains(candidate.profileId)) {
      score += 22;
    }
    if (sentInterestProfileIds.contains(candidate.profileId)) {
      score += 16;
    }
    if (receivedInterestProfileIds.contains(candidate.profileId)) {
      score += 16;
    }

    return score;
  }

  int _postDrivenSuggestionScore({
    required ProfileEntity candidate,
    required List<PostEntity> currentActivePosts,
  }) {
    if (currentActivePosts.isEmpty) {
      return 0;
    }

    final candidateType = candidate.profileType.value;
    final candidateCity = _normalizeLooseText(candidate.city);
    final candidateLevelRank = _levelRank(candidate.level);
    final candidateInstruments = _normalizeStringSet(
      candidate.instruments ?? const <String>[],
    );
    final candidateGenres = _normalizeStringSet(
      candidate.genres ?? const <String>[],
    );

    var bestScore = 0;
    for (final post in currentActivePosts) {
      if (!_isSuggestionRelevantPost(post)) {
        continue;
      }

      final postType = _normalizeLooseText(post.type);
      final postCity = _normalizeLooseText(post.city);
      final postLevelRank = _levelRank(post.level);
      final postInstruments = _normalizeStringSet(post.instruments);
      final postGenres = _normalizeStringSet(post.genres);
      final postSeekingMusicians = _normalizeStringSet(post.seekingMusicians);

      var score = 0;
      final directInstrumentMatches =
          _intersectionSize(candidateInstruments, postInstruments);
      final requestedInstrumentMatches =
          _intersectionSize(candidateInstruments, postSeekingMusicians);
      final sharedGenres = _intersectionSize(candidateGenres, postGenres);

      score += directInstrumentMatches * 14;
      score += requestedInstrumentMatches * 34;
      score += sharedGenres * 22;

      if (postCity.isNotEmpty && postCity == candidateCity) {
        score += 14;
      }

      if (candidateLevelRank != null && postLevelRank != null) {
        final levelDistance = (candidateLevelRank - postLevelRank).abs();
        if (levelDistance == 0) {
          score += 10;
        } else if (levelDistance == 1) {
          score += 5;
        }
      }

      if (candidateType == 'musician' &&
          (postType == 'band' || postType == 'hiring')) {
        score += 18;
      } else if (candidateType == 'band' && postType == 'musician') {
        score += 18;
      } else if (candidateType == 'space' &&
          (postType == 'venue' || postType == 'event')) {
        score += 16;
      } else if (postType == 'venue' &&
          (candidateType == 'musician' || candidateType == 'band')) {
        score += 12;
      }

      if (requestedInstrumentMatches > 0) {
        score += 20;
      }

      if (score > bestScore) {
        bestScore = score;
      }
    }

    return bestScore;
  }

  String _buildSuggestionReason({
    required ProfileEntity candidate,
    required bool hasPostAffinity,
    required String currentCity,
    required String currentProfileType,
    required String? currentLevel,
    required int? currentLevelRank,
    required int? currentYearsOfExperience,
    required int currentMusicPlatformCount,
    required Set<String> normalizedInstruments,
    required Set<String> normalizedGenres,
    required int commonConnectionsCount,
    required Set<String> chattedProfileIds,
    required Set<String> sentInterestProfileIds,
    required Set<String> receivedInterestProfileIds,
  }) {
    final reasons = <String>[];

    if (hasPostAffinity) {
      reasons.add('combina com seus posts ativos');
    }

    if (chattedProfileIds.contains(candidate.profileId)) {
      reasons.add('ja conversaram');
    }

    if (sentInterestProfileIds.contains(candidate.profileId) ||
        receivedInterestProfileIds.contains(candidate.profileId)) {
      reasons.add('ja houve interesse entre voces');
    }

    if (commonConnectionsCount > 0) {
      reasons.add(
        commonConnectionsCount == 1
            ? '1 conexao em comum'
            : '$commonConnectionsCount conexoes em comum',
      );
    }

    final candidateInstruments = (candidate.instruments ?? const <String>[])
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
    final candidateGenres = (candidate.genres ?? const <String>[])
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
    final sharedInstruments = _intersectionSize(
      normalizedInstruments,
      candidateInstruments,
    );
    final sharedGenres = _intersectionSize(normalizedGenres, candidateGenres);

    if (sharedInstruments > 0) {
      reasons.add(
        sharedInstruments == 1
            ? 'instrumento em comum'
            : '$sharedInstruments instrumentos em comum',
      );
    }

    if (sharedGenres > 0) {
      reasons.add(
        sharedGenres == 1
            ? 'gênero em comum'
            : '$sharedGenres gêneros em comum',
      );
    }

    final candidateLevelRank = _levelRank(candidate.level);
    if (currentLevelRank != null && candidateLevelRank != null) {
      final levelDistance = (currentLevelRank - candidateLevelRank).abs();
      if (levelDistance == 0) {
        reasons.add('nível musical parecido');
      } else if (levelDistance == 1) {
        reasons.add('nível compatível para tocar junto');
      }
    }

    final candidateYearsOfExperience = candidate.ageOrYearsSinceFormation;
    if (candidate.profileType.value == currentProfileType &&
        currentYearsOfExperience != null &&
        candidateYearsOfExperience != null) {
      final yearsDistance =
          (currentYearsOfExperience - candidateYearsOfExperience).abs();
      if (yearsDistance <= 2) {
        reasons.add('momento parecido de carreira');
      } else if (yearsDistance <= 5) {
        reasons.add('projeto em estágio parecido');
      }
    }

    final candidateMusicPlatformCount = _musicPlatformCount(candidate);
    if (currentMusicPlatformCount > 0 && candidateMusicPlatformCount > 0) {
      reasons.add('presença ativa nas plataformas');
    }

    if (currentCity.isNotEmpty && candidate.city.trim() == currentCity) {
      reasons.add('atua em ${candidate.city}');
    }

    if (reasons.isEmpty) {
      final candidateProfileType = candidate.profileType.value;
      if (currentLevel?.trim().isNotEmpty == true &&
          candidate.level?.trim().isNotEmpty == true) {
        return 'perfil com nível musical compatível com o seu';
      }
      if (candidateProfileType == currentProfileType) {
        return 'perfil com contexto musical parecido com o seu';
      }
      if ((currentProfileType == 'musician' &&
              candidateProfileType == 'band') ||
          (currentProfileType == 'band' &&
              candidateProfileType == 'musician')) {
        return 'combinação promissora entre músico e banda';
      }
      return 'perfil próximo ao seu contexto musical';
    }

    return reasons.take(2).join(' • ');
  }

  int _intersectionSize(Set<String> left, Set<String> right) {
    if (left.isEmpty || right.isEmpty) {
      return 0;
    }

    return left.intersection(right).length;
  }

  int? _levelRank(String? level) {
    final normalizedLevel = _normalizeLooseText(level);
    switch (normalizedLevel) {
      case 'iniciante':
      case 'beginner':
        return 1;
      case 'intermediario':
      case 'intermediate':
        return 2;
      case 'avancado':
      case 'advanced':
        return 3;
      case 'profissional':
      case 'professional':
        return 4;
      default:
        return null;
    }
  }

  int _musicPlatformCount(ProfileEntity profile) {
    final platformLinks = <String?>[
      profile.spotifyLink,
      profile.youtubeLink,
      profile.deezerLink,
    ];

    return platformLinks
        .where((link) => link != null && link.trim().isNotEmpty)
        .length;
  }

  Future<List<PostEntity>> _loadActivePostsByAuthorProfileId({
    required String profileId,
    int limit = 12,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    final snapshot = await _firestore
        .collection('posts')
        .where('authorProfileId', isEqualTo: profileId)
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map(PostEntity.fromFirestore)
        .where((post) => !post.isExpired && _isSuggestionRelevantPost(post))
        .toList(growable: false);
  }

  String _suggestionsContextSignature(List<PostEntity> currentActivePosts) {
    if (currentActivePosts.isEmpty) {
      return 'no-active-posts';
    }

    final parts = currentActivePosts
        .map((post) => '${post.id}:${post.createdAt.millisecondsSinceEpoch}')
        .toList()
      ..sort();
    return parts.join('|');
  }

  bool _isSuggestionRelevantPost(PostEntity post) {
    return _normalizeLooseText(post.type) != 'sales';
  }

  Set<String> _normalizeStringSet(List<String> values) {
    return values
        .map(_normalizeLooseText)
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  bool _hasValidGeoPoint(GeoPoint point) {
    return point.latitude != 0 || point.longitude != 0;
  }

  String _normalizeLooseText(String? value) {
    return (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c');
  }

  bool _allowsConnectionSuggestions(ProfileEntity candidate) {
    return candidate.allowConnectionSuggestions;
  }

  bool _allowsConnectionRequests(ProfileEntity candidate) {
    return candidate.allowConnectionRequests;
  }

  Future<void> _assertRecipientAllowsConnectionRequests({
    required String recipientProfileId,
  }) async {
    final recipientProfile =
        await _loadAvailableProfileById(recipientProfileId);
    if (recipientProfile == null) {
      throw StateError('Este perfil nao esta disponivel para conexoes agora.');
    }

    if (!recipientProfile.allowConnectionRequests) {
      throw StateError('Este perfil nao esta aceitando novos convites agora.');
    }
  }

  Future<void> _enforceRequestRateLimit({
    required String requesterProfileId,
    required String requesterUid,
  }) async {
    final since = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 24)),
    );
    final snapshot = await _requestsRef
        .where('requesterProfileId', isEqualTo: requesterProfileId)
        .where('requesterUid', isEqualTo: requesterUid)
        .where('createdAt', isGreaterThanOrEqualTo: since)
        .limit(_dailyRequestLimit)
        .get();

    if (snapshot.docs.length >= _dailyRequestLimit) {
      throw StateError(
        'Voce atingiu o limite diario de convites. Tente novamente amanha.',
      );
    }
  }

  void _assertCooldownSatisfied({
    required Map<String, dynamic>? data,
    required String requesterProfileId,
    required String recipientProfileId,
  }) {
    final requestData = data ?? <String, dynamic>{};
    final status = connectionRequestStatusFromString(
      requestData['status'] as String? ?? '',
    );
    if (status == ConnectionRequestStatus.pending) {
      return;
    }

    final lastActionAt = _parseNullableDate(
          requestData['respondedAt'] ??
              requestData['updatedAt'] ??
              requestData['createdAt'],
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final cooldownUntil = lastActionAt.add(_requestCooldown);
    final attemptCount = _currentRequestAttemptCount(requestData);
    if (cooldownUntil.isAfter(DateTime.now()) &&
        attemptCount >= _requestAttemptsBeforeCooldown) {
      throw StateError(
        'Aguarde alguns dias antes de enviar outro convite para este perfil.',
      );
    }
  }

  int _nextRequestAttemptCount({
    required Map<String, dynamic>? currentData,
  }) {
    final requestData = currentData ?? <String, dynamic>{};
    final lastActionAt = _lastRequestActionAt(requestData);

    if (lastActionAt == null ||
        lastActionAt.add(_requestCooldown).isBefore(DateTime.now())) {
      return 1;
    }

    return _currentRequestAttemptCount(requestData) + 1;
  }

  int _currentRequestAttemptCount(Map<String, dynamic> requestData) {
    final storedCount = (requestData['requestAttemptCount'] as num?)?.toInt();
    if (storedCount != null && storedCount > 0) {
      return storedCount;
    }

    if (requestData.isEmpty) {
      return 0;
    }

    return 1;
  }

  Map<String, dynamic>? _mergeRequestHistory({
    required Map<String, dynamic>? primaryData,
    required Map<String, dynamic>? secondaryData,
  }) {
    final primaryRequestData = primaryData ?? <String, dynamic>{};
    final secondaryRequestData = secondaryData ?? <String, dynamic>{};

    if (primaryRequestData.isEmpty && secondaryRequestData.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    final primaryLastActionAt = _lastRequestActionAt(primaryRequestData);
    final secondaryLastActionAt = _lastRequestActionAt(secondaryRequestData);
    final primaryAttemptCount = _activeRequestAttemptCount(
      requestData: primaryRequestData,
      lastActionAt: primaryLastActionAt,
      now: now,
    );
    final secondaryAttemptCount = _activeRequestAttemptCount(
      requestData: secondaryRequestData,
      lastActionAt: secondaryLastActionAt,
      now: now,
    );

    final hasPrimaryHistory = primaryLastActionAt != null;
    final hasSecondaryHistory = secondaryLastActionAt != null;
    final latestRequestData =
        switch ((hasPrimaryHistory, hasSecondaryHistory)) {
      (true, true) => primaryLastActionAt!.isBefore(secondaryLastActionAt!)
          ? secondaryRequestData
          : primaryRequestData,
      (true, false) => primaryRequestData,
      (false, true) => secondaryRequestData,
      (false, false) => primaryRequestData.isNotEmpty
          ? primaryRequestData
          : secondaryRequestData,
    };

    return {
      ...latestRequestData,
      'requestAttemptCount': primaryAttemptCount >= secondaryAttemptCount
          ? primaryAttemptCount
          : secondaryAttemptCount,
    };
  }

  int _activeRequestAttemptCount({
    required Map<String, dynamic> requestData,
    required DateTime? lastActionAt,
    required DateTime now,
  }) {
    if (requestData.isEmpty || lastActionAt == null) {
      return 0;
    }

    if (lastActionAt.add(_requestCooldown).isBefore(now)) {
      return 0;
    }

    return _currentRequestAttemptCount(requestData);
  }

  DateTime? _lastRequestActionAt(Map<String, dynamic> requestData) {
    if (requestData.isEmpty) {
      return null;
    }

    return _parseNullableDate(
      requestData['respondedAt'] ??
          requestData['updatedAt'] ??
          requestData['createdAt'],
    );
  }

  DateTime? _parseNullableDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  Future<List<ConnectionSuggestionEntity>?> _loadSuggestionsFromCache({
    required String profileId,
    required String profileUid,
    required Set<String> excludedProfileIds,
    required Set<String> connectedProfileIds,
    required Set<String> pendingProfileIds,
    required String contextSignature,
    required int limit,
  }) async {
    final snapshot = await _suggestionsRef.doc(profileId).get();
    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    final cacheVersion = (data['version'] as num?)?.toInt() ?? 1;
    if (cacheVersion != _suggestionsCacheVersion) {
      return null;
    }

    final cachedContextSignature = data['contextSignature'] as String? ?? '';
    if (cachedContextSignature != contextSignature) {
      return null;
    }

    final updatedAt = data['updatedAt'];
    DateTime? lastUpdated;
    if (updatedAt is Timestamp) {
      lastUpdated = updatedAt.toDate();
    } else if (updatedAt is DateTime) {
      lastUpdated = updatedAt;
    }

    if (lastUpdated == null ||
        DateTime.now().difference(lastUpdated) > _suggestionsCacheTtl) {
      return null;
    }

    final rawSuggestions =
        (data['suggestions'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
    if (rawSuggestions.isEmpty) {
      return const <ConnectionSuggestionEntity>[];
    }

    final candidateIds = rawSuggestions
        .map((item) => item['profileId'] as String? ?? '')
        .where((candidateId) =>
            candidateId.isNotEmpty &&
            !excludedProfileIds.contains(candidateId) &&
            !connectedProfileIds.contains(candidateId) &&
            !pendingProfileIds.contains(candidateId) &&
            candidateId != profileId)
        .take(limit)
        .toList(growable: false);
    if (candidateIds.length < limit) {
      return null;
    }

    if (candidateIds.isEmpty) {
      return const <ConnectionSuggestionEntity>[];
    }

    final profilesById = await _loadProfilesByIds(candidateIds);
    final suggestions = <ConnectionSuggestionEntity>[];
    for (final rawSuggestion in rawSuggestions) {
      final candidateId = rawSuggestion['profileId'] as String? ?? '';
      final profile = profilesById[candidateId];
      if (profile == null || profile.uid == profileUid) {
        continue;
      }

      suggestions.add(
        ConnectionSuggestionEntity(
          profile: profile,
          score: (rawSuggestion['score'] as num?)?.toInt() ?? 0,
          reason: rawSuggestion['reason'] as String? ?? '',
          commonConnectionsCount:
              (rawSuggestion['commonConnectionsCount'] as num?)?.toInt() ?? 0,
        ),
      );

      if (suggestions.length >= limit) {
        break;
      }
    }

    return suggestions;
  }

  Future<void> _storeSuggestionsInCache({
    required String profileId,
    required String contextSignature,
    required List<ConnectionSuggestionEntity> suggestions,
  }) async {
    await _suggestionsRef.doc(profileId).set({
      'profileId': profileId,
      'version': _suggestionsCacheVersion,
      'contextSignature': contextSignature,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'suggestions': suggestions
          .map(
            (suggestion) => {
              'profileId': suggestion.profile.profileId,
              'score': suggestion.score,
              'reason': suggestion.reason,
              'commonConnectionsCount': suggestion.commonConnectionsCount,
            },
          )
          .toList(growable: false),
    });
  }

  Future<Map<String, ProfileEntity>> _loadProfilesByIds(
    List<String> profileIds,
  ) async {
    final normalizedIds = profileIds.toSet().toList(growable: false);
    final profileMap = <String, ProfileEntity>{};

    final missingIds = <String>[];
    for (final profileId in normalizedIds) {
      final cached = _readAvailableProfileFromCache(profileId);
      if (cached != null) {
        profileMap[profileId] = cached;
        continue;
      }

      if (_availableProfileCache.containsKey(profileId)) {
        continue;
      }

      missingIds.add(profileId);
    }

    for (var start = 0; start < missingIds.length; start += 10) {
      final end =
          (start + 10 < missingIds.length) ? start + 10 : missingIds.length;
      final chunk = missingIds.sublist(start, end);
      final snapshot = await _firestore
          .collection('profiles')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      final fetchedIds = <String>{};
      for (final doc in snapshot.docs) {
        fetchedIds.add(doc.id);
        final profile = ProfileEntity.fromFirestore(doc);
        if (!_isProfileAvailable(profile)) {
          _storeAvailableProfileInCache(doc.id, null);
          continue;
        }

        _storeAvailableProfileInCache(doc.id, profile);
        profileMap[doc.id] = profile;
      }

      for (final profileId in chunk) {
        if (!fetchedIds.contains(profileId)) {
          _storeAvailableProfileInCache(profileId, null);
        }
      }
    }

    return profileMap;
  }

  Future<ProfileEntity?> _loadAvailableProfileById(String profileId) async {
    final normalizedProfileId = profileId.trim();
    if (normalizedProfileId.isEmpty) {
      return null;
    }

    final cachedProfile = _readAvailableProfileFromCache(normalizedProfileId);
    if (cachedProfile != null ||
        _availableProfileCache.containsKey(normalizedProfileId)) {
      return cachedProfile;
    }

    final snapshot =
        await _firestore.collection('profiles').doc(normalizedProfileId).get();
    if (!snapshot.exists) {
      _storeAvailableProfileInCache(normalizedProfileId, null);
      return null;
    }

    final profile = ProfileEntity.fromFirestore(snapshot);
    if (!_isProfileAvailable(profile)) {
      _storeAvailableProfileInCache(normalizedProfileId, null);
      return null;
    }

    _storeAvailableProfileInCache(normalizedProfileId, profile);

    return profile;
  }

  Stream<List<PostEntity>> _watchNetworkActivityForConnectedProfiles({
    required String profileId,
    required List<String> connectedProfileIds,
    required int limit,
  }) {
    if (connectedProfileIds.isEmpty) {
      return Stream.value(const <PostEntity>[]);
    }

    final connectedProfileChunks = _chunkProfileIds(connectedProfileIds);
    final now = Timestamp.fromDate(DateTime.now());
    final postStreams = connectedProfileChunks.map(
      (chunk) => _firestore
          .collection('posts')
          .where('authorProfileId', whereIn: chunk)
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots(),
    );

    return Rx.combineLatestList(postStreams).asyncMap((snapshots) async {
      final postsById = <String, PostEntity>{};
      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          final post = PostEntity.fromFirestore(doc);
          if (post.authorProfileId.trim().isEmpty || post.isExpired) {
            continue;
          }
          postsById[post.id] = post;
        }
      }

      if (postsById.isEmpty) {
        return const <PostEntity>[];
      }

      final currentProfile = await _loadAvailableProfileById(profileId);
      final currentLocation = currentProfile?.location;
      final hasCurrentLocation =
          currentLocation != null && _hasValidGeoPoint(currentLocation);
      final availableProfilesById = await _loadProfilesByIds(
        postsById.values
            .map((post) => post.authorProfileId)
            .toSet()
            .toList(growable: false),
      );

      final enrichedPosts = postsById.values
          .where(
        (post) => availableProfilesById.containsKey(post.authorProfileId),
      )
          .map((post) {
        final authorProfile = availableProfilesById[post.authorProfileId]!;
        final distanceKm =
            hasCurrentLocation && _hasValidGeoPoint(post.location)
                ? calculateDistanceBetweenGeoPoints(
                    currentLocation,
                    post.location,
                  )
                : post.distanceKm;
        return post.copyWith(
          authorName: post.authorName ?? authorProfile.name,
          authorPhotoUrl: post.authorPhotoUrl ?? authorProfile.photoUrl,
          distanceKm: distanceKm,
        );
      }).toList(growable: false);

      enrichedPosts.sort(
        (left, right) {
          final distanceCompare =
              (left.distanceKm ?? double.infinity).compareTo(
            right.distanceKm ?? double.infinity,
          );
          if (distanceCompare != 0) {
            return distanceCompare;
          }

          return right.createdAt.compareTo(left.createdAt);
        },
      );

      return enrichedPosts.take(limit).toList(growable: false);
    });
  }

  List<String> _normalizedConnectedProfileIds(
    List<ConnectionEntity> connections,
    String currentProfileId,
  ) {
    final connectedProfileIds = connections
        .map((connection) =>
            connection.getOtherProfileId(currentProfileId).trim())
        .where((otherProfileId) => otherProfileId.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();

    return connectedProfileIds;
  }

  bool _sameProfileIdList(List<String> previous, List<String> next) {
    if (identical(previous, next)) {
      return true;
    }

    if (previous.length != next.length) {
      return false;
    }

    for (var index = 0; index < previous.length; index++) {
      if (previous[index] != next[index]) {
        return false;
      }
    }

    return true;
  }

  ProfileEntity? _readAvailableProfileFromCache(String profileId) {
    final cached = _availableProfileCache[profileId];
    if (cached == null) {
      return null;
    }

    if (DateTime.now().difference(cached.fetchedAt) >
        _availableProfileCacheTtl) {
      _availableProfileCache.remove(profileId);
      return null;
    }

    return cached.profile;
  }

  void _storeAvailableProfileInCache(
    String profileId,
    ProfileEntity? profile,
  ) {
    _availableProfileCache[profileId] = _CachedAvailableProfile(
      fetchedAt: DateTime.now(),
      profile: profile,
    );
  }

  List<List<String>> _chunkProfileIds(
    List<String> profileIds, {
    int chunkSize = 10,
  }) {
    final chunks = <List<String>>[];
    for (var index = 0; index < profileIds.length; index += chunkSize) {
      final end = (index + chunkSize < profileIds.length)
          ? index + chunkSize
          : profileIds.length;
      chunks.add(profileIds.sublist(index, end));
    }
    return chunks;
  }

  Future<ProfileEntity> _requireAvailableProfile({
    required String profileId,
    required String unavailableMessage,
  }) async {
    final profile = await _loadAvailableProfileById(profileId);
    if (profile == null) {
      throw StateError(unavailableMessage);
    }

    return profile;
  }

  bool _isProfileAvailable(ProfileEntity profile) {
    return profile.profileId.trim().isNotEmpty &&
        profile.uid.trim().isNotEmpty &&
        profile.name.trim().isNotEmpty;
  }

  bool _hasAvailableConnectionCounterpart(
    ConnectionEntity connection, {
    required String currentProfileId,
  }) {
    final otherProfileId =
        connection.getOtherProfileId(currentProfileId).trim();
    final otherProfileUid =
        connection.getOtherProfileUid(currentProfileId).trim();
    final otherProfileName =
        connection.getOtherProfileName(currentProfileId).trim();

    return otherProfileId.isNotEmpty &&
        otherProfileUid.isNotEmpty &&
        otherProfileName.isNotEmpty;
  }

  bool _hasAvailableRequestCounterpart(
    ConnectionRequestEntity request, {
    required bool isReceived,
  }) {
    final counterpartProfileId = isReceived
        ? request.requesterProfileId.trim()
        : request.recipientProfileId.trim();
    final counterpartUid =
        isReceived ? request.requesterUid.trim() : request.recipientUid.trim();
    final counterpartName = isReceived
        ? request.requesterName.trim()
        : request.recipientName.trim();

    return counterpartProfileId.isNotEmpty &&
        counterpartUid.isNotEmpty &&
        counterpartName.isNotEmpty;
  }

  Future<void> _assertProfilesNotBlocked({
    required String profileId,
    required String otherProfileId,
    required String uid,
  }) async {
    if (await _areProfilesBlocked(
      profileId: profileId,
      otherProfileId: otherProfileId,
      uid: uid,
    )) {
      throw StateError('Conexao indisponivel entre esses perfis.');
    }
  }

  Future<bool> _areProfilesBlocked({
    required String profileId,
    required String otherProfileId,
    required String uid,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return false;
    }

    final excludedProfileIds = await BlockedRelations.getExcludedProfileIds(
      firestore: _firestore,
      profileId: profileId,
      uid: normalizedUid,
    );
    return excludedProfileIds.contains(otherProfileId);
  }
}
