import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/utils/utf16_sanitizer.dart';

class ConnectionEntity {
  const ConnectionEntity({
    required this.id,
    required this.profileIds,
    required this.profileUids,
    required this.profileNames,
    required this.profilePhotoUrls,
    required this.createdAt,
    required this.updatedAt,
    required this.initiatedByProfileId,
    required this.requestId,
  });

  factory ConnectionEntity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return ConnectionEntity(
      id: snapshot.id,
      profileIds: _safeList(
        (data['profileIds'] as List<dynamic>? ?? const <dynamic>[])
            .cast<String>(),
      ),
      profileUids: _safeList(
        (data['profileUids'] as List<dynamic>? ?? const <dynamic>[])
            .cast<String>(),
      ),
      profileNames: _safeMap(Map<String, String>.from(
        data['profileNames'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      )),
      profilePhotoUrls: _safeMap(Map<String, String>.from(
        data['profilePhotoUrls'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      )),
      createdAt: _parseConnectionDate(data['createdAt']),
      updatedAt: _parseConnectionDate(data['updatedAt']),
      initiatedByProfileId:
          _safe(data['initiatedByProfileId'] as String? ?? ''),
      requestId: _safe(data['requestId'] as String? ?? ''),
    );
  }

  final String id;
  final List<String> profileIds;
  final List<String> profileUids;
  final Map<String, String> profileNames;
  final Map<String, String> profilePhotoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String initiatedByProfileId;
  final String requestId;

  String getOtherProfileId(String currentProfileId) {
    return profileIds.firstWhere(
      (profileId) => profileId != currentProfileId,
      orElse: () => '',
    );
  }

  String getOtherProfileName(String currentProfileId) {
    final otherProfileId = getOtherProfileId(currentProfileId);
    return profileNames[otherProfileId] ?? '';
  }

  String getOtherProfileUid(String currentProfileId) {
    final otherProfileId = getOtherProfileId(currentProfileId);
    final index = profileIds.indexOf(otherProfileId);
    if (index < 0 || index >= profileUids.length) {
      return '';
    }
    return profileUids[index];
  }

  String? getOtherProfilePhotoUrl(String currentProfileId) {
    final otherProfileId = getOtherProfileId(currentProfileId);
    return profilePhotoUrls[otherProfileId];
  }
}

String _safe(String value) => Utf16Sanitizer.removeInvalidSurrogates(value);

List<String> _safeList(List<String> values) =>
    Utf16Sanitizer.removeInvalidSurrogatesFromList(values) ?? const <String>[];

Map<String, String> _safeMap(Map<String, String> values) {
  return values.map((key, value) => MapEntry(_safe(key), _safe(value)));
}

DateTime _parseConnectionDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.now();
}
