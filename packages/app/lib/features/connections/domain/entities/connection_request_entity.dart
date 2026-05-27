import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/utils/utf16_sanitizer.dart';

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
      requesterProfileId: _safe(data['requesterProfileId'] as String? ?? ''),
      requesterUid: _safe(data['requesterUid'] as String? ?? ''),
      requesterName: _safe(data['requesterName'] as String? ?? ''),
      requesterPhotoUrl: _safeOrNull(data['requesterPhotoUrl'] as String?),
      recipientProfileId: _safe(data['recipientProfileId'] as String? ?? ''),
      recipientUid: _safe(data['recipientUid'] as String? ?? ''),
      recipientName: _safe(data['recipientName'] as String? ?? ''),
      recipientPhotoUrl: _safeOrNull(data['recipientPhotoUrl'] as String?),
      status: connectionRequestStatusFromString(
        _safe(
            data['status'] as String? ?? ConnectionRequestStatus.pending.name),
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

String _safe(String value) => Utf16Sanitizer.removeInvalidSurrogates(value);

String? _safeOrNull(String? value) =>
    Utf16Sanitizer.removeInvalidSurrogatesOrNull(value);

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
