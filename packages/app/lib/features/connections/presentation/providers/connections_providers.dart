import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wegig_app/config/app_config.dart';

import '../../data/datasources/connections_remote_datasource.dart';
import '../../data/repositories/connections_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/connections_repository.dart';
import '../../domain/usecases/usecases.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

part 'connections_providers.g.dart';

const int _visibleConnectionSuggestionsLimit = 6;
const int _connectionSuggestionsFetchBuffer = 6;
const int _maxConnectionSuggestionsFetchLimit = 60;
const int _filteredConnectionSuggestionsFetchLimit = 60;
const int myConnectionsOverviewPreviewLimit = 4;
const int networkActivityOverviewPreviewLimit = 3;
const int myConnectionsPageSize = 20;
const int networkActivityPageSize = 20;
const String _myNetworkBadgeSeenAtKeyPrefix = 'my_network_badge_seen_at_v1';
const String _myNetworkBadgeSeenAtField = 'myNetworkBadgeSeenAt';

enum SuggestionLocationFilter {
  any,
  sameCity,
}

enum SuggestionCommonConnectionFilter {
  any,
  withCommonConnections,
}

enum SuggestionSortOption {
  relevance,
  commonConnections,
  recent,
}

class ConnectionSuggestionFiltersState {
  ConnectionSuggestionFiltersState({
    Set<String>? selectedInstruments,
    Set<String>? selectedGenres,
    Set<String>? selectedProfileTypeValues,
    this.locationFilter = SuggestionLocationFilter.any,
    this.commonConnectionFilter = SuggestionCommonConnectionFilter.any,
    this.sortOption = SuggestionSortOption.relevance,
  })  : selectedInstruments = selectedInstruments ?? <String>{},
        selectedGenres = selectedGenres ?? <String>{},
        selectedProfileTypeValues = selectedProfileTypeValues ?? <String>{};

  final Set<String> selectedInstruments;
  final Set<String> selectedGenres;
  final Set<String> selectedProfileTypeValues;
  final SuggestionLocationFilter locationFilter;
  final SuggestionCommonConnectionFilter commonConnectionFilter;
  final SuggestionSortOption sortOption;

  bool get hasAnyFilterActive {
    return selectedInstruments.isNotEmpty ||
        selectedGenres.isNotEmpty ||
        selectedProfileTypeValues.isNotEmpty ||
        locationFilter != SuggestionLocationFilter.any ||
        commonConnectionFilter != SuggestionCommonConnectionFilter.any ||
        sortOption != SuggestionSortOption.relevance;
  }

  ConnectionSuggestionFiltersState copyWith({
    Set<String>? selectedInstruments,
    Set<String>? selectedGenres,
    Set<String>? selectedProfileTypeValues,
    SuggestionLocationFilter? locationFilter,
    SuggestionCommonConnectionFilter? commonConnectionFilter,
    SuggestionSortOption? sortOption,
  }) {
    return ConnectionSuggestionFiltersState(
      selectedInstruments: selectedInstruments ?? this.selectedInstruments,
      selectedGenres: selectedGenres ?? this.selectedGenres,
      selectedProfileTypeValues:
          selectedProfileTypeValues ?? this.selectedProfileTypeValues,
      locationFilter: locationFilter ?? this.locationFilter,
      commonConnectionFilter:
          commonConnectionFilter ?? this.commonConnectionFilter,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

final connectionSuggestionFiltersProvider = NotifierProvider<
    ConnectionSuggestionFiltersNotifier,
    ConnectionSuggestionFiltersState>(ConnectionSuggestionFiltersNotifier.new);

class ConnectionSuggestionFiltersNotifier
    extends Notifier<ConnectionSuggestionFiltersState> {
  @override
  ConnectionSuggestionFiltersState build() {
    ref.watch(activeProfileProvider);
    return ConnectionSuggestionFiltersState();
  }

  void update(
    ConnectionSuggestionFiltersState next,
  ) {
    state = ConnectionSuggestionFiltersState(
      selectedInstruments: {...next.selectedInstruments},
      selectedGenres: {...next.selectedGenres},
      selectedProfileTypeValues: {...next.selectedProfileTypeValues},
      locationFilter: next.locationFilter,
      commonConnectionFilter: next.commonConnectionFilter,
      sortOption: next.sortOption,
    );
  }

  void clear() {
    state = ConnectionSuggestionFiltersState();
  }
}

@riverpod
FirebaseFirestore connectionsFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

@riverpod
IConnectionsRemoteDataSource connectionsRemoteDataSource(Ref ref) {
  final firestore = ref.watch(connectionsFirestoreProvider);
  return ConnectionsRemoteDataSource(firestore: firestore);
}

@riverpod
ConnectionsRepository connectionsRepository(Ref ref) {
  final remoteDataSource = ref.watch(connectionsRemoteDataSourceProvider);
  return ConnectionsRepositoryImpl(remoteDataSource: remoteDataSource);
}

@riverpod
SendConnectionRequestUseCase sendConnectionRequestUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return SendConnectionRequestUseCase(repository);
}

@riverpod
AcceptConnectionRequestUseCase acceptConnectionRequestUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return AcceptConnectionRequestUseCase(repository);
}

@riverpod
DeclineConnectionRequestUseCase declineConnectionRequestUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return DeclineConnectionRequestUseCase(repository);
}

