// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, invalid_annotation_target

part of 'profile_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileEntityImpl _$$ProfileEntityImplFromJson(Map<String, dynamic> json) =>
    _$ProfileEntityImpl(
      profileId: json['profileId'] as String,
      uid: json['uid'] as String,
      name: json['name'] as String,
      username: json['username'] as String?,
      isBand: json['isBand'] as bool,
      profileType:
          $enumDecodeNullable(_$ProfileTypeEnumMap, json['profileType']) ??
              ProfileType.musician,
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
      spaceType: json['spaceType'] as String?,
      phone: json['phone'] as String?,
      operatingHours: json['operatingHours'] as String?,
      website: json['website'] as String?,
      amenities: (json['amenities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$$ProfileEntityImplToJson(_$ProfileEntityImpl instance) =>
    <String, dynamic>{
      'profileId': instance.profileId,
      'uid': instance.uid,
      'name': instance.name,
      'username': instance.username,
      'isBand': instance.isBand,
      'profileType': _$ProfileTypeEnumMap[instance.profileType]!,
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
      'spaceType': instance.spaceType,
      'phone': instance.phone,
      'operatingHours': instance.operatingHours,
      'website': instance.website,
      'amenities': instance.amenities,
      'updatedAt':
          const NullableTimestampConverter().toJson(instance.updatedAt),
    };

const _$ProfileTypeEnumMap = {
  ProfileType.musician: 'musician',
  ProfileType.band: 'band',
  ProfileType.space: 'space',
};
