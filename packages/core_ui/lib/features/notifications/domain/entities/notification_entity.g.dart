// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint, invalid_annotation_target

part of 'notification_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationEntityImpl _$$NotificationEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationEntityImpl(
      notificationId: json['notificationId'] as String,
      type: const NotificationTypeConverter().fromJson(json['type'] as String),
      recipientUid: json['recipientUid'] as String,
      recipientProfileId: json['recipientProfileId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      senderUid: json['senderUid'] as String?,
      senderProfileId: json['senderProfileId'] as String?,
      senderName: json['senderName'] as String?,
      senderUsername: json['senderUsername'] as String?,
      senderPhoto: json['senderPhoto'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? const {},
      actionType: const NullableNotificationActionTypeConverter()
          .fromJson(json['actionType'] as String?),
      actionData: json['actionData'] as Map<String, dynamic>?,
      priority: json['priority'] == null
          ? NotificationPriority.medium
          : const NotificationPriorityConverter()
              .fromJson(json['priority'] as String),
      read: json['read'] as bool? ?? false,
      readAt: const NullableTimestampConverter().fromJson(json['readAt']),
      expiresAt: const NullableTimestampConverter().fromJson(json['expiresAt']),
    );

Map<String, dynamic> _$$NotificationEntityImplToJson(
        _$NotificationEntityImpl instance) =>
    <String, dynamic>{
      'notificationId': instance.notificationId,
      'type': const NotificationTypeConverter().toJson(instance.type),
      'recipientUid': instance.recipientUid,
      'recipientProfileId': instance.recipientProfileId,
      'title': instance.title,
      'message': instance.message,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'senderUid': instance.senderUid,
      'senderProfileId': instance.senderProfileId,
      'senderName': instance.senderName,
      'senderUsername': instance.senderUsername,
      'senderPhoto': instance.senderPhoto,
      'data': instance.data,
      'actionType': const NullableNotificationActionTypeConverter()
          .toJson(instance.actionType),
      'actionData': instance.actionData,
      'priority':
          const NotificationPriorityConverter().toJson(instance.priority),
      'read': instance.read,
      'readAt': const NullableTimestampConverter().toJson(instance.readAt),
      'expiresAt':
          const NullableTimestampConverter().toJson(instance.expiresAt),
    };
