import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:core_ui/core/json_converters.dart';
import 'package:core_ui/utils/utf16_sanitizer.dart';

part 'post_entity.freezed.dart';
part 'post_entity.g.dart';

/// Domain entity para Posts
/// Representa um post de músico ou banda procurando colaboradores
@freezed
class PostEntity with _$PostEntity {
  const PostEntity._();

  const factory PostEntity({
    required String id,
    required String authorProfileId,
    required String authorUid,
    required String content,
    @GeoPointConverter() required GeoPoint location,
    required String city,
    required String type,
    required String level,
    required List<String> instruments,
    required List<String> genres,
    required List<String> seekingMusicians,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime expiresAt,
    String? neighborhood,
    String? state,
    String? photoUrl, // Mantido para compatibilidade
    @Default([]) List<String> photoUrls, // NOVO: Lista de fotos (até 4)
    String? youtubeLink,
    String? spotifyLink,
    String? deezerLink,
    @Default([]) List<String> availableFor,
    @TimestampConverter() DateTime? eventDate,
    String? eventType,
    String? gigFormat,
    @Default([]) List<String> venueSetup,
    String? budgetRange,
    String? eventStartTime,
    String? eventEndTime,
    int? eventDurationMinutes,
    int? guestCount,
    double? distanceKm,
    String? authorName,
    String? authorPhotoUrl,
    String? activeProfileName,
    String? activeProfilePhotoUrl,
    // Sales-specific fields
    String? title,
    String? salesType,
    double? price,
    String? discountMode,
    double? discountValue,
    @TimestampConverter() DateTime? promoStartDate,
    @TimestampConverter() DateTime? promoEndDate,
    String? whatsappNumber,
    @Default(0) int commentCount,
    @Default(0) int forwardCount,
  }) = _PostEntity;

