// Map Controller - Manages GoogleMap state and interactions
// Cloud-based Map Styling é usado via cloudMapId no GoogleMap widget
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapControllerWrapper {
  GoogleMapController? _controller;
  LatLng? _currentPosition;
  double _currentZoom = 12;
  LatLngBounds? _lastSearchBounds;
  bool _showSearchAreaButton = false;

  GoogleMapController? get controller => _controller;
  LatLng? get currentPosition => _currentPosition;
  double get currentZoom => _currentZoom;
  LatLngBounds? get lastSearchBounds => _lastSearchBounds;
  bool get showSearchAreaButton => _showSearchAreaButton;

  void setController(GoogleMapController controller) {
    _controller = controller;
  }

  void setCurrentPosition(LatLng position) {
    _currentPosition = position;
  }

  void setCurrentZoom(double zoom) {
    _currentZoom = zoom;
  }

  void setLastSearchBounds(LatLngBounds? bounds) {
    _lastSearchBounds = bounds;
  }

  void setShowSearchAreaButton(bool show) {
    _showSearchAreaButton = show;
  }

  Future<void> animateToPosition(LatLng position, double zoom) async {
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(position, zoom),
    );
  }

  Future<Position> determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  void dispose() {
    _controller?.dispose();
  }
}
