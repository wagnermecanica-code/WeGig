import '../entities/entities.dart';
import '../repositories/connections_repository.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';

class LoadMyConnectionsUseCase {
  const LoadMyConnectionsUseCase(this._repository);

  final ConnectionsRepository _repository;

  Stream<List<ConnectionEntity>> call({
    required String profileId,
    required String profileUid,
    int limit = 50,
  }) {
    return _repository.watchConnections(
      profileId: profileId,
      profileUid: profileUid,
      limit: limit,
    );
  }
}

class LoadConnectionsPageUseCase {
  const LoadConnectionsPageUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<ConnectionPageEntity> call({
    required String profileId,
    required String profileUid,
    String? startAfterConnectionId,
    int limit = 20,
  }) {
    return _repository.loadConnectionsPage(
      profileId: profileId,
      profileUid: profileUid,
      startAfterConnectionId: startAfterConnectionId,
      limit: limit,
    );
  }
}

class LoadPendingReceivedRequestsUseCase {
  const LoadPendingReceivedRequestsUseCase(this._repository);

  final ConnectionsRepository _repository;

  Stream<List<ConnectionRequestEntity>> call({
    required String profileId,
    required String profileUid,
    int limit = 25,
  }) {
    return _repository.watchPendingReceivedRequests(
      profileId: profileId,
      profileUid: profileUid,
      limit: limit,
    );
  }
}

class LoadPendingSentRequestsUseCase {
  const LoadPendingSentRequestsUseCase(this._repository);

  final ConnectionsRepository _repository;

  Stream<List<ConnectionRequestEntity>> call({
    required String profileId,
    required String profileUid,
    int limit = 25,
  }) {
    return _repository.watchPendingSentRequests(
      profileId: profileId,
      profileUid: profileUid,
      limit: limit,
    );
  }
}

class LoadConnectionStatsUseCase {
  const LoadConnectionStatsUseCase(this._repository);

  final ConnectionsRepository _repository;

  Stream<ConnectionStatsEntity> call({
    required String profileId,
  }) {
    return _repository.watchConnectionStats(profileId: profileId);
  }
}

class LoadNetworkActivityUseCase {
  const LoadNetworkActivityUseCase(this._repository);

  final ConnectionsRepository _repository;

  Stream<List<PostEntity>> call({
    required String profileId,
    required String profileUid,
    int limit = 10,
  }) {
    return _repository.watchNetworkActivity(
      profileId: profileId,
      profileUid: profileUid,
      limit: limit,
    );
  }
}

class LoadNetworkActivityPageUseCase {
  const LoadNetworkActivityPageUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<NetworkActivityPageEntity> call({
    required String profileId,
    required String profileUid,
    NetworkActivityCursorEntity? startAfter,
    int limit = 20,
  }) {
    return _repository.loadNetworkActivityPage(
      profileId: profileId,
      profileUid: profileUid,
      startAfter: startAfter,
      limit: limit,
    );
  }
}

class LoadCommonConnectionsUseCase {
  const LoadCommonConnectionsUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<List<CommonConnectionEntity>> call({
    required String profileId,
    required String profileUid,
    required String otherProfileId,
    required String otherProfileUid,
    int limit = 3,
  }) {
    return _repository.loadCommonConnections(
      profileId: profileId,
      profileUid: profileUid,
      otherProfileId: otherProfileId,
      otherProfileUid: otherProfileUid,
      limit: limit,
    );
  }
}

class LoadConnectionSuggestionsUseCase {
  const LoadConnectionSuggestionsUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<List<ConnectionSuggestionEntity>> call({
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
    return _repository.loadConnectionSuggestions(
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
}

class GetConnectionStatusUseCase {
  const GetConnectionStatusUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<ConnectionStatusEntity> call({
    required String profileId,
    required String profileUid,
    required String otherProfileId,
  }) {
    return _repository.getConnectionStatus(
      profileId: profileId,
      profileUid: profileUid,
      otherProfileId: otherProfileId,
    );
  }
}
