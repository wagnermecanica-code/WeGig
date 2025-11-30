// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileEntity _$ProfileEntityFromJson(Map<String, dynamic> json) =>
    _ProfileEntity(
      profileId: json['profileId'] as String,
      uid: json['uid'] as String,
      name: json['name'] as String,
      isBand: json['isBand'] as bool,
      city: json['city'] as String,
      location: const GeoPointConverter()
          .fromJson(json['location'] as Map<String, dynamic>),
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      notificationRadius:
          (json['notificationRadius'] as num?)?.toDouble() ?? 20.0,
      notificationRadiusEnabled:
          json['notificationRadiusEnabled'] as bool? ?? true,
      photoUrl: json['photoUrl'] as String?,
      birthYear: (json['birthYear'] as num?)?.toInt(),
      bio: json['bio'] as String?,
      instruments: (json['instruments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      genres:
          (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList(),
      level: json['level'] as String?,
      instagramLink: json['instagramLink'] as String?,
      tiktokLink: json['tiktokLink'] as String?,
      youtubeLink: json['youtubeLink'] as String?,
      neighborhood: json['neighborhood'] as String?,
      state: json['state'] as String?,
      bandMembers: (json['bandMembers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$ProfileEntityToJson(_ProfileEntity instance) =>
    <String, dynamic>{
      'profileId': instance.profileId,
      'uid': instance.uid,
      'name': instance.name,
      'isBand': instance.isBand,
      'city': instance.city,
      'location': const GeoPointConverter().toJson(instance.location),
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'notificationRadius': instance.notificationRadius,
      'notificationRadiusEnabled': instance.notificationRadiusEnabled,
      'photoUrl': instance.photoUrl,
      'birthYear': instance.birthYear,
      'bio': instance.bio,
      'instruments': instance.instruments,
      'genres': instance.genres,
      'level': instance.level,
      'instagramLink': instance.instagramLink,
      'tiktokLink': instance.tiktokLink,
      'youtubeLink': instance.youtubeLink,
      'neighborhood': instance.neighborhood,
      'state': instance.state,
      'bandMembers': instance.bandMembers,
      'updatedAt':
          const NullableTimestampConverter().toJson(instance.updatedAt),
    };