  /// From Firestore Document
  factory PostEntity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Post data is null');
    }

    return PostEntity(
      id: snapshot.id,
      authorProfileId: _safe(data['authorProfileId'] as String? ?? ''),
      authorUid: _safe(data['authorUid'] as String? ?? ''),
      content: _safe((data['content'] ?? data['message']) as String? ?? ''),
      location: _parseGeoPoint(data['location']),
      city: _safe(data['city'] as String? ?? ''),
      neighborhood: _safeOrNull(data['neighborhood'] as String?),
      state: _safeOrNull(data['state'] as String?),
      photoUrl: _safeOrNull(data['photoUrl'] as String?),
      photoUrls: _safeList(
        (data['photoUrls'] as List<dynamic>?)?.cast<String>() ??
            (data['photoUrl'] != null ? [data['photoUrl'] as String] : []),
      ), // Compatibilidade
      youtubeLink: _safeOrNull(data['youtubeLink'] as String?),
      spotifyLink: _safeOrNull(data['spotifyLink'] as String?),
      deezerLink: _safeOrNull(data['deezerLink'] as String?),
      type: _safe(data['type'] as String? ?? 'musician'),
      level: _safe(data['level'] as String? ?? ''),
      instruments: _safeList(
        (data['instruments'] as List<dynamic>?)?.cast<String>() ?? [],
      ),
      genres:
          _safeList((data['genres'] as List<dynamic>?)?.cast<String>() ?? []),
      seekingMusicians: _safeList(
        (data['seekingMusicians'] as List<dynamic>?)?.cast<String>() ?? [],
      ),
      availableFor: _safeList(
        (data['availableFor'] as List<dynamic>?)?.cast<String>() ?? [],
      ),
      eventDate: (data['eventDate'] as Timestamp?)?.toDate(),
      eventType: _safeOrNull(data['eventType'] as String?),
      gigFormat: _safeOrNull(data['gigFormat'] as String?),
      venueSetup: _safeList(
        (data['venueSetup'] as List<dynamic>?)?.cast<String>() ?? [],
      ),
      budgetRange: _safeOrNull(data['budgetRange'] as String?),
      eventStartTime: _safeOrNull(data['eventStartTime'] as String?),
      eventEndTime: _safeOrNull(data['eventEndTime'] as String?),
      eventDurationMinutes: (data['eventDurationMinutes'] as num?)?.toInt(),
      guestCount: (data['guestCount'] as num?)?.toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      authorName: _safeOrNull(data['authorName'] as String?),
      authorPhotoUrl: _safeOrNull(data['authorPhotoUrl'] as String?),
      activeProfileName: _safeOrNull(data['activeProfileName'] as String?),
      activeProfilePhotoUrl:
          _safeOrNull(data['activeProfilePhotoUrl'] as String?),
      // Sales-specific fields
      title: _safeOrNull(data['title'] as String?),
      salesType: _safeOrNull(data['salesType'] as String?),
      price: (data['price'] as num?)?.toDouble(),
      discountMode: _safeOrNull(data['discountMode'] as String?),
      discountValue: (data['discountValue'] as num?)?.toDouble(),
      promoStartDate: (data['promoStartDate'] as Timestamp?)?.toDate(),
      promoEndDate: (data['promoEndDate'] as Timestamp?)?.toDate(),
      whatsappNumber: _safeOrNull(data['whatsappNumber'] as String?),
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      forwardCount: (data['forwardCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// From JSON - generated by freezed
  factory PostEntity.fromJson(Map<String, dynamic> json) =>
      _$PostEntityFromJson(json);

  /// Getters úteis
  double get latitude => location.latitude;
  double get longitude => location.longitude;

  bool get hasPhoto =>
      photoUrls.isNotEmpty || (photoUrl != null && photoUrl!.isNotEmpty);
  bool get hasYouTube => youtubeLink != null && youtubeLink!.isNotEmpty;
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Retorna primeira foto (para compatibilidade com código existente)
  String? get firstPhotoUrl =>
      photoUrls.isNotEmpty ? photoUrls.first : photoUrl;

  /// To Firestore Document
  Map<String, dynamic> toFirestore() {
    return {
      'authorProfileId': authorProfileId,
      'authorUid': authorUid,
      'content': content,
      'location': location,
      'city': city,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (state != null) 'state': state,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
      if (youtubeLink != null) 'youtubeLink': youtubeLink,
      if (spotifyLink != null) 'spotifyLink': spotifyLink,
      if (deezerLink != null) 'deezerLink': deezerLink,
      'type': type,
      'level': level,
      'instruments': instruments,
      'genres': genres,
      'seekingMusicians': seekingMusicians,
      'availableFor': availableFor,
      if (eventDate != null) 'eventDate': Timestamp.fromDate(eventDate!),
      if (eventType != null) 'eventType': eventType,
      if (gigFormat != null) 'gigFormat': gigFormat,
      if (venueSetup.isNotEmpty) 'venueSetup': venueSetup,
      if (budgetRange != null) 'budgetRange': budgetRange,
      if (eventStartTime != null) 'eventStartTime': eventStartTime,
      if (eventEndTime != null) 'eventEndTime': eventEndTime,
      if (eventDurationMinutes != null)
        'eventDurationMinutes': eventDurationMinutes,
      if (guestCount != null) 'guestCount': guestCount,
      if (authorName != null) 'authorName': authorName,
      if (authorPhotoUrl != null) 'authorPhotoUrl': authorPhotoUrl,
      if (activeProfileName != null) 'activeProfileName': activeProfileName,
      if (activeProfilePhotoUrl != null)
        'activeProfilePhotoUrl': activeProfilePhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      // Sales-specific fields
      if (title != null) 'title': title,
      if (salesType != null) 'salesType': salesType,
      if (price != null) 'price': price,
      if (discountMode != null) 'discountMode': discountMode,
      if (discountValue != null) 'discountValue': discountValue,
      if (promoStartDate != null)
        'promoStartDate': Timestamp.fromDate(promoStartDate!),
      if (promoEndDate != null)
        'promoEndDate': Timestamp.fromDate(promoEndDate!),
      if (whatsappNumber != null) 'whatsappNumber': whatsappNumber,
      'commentCount': commentCount,
      'forwardCount': forwardCount,
    };
  }

  // To JSON - generated by freezed
  // toJson() is already generated by freezed
}

String _safe(String value) => Utf16Sanitizer.removeInvalidSurrogates(value);

String? _safeOrNull(String? value) =>
    Utf16Sanitizer.removeInvalidSurrogatesOrNull(value);

List<String> _safeList(List<String> values) =>
    Utf16Sanitizer.removeInvalidSurrogatesFromList(values) ?? const <String>[];

/// Accepts both GeoPoint and legacy map representations from older documents.
GeoPoint _parseGeoPoint(dynamic rawLocation) {
  if (rawLocation is GeoPoint) {
    return rawLocation;
  }

  if (rawLocation is Map<String, dynamic>) {
    final lat = _tryParseCoordinate(
      rawLocation['latitude'] ?? rawLocation['_latitude'] ?? rawLocation['lat'],
    );
    final lng = _tryParseCoordinate(
      rawLocation['longitude'] ??
          rawLocation['_longitude'] ??
          rawLocation['lng'],
    );
    if (lat != null && lng != null) {
      return GeoPoint(lat, lng);
    }
  }

  return const GeoPoint(0, 0);
}

double? _tryParseCoordinate(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
