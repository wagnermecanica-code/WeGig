import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart'
  as gm_cluster;

import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/models/user_type.dart';

/// Item básico usado pelo Maps Cluster Manager.
class WeGigClusterItem with gm_cluster.ClusterItem {
  WeGigClusterItem(this.post)
      : _location = LatLng(
          post.location.latitude,
          post.location.longitude,
        );

  final PostEntity post;
  final LatLng _location;

  @override
  LatLng get location => _location;

  UserType get userType => userTypeFromPostType(post.type);
}
