// WEGIG – HOME MAP WIDGET
// Extracted from HomePage for better maintainability
// Handles Google Maps display with markers

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wegig_app/features/home/presentation/widgets/map/map_controller.dart';

class HomeMapWidget extends StatelessWidget {
  const HomeMapWidget({
    super.key,
    required this.mapControllerWrapper,
    required this.markers,
    required this.onMapCreated,
    required this.onMapIdle,
    required this.onCameraMove,
  });

  final MapControllerWrapper mapControllerWrapper;
  final Set<Marker> markers;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onMapIdle;
  final Function(CameraPosition) onCameraMove;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: const CameraPosition(
        target: LatLng(-23.5505, -46.6333), // São Paulo default
        zoom: 12,
      ),
      onMapCreated: (controller) {
        mapControllerWrapper.setController(controller);
        // Note: applyMapStyle() moved to MapControllerWrapper.setController()
        onMapCreated(controller);
      },
      markers: markers,
      onCameraIdle: onMapIdle,
      onCameraMove: onCameraMove,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: false,
      zoomGesturesEnabled: true,
    );
  }
}
