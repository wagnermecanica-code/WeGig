// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConversationEntity _$ConversationEntityFromJson(Map<String, dynamic> json) =>
    _ConversationEntity(
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
      unreadCount: Map<String, int>.from(json['unreadCount'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      archived: json['archived'] as bool? ?? false,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ConversationEntityToJson(_ConversationEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participants': instance.participants,
      'participantProfiles': instance.participantProfiles,
      'lastMessage': instance.lastMessage,
      'lastMessageTimestamp': instance.lastMessageTimestamp.toIso8601String(),
      'unreadCount': instance.unreadCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'archived': instance.archived,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
