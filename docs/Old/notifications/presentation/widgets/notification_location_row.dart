import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Displays contextual location info for a notification, loading the post when needed.
class NotificationLocationRow extends StatefulWidget {
  const NotificationLocationRow({
    super.key,
    required this.notification,
    this.textStyle,
    this.iconColor,
  });

  final NotificationEntity notification;
  final TextStyle? textStyle;
  final Color? iconColor;

  @override
  State<NotificationLocationRow> createState() => _NotificationLocationRowState();
}

class _NotificationLocationRowState extends State<NotificationLocationRow> {
  static final Map<String, _PostLocation> _cache = <String, _PostLocation>{};

  _PostLocation? _postLocation;
  bool _isLoading = false;
  bool _didAttemptLoad = false;

  NotificationEntity get _notification => widget.notification;

  @override
  void initState() {
    super.initState();
    _maybeLoadPostLocation();
  }

  @override
  void didUpdateWidget(NotificationLocationRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notification.notificationId !=
        widget.notification.notificationId) {
      _postLocation = null;
      _isLoading = false;
      _didAttemptLoad = false;
      _maybeLoadPostLocation();
    }
  }

  void _maybeLoadPostLocation() {
    if (_hasInlineLocation || _didAttemptLoad) return;
    final postId = _notification.targetId;
    if (postId == null || postId.isEmpty) return;

    _didAttemptLoad = true;
    if (_cache.containsKey(postId)) {
      setState(() => _postLocation = _cache[postId]);
      return;
    }

    _isLoading = true;
    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .get()
        .then((doc) {
      if (!mounted) return;
      if (!doc.exists) {
        setState(() => _isLoading = false);
        return;
      }
      final data = doc.data()!;
      final location = _PostLocation(
        city: (data['city'] as String?)?.trim(),
        neighborhood: (data['neighborhood'] as String?)?.trim(),
        state: (data['state'] as String?)?.trim(),
      );
      _cache[postId] = location;
      setState(() {
        _postLocation = location;
        _isLoading = false;
      });
    }).catchError((_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  bool get _hasInlineLocation =>
      (_notification.city?.isNotEmpty ?? false) ||
      (_notification.distance != null);

  String? get _resolvedLocationLabel {
    final inlineCity = _notification.city;
    if (inlineCity != null && inlineCity.isNotEmpty) {
      return inlineCity;
    }

    if (_postLocation == null) {
      return null;
    }

    final parts = <String>[];
    if (_postLocation!.neighborhood?.isNotEmpty ?? false) {
      parts.add(_postLocation!.neighborhood!);
    }
    final cityState = _composeCityState(_postLocation!);
    if (cityState != null) {
      parts.add(cityState);
    }

    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' · ');
  }

  String? _composeCityState(_PostLocation location) {
    final city = location.city;
    final state = location.state;
    if ((city?.isNotEmpty ?? false) && (state?.isNotEmpty ?? false)) {
      return '$city/$state';
    }
    return city ?? state;
  }

  String? get _distanceLabel {
    final distance = _notification.distance;
    if (distance == null) return null;
    final formatted = distance >= 10 ? distance.toStringAsFixed(0) : distance.toStringAsFixed(1);
    return '$formatted km';
  }

  @override
  Widget build(BuildContext context) {
    final locationLabel = _resolvedLocationLabel;
    final distanceLabel = _distanceLabel;
    final shouldShow =
        (locationLabel?.isNotEmpty ?? false) || (distanceLabel?.isNotEmpty ?? false);

    if (!shouldShow) {
      if (_isLoading) {
        return _buildRow('Carregando localização...');
      }
      return const SizedBox.shrink();
    }

    final parts = <String>[];
    if (locationLabel != null && locationLabel.isNotEmpty) {
      parts.add(locationLabel);
    }
    if (distanceLabel != null && distanceLabel.isNotEmpty) {
      parts.add(distanceLabel);
    }

    return _buildRow(parts.join(' · '));
  }

  Widget _buildRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.location,
            size: 16,
            color: widget.iconColor ?? AppColors.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: widget.textStyle ??
                  const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostLocation {
  const _PostLocation({this.city, this.neighborhood, this.state});

  final String? city;
  final String? neighborhood;
  final String? state;
}
