import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:core_ui/models/user_type.dart';
import 'package:core_ui/theme/app_colors.dart';

import 'marker_bitmap_helper.dart';
import 'wegig_pin_widget.dart';

class WeGigPinDescriptorBuilder {
  WeGigPinDescriptorBuilder({
    this.logicalSize = const Size(46.9, 62.7),
    this.pixelRatioMultiplier = 3.0,
  });

  final Size logicalSize;
  final double pixelRatioMultiplier;

  static const List<String> _rgbPlaceholders = [
    'rgb(209,43,47)',
    'rgb(220,32,40)',
    'rgb(231,77,70)',
  ];

  static const List<String> _hexPlaceholders = [
    '#D12B2F',
    '#d12b2f',
    '#E74D46',
    '#e74d46',
  ];

  String? _baseSvg;
  final Map<UserType, String> _tintedSvgCache = {};
  final Map<_CacheKey, BitmapDescriptor> _descriptorCache = {};

  Future<void> warmup() async {
    await Future.wait([
      getDescriptor(UserType.band),
      getDescriptor(UserType.musician),
    ]);
  }

  Future<BitmapDescriptor> getDescriptor(
    UserType userType, {
    bool isHighlighted = false,
  }) async {
    final cacheKey = _CacheKey(userType, isHighlighted);
    if (_descriptorCache.containsKey(cacheKey)) {
      return _descriptorCache[cacheKey]!;
    }

    final svgContent = await _resolveSvg(userType);
    final widget = WeGigPinWidget(
      svgContent: svgContent,
      userType: userType,
      size: logicalSize.width,
      isHighlighted: isHighlighted,
    );

    final descriptor = await MarkerBitmapHelper.fromWidget(
      widget: widget,
      logicalSize: logicalSize,
      pixelRatioMultiplier: pixelRatioMultiplier,
    );

    _descriptorCache[cacheKey] = descriptor;
    return descriptor;
  }

  Future<String> _resolveSvg(UserType userType) async {
    _baseSvg ??= await rootBundle.loadString('assets/pin_template.svg');
    if (_tintedSvgCache.containsKey(userType)) {
      return _tintedSvgCache[userType]!;
    }

    final Color primaryColor =
      userType.isBand ? AppColors.accent : AppColors.primary;

    String tinted = _baseSvg!;

    for (final placeholder in _rgbPlaceholders) {
      tinted = tinted.replaceAll(placeholder, _toRgb(primaryColor));
    }

    for (final placeholder in _hexPlaceholders) {
      tinted = tinted.replaceAll(placeholder, _toHex(primaryColor));
    }

    _tintedSvgCache[userType] = tinted;
    return tinted;
  }

  String _toRgb(Color color) => 'rgb(${color.r.toInt()},${color.g.toInt()},${color.b.toInt()})';

  String _toHex(Color color) {
    String toHex(int value) => value.toRadixString(16).padLeft(2, '0');
    return '#${toHex(color.r.toInt())}${toHex(color.g.toInt())}${toHex(color.b.toInt())}'
        .toUpperCase();
  }
}

class _CacheKey {
  const _CacheKey(this.type, this.isHighlighted);

  final UserType type;
  final bool isHighlighted;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _CacheKey &&
        other.type == type &&
        other.isHighlighted == isHighlighted;
  }

  @override
  int get hashCode => Object.hash(type, isHighlighted);
}