@riverpod
CancelConnectionRequestUseCase cancelConnectionRequestUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return CancelConnectionRequestUseCase(repository);
}

@riverpod
RemoveConnectionUseCase removeConnectionUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return RemoveConnectionUseCase(repository);
}

@riverpod
LoadMyConnectionsUseCase loadMyConnectionsUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return LoadMyConnectionsUseCase(repository);
}

@riverpod
LoadConnectionsPageUseCase loadConnectionsPageUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return LoadConnectionsPageUseCase(repository);
}

@riverpod
LoadPendingReceivedRequestsUseCase loadPendingReceivedRequestsUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return LoadPendingReceivedRequestsUseCase(repository);
}

@riverpod
LoadPendingSentRequestsUseCase loadPendingSentRequestsUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return LoadPendingSentRequestsUseCase(repository);
}

@riverpod
LoadConnectionStatsUseCase loadConnectionStatsUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return LoadConnectionStatsUseCase(repository);
}

@riverpod
LoadNetworkActivityUseCase loadNetworkActivityUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return LoadNetworkActivityUseCase(repository);
}

@riverpod
LoadNetworkActivityPageUseCase loadNetworkActivityPageUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return LoadNetworkActivityPageUseCase(repository);
}

@riverpod
LoadCommonConnectionsUseCase loadCommonConnectionsUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return LoadCommonConnectionsUseCase(repository);
}

@riverpod
LoadConnectionSuggestionsUseCase loadConnectionSuggestionsUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return LoadConnectionSuggestionsUseCase(repository);
}

@riverpod
GetConnectionStatusUseCase getConnectionStatusUseCase(Ref ref) {
  final repository = ref.watch(connectionsRepositoryProvider);
  return GetConnectionStatusUseCase(repository);
}

@riverpod
Stream<List<ConnectionEntity>> myConnectionsStream(
  Ref ref, {
  required String profileId,
  required String profileUid,
  int limit = 50,
}) {
  final useCase = ref.watch(loadMyConnectionsUseCaseProvider);
  return useCase(profileId: profileId, profileUid: profileUid, limit: limit);
}

@riverpod
Stream<List<ConnectionEntity>> myConnectionsOverviewPreviewStream(
  Ref ref, {
  required String profileId,
  required String profileUid,
}) {
  final useCase = ref.watch(loadMyConnectionsUseCaseProvider);
  return useCase(
    profileId: profileId,
    profileUid: profileUid,
    limit: myConnectionsOverviewPreviewLimit,
  );
}

@riverpod
Stream<List<ConnectionRequestEntity>> pendingReceivedRequestsStream(
  Ref ref, {
  required String profileId,
  required String profileUid,
  int limit = 25,
}) {
  final useCase = ref.watch(loadPendingReceivedRequestsUseCaseProvider);
  return useCase(profileId: profileId, profileUid: profileUid, limit: limit);
}

