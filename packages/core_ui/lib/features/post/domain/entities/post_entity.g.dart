// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, invalid_annotation_target

part of 'post_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostEntityImpl _$$PostEntityImplFromJson(Map<String, dynamic> json) =>
    _$PostEntityImpl(
      id: json['id'] as String,
      authorProfileId: json['authorProfileId'] as String,
      authorUid: json['authorUid'] as String,
      content: json['content'] as String,
      location: const GeoPointConverter()
          .fromJson(json['location'] as Map<String, dynamic>),
      city: json['city'] as String,
      type: json['type'] as String,
      level: json['level'] as String,
      instruments: (json['instruments'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      genres:
          (json['genres'] as List<dynamic>).map((e) => e as String).toList(),
      seekingMusicians: (json['seekingMusicians'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      expiresAt:
          const TimestampConverter().fromJson(json['expiresAt'] as Object),
      neighborhood: json['neighborhood'] as String?,
      state: json['state'] as String?,
      photoUrl: json['photoUrl'] as String?,
      youtubeLink: json['youtubeLink'] as String?,
      availableFor: (json['availableFor'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      authorName: json['authorName'] as String?,
      authorPhotoUrl: json['authorPhotoUrl'] as String?,
      activeProfileName: json['activeProfileName'] as String?,
      activeProfilePhotoUrl: json['activeProfilePhotoUrl'] as String?,
    );

Map<String, dynamic> _$$PostEntityImplToJson(_$PostEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'authorProfileId': instance.authorProfileId,
      'authorUid': instance.authorUid,
      'content': instance.content,
      'location': const GeoPointConverter().toJson(instance.location),
      'city': instance.city,
      'type': instance.type,
      'level': instance.level,
      'instruments': instance.instruments,
      'genres': instance.genres,
      'seekingMusicians': instance.seekingMusicians,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'expiresAt': const TimestampConverter().toJson(instance.expiresAt),
      'neighborhood': instance.neighborhood,
      'state': instance.state,
      'photoUrl': instance.photoUrl,
      'youtubeLink': instance.youtubeLink,
      'availableFor': instance.availableFor,
      'distanceKm': instance.distanceKm,
      'authorName': instance.authorName,
      'authorPhotoUrl': instance.authorPhotoUrl,
      'activeProfileName': instance.activeProfileName,
      'activeProfilePhotoUrl': instance.activeProfilePhotoUrl,
    };
