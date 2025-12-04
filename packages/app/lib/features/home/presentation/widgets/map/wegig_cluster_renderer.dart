import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart'
  as gm_cluster;

import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/models/user_type.dart';
import 'package:core_ui/theme/app_colors.dart';

import 'marker_bitmap_helper.dart';
import 'wegig_cluster_models.dart';
import 'wegig_pin_descriptor_builder.dart';

class WeGigClusterRenderer {
  WeGigClusterRenderer({WeGigPinDescriptorBuilder? descriptorBuilder})
      : _pinDescriptorBuilder = descriptorBuilder ?? WeGigPinDescriptorBuilder();

  final WeGigPinDescriptorBuilder _pinDescriptorBuilder;
  final Map<_ClusterCacheKey, BitmapDescriptor> _clusterBadgeCache = {};

  Future<void> warmup() => _pinDescriptorBuilder.warmup();

  Future<Marker> buildMarker(
    gm_cluster.Cluster<WeGigClusterItem> cluster, {
    required Future<void> Function(PostEntity) onMarkerTap,
    ValueChanged<gm_cluster.Cluster<WeGigClusterItem>>? onClusterTap,
    bool Function(PostEntity post)? isActive,
  }) async {
    if (cluster.isMultiple) {
      final descriptor = await _clusterDescriptor(cluster);
      return Marker(
        markerId: MarkerId('cluster_${cluster.hashCode}'),
        position: cluster.location,
        icon: descriptor,
        anchor: const Offset(0.5, 0.5),
        onTap: () => onClusterTap?.call(cluster),
        zIndexInt: cluster.count.toDouble(),
      );
    }

    final item = cluster.items.first;
    final descriptor = await _pinDescriptorBuilder.getDescriptor(
      item.userType,
      isHighlighted: isActive?.call(item.post) ?? false,
    );
    return Marker(
      markerId: MarkerId(item.post.id),
      position: cluster.location,
      icon: descriptor,
      anchor: const Offset(0.5, 1.0),
      onTap: () => onMarkerTap(item.post),
      zIndexInt: cluster.count.toDouble(),
    );
  }

  Future<BitmapDescriptor> _clusterDescriptor(
    gm_cluster.Cluster<WeGigClusterItem> cluster,
  ) async {
    final color = _dominantColor(cluster);
    final key = _ClusterCacheKey(cluster.count, color.toARGB32());
    if (_clusterBadgeCache.containsKey(key)) {
      return _clusterBadgeCache[key]!;
    }

    final descriptor = await MarkerBitmapHelper.fromWidget(
      widget: _ClusterBadge(
        count: cluster.count,
        color: color,
      ),
      logicalSize: const Size(96, 96),
      pixelRatioMultiplier: 2.5,
    );

    _clusterBadgeCache[key] = descriptor;
    return descriptor;
  }

  Color _dominantColor(gm_cluster.Cluster<WeGigClusterItem> cluster) {
    final bandCount =
        cluster.items.where((item) => item.userType.isBand).length;
    return bandCount >= (cluster.count / 2)
        ? AppColors.accent
        : AppColors.primary;
  }
}

class _ClusterCacheKey {
  const _ClusterCacheKey(this.count, this.colorValue);

  final int count;
  final int colorValue;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ClusterCacheKey &&
        other.count == count &&
        other.colorValue == colorValue;
  }

  @override
  int get hashCode => Object.hash(count, colorValue);
}

class _ClusterBadge extends StatelessWidget {
  const _ClusterBadge({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final String label = count > 99 ? '99+' : count.toString();
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.95),
            color,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 24,
          ),
        ],
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