@riverpod
Stream<List<ConnectionRequestEntity>> pendingSentRequestsStream(
  Ref ref, {
  required String profileId,
  required String profileUid,
  int limit = 25,
}) {
  final useCase = ref.watch(loadPendingSentRequestsUseCaseProvider);
  return useCase(profileId: profileId, profileUid: profileUid, limit: limit);
}

@riverpod
Stream<ConnectionStatsEntity> connectionStatsStream(
  Ref ref,
  String profileId,
) {
  final useCase = ref.watch(loadConnectionStatsUseCaseProvider);
  return useCase(profileId: profileId);
}

@Riverpod(keepAlive: true)
class NetworkBadgeSeenAt extends _$NetworkBadgeSeenAt {
  @override
  Future<DateTime?> build(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final localMillis = prefs.getInt(_badgeSeenAtKey(profileId));
    final localSeenAt = localMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(localMillis)
        : null;

    DateTime? remoteSeenAt;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(profileId)
          .get(const GetOptions(source: Source.server));
      remoteSeenAt =
          _parseTimestamp(snapshot.data()?[_myNetworkBadgeSeenAtField]);
    } catch (_) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(profileId)
            .get(const GetOptions(source: Source.cache));
        remoteSeenAt =
            _parseTimestamp(snapshot.data()?[_myNetworkBadgeSeenAtField]);
      } catch (_) {
        remoteSeenAt = null;
      }
    }

    final resolvedSeenAt = _latestDate(localSeenAt, remoteSeenAt);
    if (resolvedSeenAt != null &&
        resolvedSeenAt.millisecondsSinceEpoch != localMillis) {
      await prefs.setInt(
        _badgeSeenAtKey(profileId),
        resolvedSeenAt.millisecondsSinceEpoch,
      );
    }

    return resolvedSeenAt;
  }

  Future<void> markSeen() async {
    final now = DateTime.now();
    state = AsyncData(now);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _badgeSeenAtKey(profileId),
      now.millisecondsSinceEpoch,
    );

    try {
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(profileId)
          .set({
        _myNetworkBadgeSeenAtField: Timestamp.fromDate(now),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint(
        '⚠️ NetworkBadgeSeenAt: failed to persist remote seenAt for $profileId: $error',
      );
    }
  }

  String _badgeSeenAtKey(String profileId) {
    return '$_myNetworkBadgeSeenAtKeyPrefix:$profileId';
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  DateTime? _latestDate(DateTime? first, DateTime? second) {
    if (first == null) {
      return second;
    }
    if (second == null) {
      return first;
    }
    return first.isAfter(second) ? first : second;
  }
}

@riverpod
Stream<int> networkBadgeCountStream(
  Ref ref, {
  required String profileId,
  required String recipientUid,
  int? seenAtMillis,
}) {
  final loadPendingReceived =
      ref.watch(loadPendingReceivedRequestsUseCaseProvider);
  final loadConnections = ref.watch(loadMyConnectionsUseCaseProvider);

  if (recipientUid.trim().isEmpty) {
    return Stream.value(0);
  }

  final seenAt = seenAtMillis != null
      ? DateTime.fromMillisecondsSinceEpoch(seenAtMillis)
      : null;

  final pendingReceivedStream = loadPendingReceived(
    profileId: profileId,
    profileUid: recipientUid,
  );
  final connectionsStream = loadConnections(
    profileId: profileId,
    profileUid: recipientUid,
  );

  return Rx.combineLatest2(
    pendingReceivedStream,
    connectionsStream,
    (
      List<ConnectionRequestEntity> pendingRequests,
      List<ConnectionEntity> connections,
    ) {
      final pendingReceivedCount = pendingRequests.where((request) {
        return _isAfterSeenDate(request.createdAt, seenAt);
      }).length;
      final newlyAcceptedOutgoingCount = connections.where((connection) {
        if (connection.initiatedByProfileId != profileId) {
          return false;
        }

        return _isAfterSeenDate(connection.createdAt, seenAt);
      }).length;

      return pendingReceivedCount + newlyAcceptedOutgoingCount;
    },
  ).distinct();
}

@riverpod
Stream<List<PostEntity>> networkActivityStream(
  Ref ref, {
  required String profileId,
  required String profileUid,
  int limit = 10,
}) {
  final useCase = ref.watch(loadNetworkActivityUseCaseProvider);
  return useCase(
    profileId: profileId,
    profileUid: profileUid,
    limit: limit,
  );
}

@riverpod
Stream<List<PostEntity>> networkActivityOverviewPreviewStream(
  Ref ref, {
  required String profileId,
  required String profileUid,
}) {
  final useCase = ref.watch(loadNetworkActivityUseCaseProvider);
  return useCase(
    profileId: profileId,
    profileUid: profileUid,
    limit: networkActivityOverviewPreviewLimit,
  );
}

@riverpod
Future<List<CommonConnectionEntity>> commonConnections(
  Ref ref, {
  required String profileId,
  required String profileUid,
  required String otherProfileId,
  required String otherProfileUid,
  int limit = 3,
}) {
  final useCase = ref.watch(loadCommonConnectionsUseCaseProvider);
  return useCase(
    profileId: profileId,
    profileUid: profileUid,
    otherProfileId: otherProfileId,
    otherProfileUid: otherProfileUid,
    limit: limit,
  );
}

@riverpod
Future<List<ConnectionSuggestionEntity>> connectionSuggestions(Ref ref) async {
  final activeProfile = ref.watch(activeProfileProvider);
  if (activeProfile == null) {
    return const <ConnectionSuggestionEntity>[];
  }
  final suggestionFilters = ref.watch(connectionSuggestionFiltersProvider);
  final excludedProfileIds =
      ref.watch(connectionSuggestionExcludedProfileIdsProvider);

  final hasProfileTypeFilter =
      suggestionFilters.selectedProfileTypeValues.isNotEmpty;
  final requestedLimit = hasProfileTypeFilter
      ? _filteredConnectionSuggestionsFetchLimit
      : (_visibleConnectionSuggestionsLimit +
              _connectionSuggestionsFetchBuffer)
          .clamp(
          _visibleConnectionSuggestionsLimit,
          _maxConnectionSuggestionsFetchLimit,
        );

  final useCase = ref.watch(loadConnectionSuggestionsUseCaseProvider);
  final suggestions = await useCase(
    profileId: activeProfile.profileId,
    profileUid: activeProfile.uid,
    currentCity: activeProfile.city,
    currentProfileType: activeProfile.profileType.value,
    currentLevel: activeProfile.level,
    currentInstruments: activeProfile.instruments ?? const <String>[],
    currentGenres: activeProfile.genres ?? const <String>[],
    limit: requestedLimit,
  );

  return suggestions
      .where(
        (suggestion) => !excludedProfileIds.contains(
          suggestion.profile.profileId,
        ),
      )
      .toList(growable: false);
}

@riverpod
Set<String> connectionSuggestionExcludedProfileIds(Ref ref) {
  final activeProfile = ref.watch(activeProfileProvider);
  if (activeProfile == null) {
    return <String>{};
  }

  final connections = ref
          .watch(
            myConnectionsStreamProvider(
              profileId: activeProfile.profileId,
              profileUid: activeProfile.uid,
            ),
          )
          .valueOrNull ??
      const <ConnectionEntity>[];
  final pendingSentRequests = ref
          .watch(
            pendingSentRequestsStreamProvider(
              profileId: activeProfile.profileId,
              profileUid: activeProfile.uid,
            ),
          )
          .valueOrNull ??
      const <ConnectionRequestEntity>[];
  final pendingReceivedRequests = ref
          .watch(
            pendingReceivedRequestsStreamProvider(
              profileId: activeProfile.profileId,
              profileUid: activeProfile.uid,
            ),
          )
          .valueOrNull ??
      const <ConnectionRequestEntity>[];
  final optimisticStatuses = ref.watch(optimisticConnectionStatusesProvider);

  final excludedProfileIds = <String>{activeProfile.profileId};

  for (final connection in connections) {
    final otherProfileId =
        connection.getOtherProfileId(activeProfile.profileId);
    if (otherProfileId.isNotEmpty) {
      excludedProfileIds.add(otherProfileId);
    }
  }

  for (final request in pendingSentRequests) {
    if (request.recipientProfileId.isNotEmpty) {
      excludedProfileIds.add(request.recipientProfileId);
    }
  }

  for (final request in pendingReceivedRequests) {
    if (request.requesterProfileId.isNotEmpty) {
      excludedProfileIds.add(request.requesterProfileId);
    }
  }

  for (final entry in optimisticStatuses.entries) {
    if (entry.value.status != ConnectionRelationshipStatus.none) {
      excludedProfileIds.add(entry.key);
    }
  }

  return excludedProfileIds;
}

@riverpod
Future<ConnectionStatusEntity> connectionStatus(
  Ref ref,
  String otherProfileId,
) async {
  final activeProfile = ref.watch(activeProfileProvider);
  if (activeProfile == null) {
    return const ConnectionStatusEntity.none();
  }

  final useCase = ref.watch(getConnectionStatusUseCaseProvider);
  return useCase(
    profileId: activeProfile.profileId,
    profileUid: activeProfile.uid,
    otherProfileId: otherProfileId,
  );
}

final optimisticConnectionStatusesProvider = NotifierProvider<
    OptimisticConnectionStatuses,
    Map<String, ConnectionStatusEntity>>(OptimisticConnectionStatuses.new);

class OptimisticConnectionStatuses
    extends Notifier<Map<String, ConnectionStatusEntity>> {
  @override
  Map<String, ConnectionStatusEntity> build() {
    ref.watch(activeProfileProvider);
    return <String, ConnectionStatusEntity>{};
  }

  void setStatus({
    required String profileId,
    required ConnectionStatusEntity status,
  }) {
    state = {
      ...state,
      profileId: status,
    };
  }

  void clearStatus(String profileId) {
    if (!state.containsKey(profileId)) {
      return;
    }

    final nextState = {...state}..remove(profileId);
    state = nextState;
  }
}

final effectiveConnectionStatusProvider =
    Provider.family<AsyncValue<ConnectionStatusEntity>, String>(
  (ref, otherProfileId) {
    final optimisticStatus = ref.watch(
      optimisticConnectionStatusesProvider.select(
        (statuses) => statuses[otherProfileId],
      ),
    );

    if (optimisticStatus != null) {
      return AsyncData(optimisticStatus);
    }

    final activeProfile = ref.watch(activeProfileProvider);
    final fallbackAsync = ref.watch(connectionStatusProvider(otherProfileId));

    if (activeProfile == null) {
      return fallbackAsync;
    }

    final profileId = activeProfile.profileId;
    final profileUid = activeProfile.uid;

    final connectionsAsync = ref.watch(
      myConnectionsStreamProvider(
        profileId: profileId,
        profileUid: profileUid,
      ),
    );
    final pendingSentAsync = ref.watch(
      pendingSentRequestsStreamProvider(
        profileId: profileId,
        profileUid: profileUid,
      ),
    );
    final pendingReceivedAsync = ref.watch(
      pendingReceivedRequestsStreamProvider(
        profileId: profileId,
        profileUid: profileUid,
      ),
    );

    final connections = connectionsAsync.valueOrNull;
    if (connections != null) {
      final match = connections.where(
        (connection) =>
            connection.getOtherProfileId(profileId) == otherProfileId,
      );
      if (match.isNotEmpty) {
        final connection = match.first;
        return AsyncData(
          ConnectionStatusEntity(
            status: ConnectionRelationshipStatus.connected,
            connectionId: connection.id,
            otherProfileId: otherProfileId,
          ),
        );
      }
    }

    final pendingSent = pendingSentAsync.valueOrNull;
    if (pendingSent != null) {
      final match = pendingSent.where(
        (request) =>
            request.recipientProfileId == otherProfileId && request.isPending,
      );
      if (match.isNotEmpty) {
        final request = match.first;
        return AsyncData(
          ConnectionStatusEntity(
            status: ConnectionRelationshipStatus.pendingSent,
            requestId: request.id,
            otherProfileId: otherProfileId,
          ),
        );
      }
    }

    final pendingReceived = pendingReceivedAsync.valueOrNull;
    if (pendingReceived != null) {
      final match = pendingReceived.where(
        (request) =>
            request.requesterProfileId == otherProfileId && request.isPending,
      );
      if (match.isNotEmpty) {
        final request = match.first;
        return AsyncData(
          ConnectionStatusEntity(
            status: ConnectionRelationshipStatus.pendingReceived,
            requestId: request.id,
            otherProfileId: otherProfileId,
          ),
        );
      }
    }

    // Se o fallback (connectionStatusProvider) já tem um valor definitivo,
    // usamos. Mas se ele retornou `none` e algum dos streams ainda NÃO emitiu
    // (AsyncLoading), preferimos `AsyncLoading` para evitar exibir um estado
    // intermediário errado (ex.: logo após enviar um convite, antes do stream
    // atualizar o contador local de pendingSent).
    final streamsStillLoading = connectionsAsync.isLoading ||
        pendingSentAsync.isLoading ||
        pendingReceivedAsync.isLoading;

    final fallbackValue = fallbackAsync.valueOrNull;
    if (fallbackValue != null &&
        fallbackValue.status != ConnectionRelationshipStatus.none) {
      return fallbackAsync;
    }

    if (streamsStillLoading) {
      return const AsyncLoading();
    }

    return fallbackAsync;
  },
);

@riverpod
class DismissedSuggestions extends _$DismissedSuggestions {
  @override
  Set<String> build() {
    ref.watch(activeProfileProvider);
    return <String>{};
  }

  void dismiss(String profileId) {
    state = {...state, profileId};
  }

  void remove(String profileId) {
    if (!state.contains(profileId)) {
      return;
    }

    final nextState = {...state}..remove(profileId);
    state = nextState;
  }

  void clear() {
    if (state.isEmpty) {
      return;
    }

    state = <String>{};
  }
}

@riverpod
class ConnectionsActions extends _$ConnectionsActions {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> sendRequest({
    required ProfileEntity recipientProfile,
  }) async {
    final activeProfile = _requireActiveProfile();
    final recipientProfileId = recipientProfile.profileId;
    final optimisticStatuses =
        ref.read(optimisticConnectionStatusesProvider.notifier);
    optimisticStatuses.setStatus(
      profileId: recipientProfileId,
      status: ConnectionStatusEntity(
        status: ConnectionRelationshipStatus.pendingSent,
        otherProfileId: recipientProfileId,
      ),
    );
    state = const AsyncLoading();

    try {
      await ref.read(sendConnectionRequestUseCaseProvider)(
        requesterProfileId: activeProfile.profileId,
        requesterUid: activeProfile.uid,
        requesterName: activeProfile.name,
        requesterPhotoUrl: activeProfile.photoUrl,
        recipientProfileId: recipientProfile.profileId,
        recipientUid: recipientProfile.uid,
        recipientName: recipientProfile.name,
        recipientPhotoUrl: recipientProfile.photoUrl,
      );
      ref.invalidate(connectionSuggestionsProvider);
      ref.invalidate(connectionStatusProvider(recipientProfileId));

      // Após o envio, confirmamos o status antes de limpar o optimistic.
      // Sem essa confirmação, ao limpar o optimistic o consumidor de
      // `effectiveConnectionStatusProvider` pode cair no fallback
      // (connectionStatusProvider) ainda em AsyncLoading e exibir um estado
      // intermediário incorreto (ex.: botão "Conectar").
      try {
        final refreshed = await ref
            .read(connectionStatusProvider(recipientProfileId).future);
        if (refreshed.status == ConnectionRelationshipStatus.pendingSent ||
            refreshed.status == ConnectionRelationshipStatus.connected) {
          optimisticStatuses.clearStatus(recipientProfileId);
        } else {
          // Safety net: mesmo se o status retornado não for o esperado,
          // limpamos o optimistic após um delay para evitar ficar preso.
          // O stream em tempo real eventualmente converge para o estado real.
          Future<void>.delayed(const Duration(seconds: 5), () {
            optimisticStatuses.clearStatus(recipientProfileId);
          });
        }
      } catch (error, stackTrace) {
        debugPrint(
          '⚠️ [CONNECTIONS] optimistic status refresh failed for '
          '$recipientProfileId: ${error.runtimeType}: $error',
        );
        debugPrint('⚠️ [CONNECTIONS] optimistic status stackTrace: $stackTrace');
        Future<void>.delayed(const Duration(seconds: 5), () {
          optimisticStatuses.clearStatus(recipientProfileId);
        });
      }

      await _logAnalyticsEvent(
        name: 'connection_request_sent',
        parameters: {
          'active_profile_id': activeProfile.profileId,
          'active_profile_type': activeProfile.profileType.value,
          'target_profile_id': recipientProfileId,
          'target_profile_type': recipientProfile.profileType.value,
        },
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint(
          '❌ [CONNECTIONS] sendRequest FAILED: ${error.runtimeType}: $error');
      debugPrint('❌ [CONNECTIONS] stackTrace: $stackTrace');
      await _logAnalyticsEvent(
        name: 'connection_request_send_error',
        parameters: {
          'active_profile_id': activeProfile.profileId,
          'target_profile_id': recipientProfileId,
          'error': error.runtimeType.toString(),
        },
      );
      optimisticStatuses.clearStatus(recipientProfileId);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> acceptRequest({
    required String requestId,
    required String otherProfileId,
  }) async {
    final activeProfile = _requireActiveProfile();
    final optimisticStatuses =
        ref.read(optimisticConnectionStatusesProvider.notifier);
    optimisticStatuses.setStatus(
      profileId: otherProfileId,
      status: ConnectionStatusEntity(
        status: ConnectionRelationshipStatus.connected,
        otherProfileId: otherProfileId,
      ),
    );
    state = const AsyncLoading();

    try {
      await ref.read(acceptConnectionRequestUseCaseProvider)(
        requestId: requestId,
        responderProfileId: activeProfile.profileId,
      );
      ref.invalidate(connectionSuggestionsProvider);
      ref.invalidate(connectionStatusProvider(otherProfileId));
      await _refreshConnectionStatus(otherProfileId);
      await _logAnalyticsEvent(
        name: 'connection_request_accepted',
        parameters: {
          'active_profile_id': activeProfile.profileId,
          'request_id': requestId,
          'target_profile_id': otherProfileId,
        },
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      await _logAnalyticsEvent(
        name: 'connection_request_accept_error',
        parameters: {
          'active_profile_id': activeProfile.profileId,
          'request_id': requestId,
          'target_profile_id': otherProfileId,
          'error': error.runtimeType.toString(),
        },
      );
      state = AsyncError(error, stackTrace);
    } finally {
      optimisticStatuses.clearStatus(otherProfileId);
    }
  }

  Future<void> declineRequest({
    required String requestId,
    required String otherProfileId,
  }) async {
    final activeProfile = _requireActiveProfile();
    final optimisticStatuses =
        ref.read(optimisticConnectionStatusesProvider.notifier);
    optimisticStatuses.setStatus(
      profileId: otherProfileId,
      status: ConnectionStatusEntity(
        status: ConnectionRelationshipStatus.none,
        otherProfileId: otherProfileId,
      ),
    );
    state = const AsyncLoading();

    try {
      await ref.read(declineConnectionRequestUseCaseProvider)(
        requestId: requestId,
        responderProfileId: activeProfile.profileId,
      );
      ref.invalidate(connectionStatusProvider(otherProfileId));
      await _refreshConnectionStatus(otherProfileId);
      await _logAnalyticsEvent(
        name: 'connection_request_declined',
        parameters: {
          'active_profile_id': activeProfile.profileId,
          'request_id': requestId,
          'target_profile_id': otherProfileId,
        },
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      await _logAnalyticsEvent(
        name: 'connection_request_decline_error',
        parameters: {
          'active_profile_id': activeProfile.profileId,
          'request_id': requestId,
          'target_profile_id': otherProfileId,
          'error': error.runtimeType.toString(),
        },
      );
      state = AsyncError(error, stackTrace);
    } finally {
      optimisticStatuses.clearStatus(otherProfileId);
    }
  }

  Future<void> cancelRequest({
    required String requestId,
    required String otherProfileId,
  }) async {
    final activeProfile = _requireActiveProfile();
    final optimisticStatuses =
        ref.read(optimisticConnectionStatusesProvider.notifier);
    optimisticStatuses.setStatus(
      profileId: otherProfileId,
      status: ConnectionStatusEntity(
        status: ConnectionRelationshipStatus.none,
        otherProfileId: otherProfileId,
      ),
    );
    state = const AsyncLoading();

    try {
      await ref.read(cancelConnectionRequestUseCaseProvider)(
        requestId: requestId,
        requesterProfileId: activeProfile.profileId,
      );
      ref.invalidate(connectionStatusProvider(otherProfileId));
      await _refreshConnectionStatus(otherProfileId);
      await _logAnalyticsEvent(
        name: 'connection_request_cancelled',
        parameters: {
          'active_profile_id': activeProfile.profileId,
          'request_id': requestId,
          'target_profile_id': otherProfileId,
        },
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      await _logAnalyticsEvent(
        name: 'connection_request_cancel_error',
        parameters: {
          'active_profile_id': activeProfile.profileId,
          'request_id': requestId,
          'target_profile_id': otherProfileId,
          'error': error.runtimeType.toString(),
        },
      );
      state = AsyncError(error, stackTrace);
    } finally {
      optimisticStatuses.clearStatus(otherProfileId);
    }
  }

  Future<void> removeConnection({
    required String connectionId,
    required String otherProfileId,
  }) async {
    final activeProfile = _requireActiveProfile();
    final optimisticStatuses =
        ref.read(optimisticConnectionStatusesProvider.notifier);
    optimisticStatuses.setStatus(
      profileId: otherProfileId,
      status: ConnectionStatusEntity(
        status: ConnectionRelationshipStatus.none,
        otherProfileId: otherProfileId,
      ),
    );
    state = const AsyncLoading();

    try {
      await ref.read(removeConnectionUseCaseProvider)(
        connectionId: connectionId,
        currentProfileId: activeProfile.profileId,
      );
      ref.invalidate(connectionSuggestionsProvider);
      ref.invalidate(connectionStatusProvider(otherProfileId));
      await _refreshConnectionStatus(otherProfileId);
      await _logAnalyticsEvent(
        name: 'connection_removed',
        parameters: {
          'active_profile_id': activeProfile.profileId,
          'connection_id': connectionId,
          'target_profile_id': otherProfileId,
        },
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      await _logAnalyticsEvent(
        name: 'connection_remove_error',
        parameters: {
          'active_profile_id': activeProfile.profileId,
          'connection_id': connectionId,
          'target_profile_id': otherProfileId,
          'error': error.runtimeType.toString(),
        },
      );
      state = AsyncError(error, stackTrace);
    } finally {
      optimisticStatuses.clearStatus(otherProfileId);
    }
  }

  ProfileEntity _requireActiveProfile() {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) {
      throw StateError('Perfil ativo nao encontrado.');
    }
    return activeProfile;
  }

  Future<void> _refreshConnectionStatus(String otherProfileId) async {
    try {
      await ref.read(connectionStatusProvider(otherProfileId).future);
    } catch (error, stackTrace) {
      debugPrint(
        '⚠️ [CONNECTIONS] optimistic status refresh failed for '
        '$otherProfileId: ${error.runtimeType}: $error',
      );
      debugPrint('⚠️ [CONNECTIONS] optimistic status stackTrace: $stackTrace');
    }
  }

  Future<void> _logAnalyticsEvent({
    required String name,
    required Map<String, Object> parameters,
  }) async {
    if (!AppConfig.enableAnalytics) {
      return;
    }

    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (_) {
      // Analytics failure must not affect the social flow.
    }
  }
}

bool _isAfterSeenDate(DateTime eventAt, DateTime? seenAt) {
  if (seenAt == null) {
    return false;
  }

  return eventAt.isAfter(seenAt);
}
