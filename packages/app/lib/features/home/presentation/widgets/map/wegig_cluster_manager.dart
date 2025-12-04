import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart'
    as gm_cluster;

import 'package:core_ui/features/post/domain/entities/post_entity.dart';

import 'wegig_cluster_models.dart';
import 'wegig_cluster_renderer.dart';

typedef MarkerUpdateCallback = void Function(Set<Marker> markers);

class WeGigClusterManager {
  WeGigClusterManager({
    required Future<void> Function(PostEntity) onMarkerTap,
    required MarkerUpdateCallback onMarkersUpdated,
    ValueChanged<gm_cluster.Cluster<WeGigClusterItem>>? onClusterTap,
    bool Function(PostEntity post)? isActive,
    double stopClusteringZoom = 15,
  })  : _onMarkerTap = onMarkerTap,
        _onMarkersUpdated = onMarkersUpdated,
        _isActive = isActive ?? ((_) => false),
        _renderer = WeGigClusterRenderer() {
    _clusterManager = gm_cluster.ClusterManager<WeGigClusterItem>(
      [],
      _onMarkersUpdated,
      markerBuilder: (cluster) => _renderer.buildMarker(
        cluster,
        onMarkerTap: _onMarkerTap,
        onClusterTap: onClusterTap,
        isActive: _isActive,
      ),
      stopClusteringZoom: stopClusteringZoom,
    );
  }

  late final gm_cluster.ClusterManager<WeGigClusterItem> _clusterManager;
  final Future<void> Function(PostEntity) _onMarkerTap;
  final MarkerUpdateCallback _onMarkersUpdated;
  final bool Function(PostEntity post) _isActive;
  final WeGigClusterRenderer _renderer;

  Future<void> setItems(List<PostEntity> posts) async {
    await _clusterManager.setItems(posts.map(WeGigClusterItem.new).toList());
  }

  void onCameraMove(CameraPosition position) {
    _clusterManager.onCameraMove(position);
  }

  Future<void> updateMap() => _clusterManager.updateMap();

  Future<void> setMapId(int mapId) async {
    await _clusterManager.setMapId(mapId);
  }

  Future<void> warmup() async {
    await _renderer.warmup();
  }

  void dispose() {
    _clusterManager.dispose();
  }
}
