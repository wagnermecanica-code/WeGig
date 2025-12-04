import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

/// Helper para converter um widget em [BitmapDescriptor] com controle de
/// resolução. Encapsula o package `widget_to_marker` para manter a
/// configuração centralizada.
class MarkerBitmapHelper {
  const MarkerBitmapHelper._();

  static Future<BitmapDescriptor> fromWidget({
    required Widget widget,
    Size logicalSize = const Size(96, 128),
    double pixelRatioMultiplier = 3.0,
    Duration waitToRender = const Duration(milliseconds: 80),
  }) async {
    return widget.toBitmapDescriptor(
      logicalSize: logicalSize,
      imageSize: Size(
        logicalSize.width * pixelRatioMultiplier,
        logicalSize.height * pixelRatioMultiplier,
      ),
      waitToRender: waitToRender,
    );
  }
}
