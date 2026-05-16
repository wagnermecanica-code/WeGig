import 'connection_status.dart';

class ConnectionStatusEntity {
  const ConnectionStatusEntity({
    required this.status,
    this.requestId,
    this.connectionId,
    this.otherProfileId,
  });

  const ConnectionStatusEntity.none()
      : status = ConnectionRelationshipStatus.none,
        requestId = null,
        connectionId = null,
        otherProfileId = null;

  final ConnectionRelationshipStatus status;
  final String? requestId;
  final String? connectionId;
  final String? otherProfileId;

  bool get canSendRequest => status == ConnectionRelationshipStatus.none;
  bool get isConnected => status == ConnectionRelationshipStatus.connected;
}
