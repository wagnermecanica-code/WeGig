import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionStatsEntity {
  const ConnectionStatsEntity({
    required this.profileId,
    required this.totalConnections,
    required this.pendingReceived,
    required this.pendingSent,
    required this.updatedAt,
  });

  const ConnectionStatsEntity.empty(String profileId)
      : profileId = profileId,
        totalConnections = 0,
        pendingReceived = 0,
        pendingSent = 0,
        updatedAt = null;

  factory ConnectionStatsEntity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return ConnectionStatsEntity(
      profileId: snapshot.id,
      totalConnections: (data['totalConnections'] as num?)?.toInt() ?? 0,
      pendingReceived: (data['pendingReceived'] as num?)?.toInt() ?? 0,
      pendingSent: (data['pendingSent'] as num?)?.toInt() ?? 0,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  final String profileId;
  final int totalConnections;
  final int pendingReceived;
  final int pendingSent;
  final DateTime? updatedAt;
}
