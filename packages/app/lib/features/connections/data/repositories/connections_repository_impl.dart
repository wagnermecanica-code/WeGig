import 'package:flutter/foundation.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/connections_repository.dart';
import '../datasources/connections_remote_datasource.dart';

class ConnectionsRepositoryImpl implements ConnectionsRepository {
  ConnectionsRepositoryImpl({
    required IConnectionsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final IConnectionsRemoteDataSource _remoteDataSource;

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
    try {
      return await _remoteDataSource.sendConnectionRequest(
        requesterProfileId: requesterProfileId,
        requesterUid: requesterUid,
        requesterName: requesterName,
        requesterPhotoUrl: requesterPhotoUrl,
        recipientProfileId: recipientProfileId,
        recipientUid: recipientUid,
        recipientName: recipientName,
        recipientPhotoUrl: recipientPhotoUrl,
      );
    } catch (error) {
      debugPrint('❌ ConnectionsRepository: erro ao enviar convite - $error');
      rethrow;
    }
  }

  @override
  Future<void> acceptConnectionRequest({
    required String requestId,
    required String responderProfileId,
  }) {
    return _remoteDataSource.acceptConnectionRequest(
      requestId: requestId,
      responderProfileId: responderProfileId,
    );
  }

  @override
  Future<void> declineConnectionRequest({
    required String requestId,
    required String responderProfileId,
  }) {
    return _remoteDataSource.declineConnectionRequest(
      requestId: requestId,
      responderProfileId: responderProfileId,
    );
  }

  @override
  Future<void> cancelConnectionRequest({
    required String requestId,
    required String requesterProfileId,
  }) {
    return _remoteDataSource.cancelConnectionRequest(
      requestId: requestId,
      requesterProfileId: requesterProfileId,
    );
  }

  @override
  Future<void> removeConnection({
    required String connectionId,
    required String currentProfileId,
  }) {
    return _remoteDataSource.removeConnection(
      connectionId: connectionId,
      currentProfileId: currentProfileId,
    );
  }

  @override
  Stream<List<ConnectionEntity>> watchConnections({
    required String profileId,
    required String profileUid,
    int limit = 50,
  }) {
    return _remoteDataSource.watchConnections(
      profileId: profileId,
      profileUid: profileUid,
      limit: limit,
    );
  }

  @override
  Future<ConnectionPageEntity> loadConnectionsPage({
    required String profileId,
    required String profileUid,
    String? startAfterConnectionId,
    int limit = 20,
  }) {
    return _remoteDataSource.loadConnectionsPage(
      profileId: profileId,
      profileUid: profileUid,
      startAfterConnectionId: startAfterConnectionId,
      limit: limit,
    );
  }

  @override
  Stream<List<ConnectionRequestEntity>> watchPendingReceivedRequests({
    required String profileId,
    required String profileUid,
    int limit = 25,
  }) {
    return _remoteDataSource.watchPendingReceivedRequests(
      profileId: profileId,
      profileUid: profileUid,
      limit: limit,
    );
  }

  @override
  Stream<List<ConnectionRequestEntity>> watchPendingSentRequests({
    required String profileId,
    required String profileUid,
    int limit = 25,
  }) {
    return _remoteDataSource.watchPendingSentRequests(
      profileId: profileId,
      profileUid: profileUid,
      limit: limit,
    );
  }

  @override
  Stream<ConnectionStatsEntity> watchConnectionStats({
    required String profileId,
  }) {
    return _remoteDataSource.watchConnectionStats(profileId: profileId);
  }

  @override
  Stream<List<PostEntity>> watchNetworkActivity({
    required String profileId,
    required String profileUid,
    int limit = 10,
  }) {
    return _remoteDataSource.watchNetworkActivity(
      profileId: profileId,
      profileUid: profileUid,
      limit: limit,
    );
  }

  @override
  Future<NetworkActivityPageEntity> loadNetworkActivityPage({
    required String profileId,
    required String profileUid,
    NetworkActivityCursorEntity? startAfter,
    int limit = 20,
  }) {
    return _remoteDataSource.loadNetworkActivityPage(
      profileId: profileId,
      profileUid: profileUid,
      startAfter: startAfter,
      limit: limit,
    );
  }

  @override
  Future<List<CommonConnectionEntity>> loadCommonConnections({
    required String profileId,
    required String profileUid,
    required String otherProfileId,
    required String otherProfileUid,
    int limit = 3,
  }) {
    return _remoteDataSource.loadCommonConnections(
      profileId: profileId,
      profileUid: profileUid,
      otherProfileId: otherProfileId,
      otherProfileUid: otherProfileUid,
      limit: limit,
    );
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
  }) {
    return _remoteDataSource.loadConnectionSuggestions(
      profileId: profileId,
      profileUid: profileUid,
      currentCity: currentCity,
      currentProfileType: currentProfileType,
      currentLevel: currentLevel,
      currentInstruments: currentInstruments,
      currentGenres: currentGenres,
      limit: limit,
      filterProfileTypes: filterProfileTypes,
      filterInstruments: filterInstruments,
      filterGenres: filterGenres,
      filterSameCity: filterSameCity,
      filterWithCommonConnections: filterWithCommonConnections,
    );
  }

  @override
  Future<ConnectionStatusEntity> getConnectionStatus({
    required String profileId,
    required String profileUid,
    required String otherProfileId,
  }) {
    return _remoteDataSource.getConnectionStatus(
      profileId: profileId,
      profileUid: profileUid,
      otherProfileId: otherProfileId,
    );
  }
}
