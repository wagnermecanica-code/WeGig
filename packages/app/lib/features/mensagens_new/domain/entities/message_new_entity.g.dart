// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_new_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageNewEntityImpl _$$MessageNewEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$MessageNewEntityImpl(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderProfileId: json['senderProfileId'] as String,
      senderName: json['senderName'] as String?,
      senderPhotoUrl: json['senderPhotoUrl'] as String?,
      text: json['text'] as String,
      imageUrl: json['imageUrl'] as String?,
      type: $enumDecodeNullable(_$MessageTypeEnumMap, json['type']) ??
          MessageType.text,
      status:
          $enumDecodeNullable(_$MessageDeliveryStatusEnumMap, json['status']) ??
              MessageDeliveryStatus.sending,
      createdAt: DateTime.parse(json['createdAt'] as String),
      editedAt: json['editedAt'] == null
          ? null
          : DateTime.parse(json['editedAt'] as String),
      isEdited: json['isEdited'] as bool? ?? false,
      reactions: (json['reactions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      replyTo: json['replyTo'] == null
          ? null
          : MessageReplyData.fromJson(json['replyTo'] as Map<String, dynamic>),
      deletedForProfiles: (json['deletedForProfiles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      deletedForEveryone: json['deletedForEveryone'] as bool? ?? false,
      originalText: json['originalText'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$MessageNewEntityImplToJson(
        _$MessageNewEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'senderId': instance.senderId,
      'senderProfileId': instance.senderProfileId,
      'senderName': instance.senderName,
      'senderPhotoUrl': instance.senderPhotoUrl,
      'text': instance.text,
      'imageUrl': instance.imageUrl,
      'type': _$MessageTypeEnumMap[instance.type]!,
      'status': _$MessageDeliveryStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'editedAt': instance.editedAt?.toIso8601String(),
      'isEdited': instance.isEdited,
      'reactions': instance.reactions,
      'replyTo': instance.replyTo,
      'deletedForProfiles': instance.deletedForProfiles,
      'deletedForEveryone': instance.deletedForEveryone,
      'originalText': instance.originalText,
      'metadata': instance.metadata,
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.system: 'system',
  MessageType.deleted: 'deleted',
};

const _$MessageDeliveryStatusEnumMap = {
  MessageDeliveryStatus.sending: 'sending',
  MessageDeliveryStatus.sent: 'sent',
  MessageDeliveryStatus.delivered: 'delivered',
  MessageDeliveryStatus.read: 'read',
  MessageDeliveryStatus.failed: 'failed',
};

_$MessageReplyDataImpl _$$MessageReplyDataImplFromJson(
        Map<String, dynamic> json) =>
    _$MessageReplyDataImpl(
      messageId: json['messageId'] as String,
      text: json['text'] as String,
      senderProfileId: json['senderProfileId'] as String,
      senderName: json['senderName'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$$MessageReplyDataImplToJson(
        _$MessageReplyDataImpl instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'text': instance.text,
      'senderProfileId': instance.senderProfileId,
      'senderName': instance.senderName,
      'imageUrl': instance.imageUrl,
    };
