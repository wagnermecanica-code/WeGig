import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';

/// JSON Converter for Firestore GeoPoint
class GeoPointConverter implements JsonConverter<GeoPoint, Map<String, dynamic>> {
  const GeoPointConverter();

  @override
  GeoPoint fromJson(Map<String, dynamic> json) {
    // Handle different GeoPoint JSON formats
    if (json.containsKey('_latitude') && json.containsKey('_longitude')) {
      return GeoPoint(
        (json['_latitude'] as num).toDouble(),
        (json['_longitude'] as num).toDouble(),
      );
    }
    if (json.containsKey('latitude') && json.containsKey('longitude')) {
      return GeoPoint(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      );
    }
    return const GeoPoint(0, 0);
  }

  @override
  Map<String, dynamic> toJson(GeoPoint geoPoint) {
    return {
      '_latitude': geoPoint.latitude,
      '_longitude': geoPoint.longitude,
    };
  }
}

/// JSON Converter for Firestore Timestamp to DateTime
class TimestampConverter implements JsonConverter<DateTime, Object> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object json) {
    if (json is Timestamp) {
      return json.toDate();
    }
    if (json is String) {
      return DateTime.parse(json);
    }
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    if (json is Map && json.containsKey('_seconds')) {
      final seconds = (json['_seconds'] as num).toInt();
      final nanoseconds = (json['_nanoseconds'] as num?)?.toInt() ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + nanoseconds ~/ 1000000,
      );
    }
    return DateTime.now();
  }

  @override
  String toJson(DateTime dateTime) {
    return dateTime.toIso8601String();
  }
}

/// JSON Converter for nullable Firestore Timestamp to DateTime?
class NullableTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) {
      return json.toDate();
    }
    if (json is String) {
      return DateTime.parse(json);
    }
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    if (json is Map && json.containsKey('_seconds')) {
      final seconds = (json['_seconds'] as num).toInt();
      final nanoseconds = (json['_nanoseconds'] as num?)?.toInt() ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + nanoseconds ~/ 1000000,
      );
    }
    return null;
  }

  @override
  String? toJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}

/// JSON Converter for NotificationType enum
class NotificationTypeConverter implements JsonConverter<NotificationType, String> {
  const NotificationTypeConverter();

  @override
  NotificationType fromJson(String json) {
    return NotificationEntity.parseType(json);
  }

  @override
  String toJson(NotificationType type) {
    return type.name;
  }
}

/// JSON Converter for NotificationPriority enum
class NotificationPriorityConverter implements JsonConverter<NotificationPriority, String> {
  const NotificationPriorityConverter();

  @override
  NotificationPriority fromJson(String json) {
    return NotificationEntity.parsePriority(json);
  }

  @override
  String toJson(NotificationPriority priority) {
    return priority.name;
  }
}

/// JSON Converter for NotificationActionType enum (nullable)
class NullableNotificationActionTypeConverter implements JsonConverter<NotificationActionType?, String?> {
  const NullableNotificationActionTypeConverter();

  @override
  NotificationActionType? fromJson(String? json) {
    if (json == null) return null;
    return NotificationEntity.parseActionType(json);
  }

  @override
  String? toJson(NotificationActionType? actionType) {
    return actionType?.name;
  }
}
