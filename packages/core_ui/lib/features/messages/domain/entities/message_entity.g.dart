// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageEntity _$MessageEntityFromJson(Map<String, dynamic> json) =>
    _MessageEntity(
      messageId: json['messageId'] as String,
      senderId: json['senderId'] as String,
      senderProfileId: json['senderProfileId'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imageUrl: json['imageUrl'] as String?,
      replyTo: json['replyTo'] == null
          ? null
          : MessageReplyEntity.fromJson(
              json['replyTo'] as Map<String, dynamic>),
      reactions: (json['reactions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      read: json['read'] as bool? ?? false,
    );

Map<String, dynamic> _$MessageEntityToJson(_MessageEntity instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'senderId': instance.senderId,
      'senderProfileId': instance.senderProfileId,
      'text': instance.text,
      'timestamp': instance.timestamp.toIso8601String(),
      'imageUrl': instance.imageUrl,
      'replyTo': instance.replyTo,
      'reactions': instance.reactions,
      'read': instance.read,
    };

_MessageReplyEntity _$MessageReplyEntityFromJson(Map<String, dynamic> json) =>
    _MessageReplyEntity(
      messageId: json['messageId'] as String,
      text: json['text'] as String,
      senderId: json['senderId'] as String,
      senderProfileId: json['senderProfileId'] as String?,
    );

Map<String, dynamic> _$MessageReplyEntityToJson(_MessageReplyEntity instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'text': instance.text,
      'senderId': instance.senderId,
      'senderProfileId': instance.senderProfileId,
    };
