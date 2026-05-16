import 'package:cloud_firestore/cloud_firestore.dart';

import 'connection_status.dart';

class ConnectionRequestEntity {
  const ConnectionRequestEntity({
    required this.id,
    required this.requesterProfileId,
    required this.requesterUid,
    required this.requesterName,
    required this.recipientProfileId,
    required this.recipientUid,
    required this.recipientName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.requesterPhotoUrl,
    this.recipientPhotoUrl,
    this.respondedAt,
  });

  factory ConnectionRequestEntity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return ConnectionRequestEntity(
      id: snapshot.id,
      requesterProfileId: data['requesterProfileId'] as String? ?? '',
      requesterUid: data['requesterUid'] as String? ?? '',
      requesterName: data['requesterName'] as String? ?? '',
      requesterPhotoUrl: data['requesterPhotoUrl'] as String?,
      recipientProfileId: data['recipientProfileId'] as String? ?? '',
      recipientUid: data['recipientUid'] as String? ?? '',
      recipientName: data['recipientName'] as String? ?? '',
      recipientPhotoUrl: data['recipientPhotoUrl'] as String?,
      status: connectionRequestStatusFromString(
        data['status'] as String? ?? ConnectionRequestStatus.pending.name,
      ),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      respondedAt: _parseNullableDate(data['respondedAt']),
    );
  }

  final String id;
  final String requesterProfileId;
  final String requesterUid;
  final String requesterName;
  final String? requesterPhotoUrl;
  final String recipientProfileId;
  final String recipientUid;
  final String recipientName;
  final String? recipientPhotoUrl;
  final ConnectionRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? respondedAt;

  bool get isPending => status == ConnectionRequestStatus.pending;

  Map<String, dynamic> toFirestore() {
    return {
      'requesterProfileId': requesterProfileId,
      'requesterUid': requesterUid,
      'requesterName': requesterName,
      'requesterPhotoUrl': requesterPhotoUrl,
      'recipientProfileId': recipientProfileId,
      'recipientUid': recipientUid,
      'recipientName': recipientName,
      'recipientPhotoUrl': recipientPhotoUrl,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }
}

DateTime _parseDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.now();
}

DateTime? _parseNullableDate(dynamic value) {
  if (value == null) {
    return null;
  }
  return _parseDate(value);
}
