import '../entities/entities.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';

abstract class ConnectionsRepository {
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
