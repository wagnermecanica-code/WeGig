// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_new_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConversationNewEntityImpl _$$ConversationNewEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$ConversationNewEntityImpl(
      id: json['id'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      participantProfiles: (json['participantProfiles'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lastMessage: json['lastMessage'] as String,
      lastMessageTimestamp:
          DateTime.parse(json['lastMessageTimestamp'] as String),
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      unreadCount: Map<String, int>.from(json['unreadCount'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      archived: json['archived'] as bool? ?? false,
      archivedByProfiles: (json['archivedByProfiles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      mutedByProfiles: (json['mutedByProfiles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      pinnedByProfiles: (json['pinnedByProfiles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      deletedByProfiles: (json['deletedByProfiles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      clearHistoryTimestamp:
          (json['clearHistoryTimestamp'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, DateTime.parse(e as String)),
              ) ??
              const <String, DateTime>{},
      typingIndicators:
          (json['typingIndicators'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, DateTime.parse(e as String)),
              ) ??
              const {},
    );

Map<String, dynamic> _$$ConversationNewEntityImplToJson(
        _$ConversationNewEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participants': instance.participants,
      'participantProfiles': instance.participantProfiles,
      'lastMessage': instance.lastMessage,
      'lastMessageTimestamp': instance.lastMessageTimestamp.toIso8601String(),
      'lastMessageSenderId': instance.lastMessageSenderId,
      'unreadCount': instance.unreadCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'archived': instance.archived,
      'archivedByProfiles': instance.archivedByProfiles,
      'mutedByProfiles': instance.mutedByProfiles,
      'pinnedByProfiles': instance.pinnedByProfiles,
      'deletedByProfiles': instance.deletedByProfiles,
      'clearHistoryTimestamp': instance.clearHistoryTimestamp
          .map((k, e) => MapEntry(k, e.toIso8601String())),
      'typingIndicators': instance.typingIndicators
          .map((k, e) => MapEntry(k, e.toIso8601String())),
    };

_$ParticipantDataImpl _$$ParticipantDataImplFromJson(
        Map<String, dynamic> json) =>
    _$ParticipantDataImpl(
      profileId: json['profileId'] as String,
      uid: json['uid'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      profileType: json['profileType'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] == null
          ? null
          : DateTime.parse(json['lastSeen'] as String),
    );

Map<String, dynamic> _$$ParticipantDataImplToJson(
        _$ParticipantDataImpl instance) =>
    <String, dynamic>{
      'profileId': instance.profileId,
      'uid': instance.uid,
      'name': instance.name,
      'photoUrl': instance.photoUrl,
      'profileType': instance.profileType,
      'isOnline': instance.isOnline,
      'lastSeen': instance.lastSeen?.toIso8601String(),
    };
