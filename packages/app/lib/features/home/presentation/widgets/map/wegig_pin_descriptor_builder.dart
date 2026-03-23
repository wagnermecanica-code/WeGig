import 'dart:io' show Platform;
import 'dart:math' as math;
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
    Size? logicalSize,
    double? pixelRatioMultiplier,
  })  : logicalSize = logicalSize ?? _defaultLogicalSize,
        pixelRatioMultiplier = pixelRatioMultiplier ?? _defaultPixelRatio;

  /// Tamanho lógico padrão ajustado por densidade e tamanho de tela.
  static Size get _defaultLogicalSize => _responsiveLogicalSize();

  /// Aspect ratio do pin (altura / largura) alinhado ao widget.
  static const double _pinHeightRatio = 1.28;

  /// Fallback para casos sem view disponível.
  static Size get _fallbackLogicalSize => Platform.isAndroid
      ? const Size(32.0, 41.0)
      : const Size(46.0, 59.0);

  /// Calcula tamanho responsivo a partir do viewport lógico.
  static Size _responsiveLogicalSize() {
    final views = PlatformDispatcher.instance.views;
    if (views.isEmpty) return _fallbackLogicalSize;

    final view = views.first;
    final pixelRatio = view.devicePixelRatio == 0 ? _defaultPixelRatio : view.devicePixelRatio;
    final logicalWidth = view.physicalSize.width / pixelRatio;
    final logicalHeight = view.physicalSize.height / pixelRatio;
    final shortestSide = math.min(logicalWidth, logicalHeight);

    // Usa ~8% do lado menor, com limites para telas pequenas/grandes.
    final base = (shortestSide * 0.08).clamp(28.0, Platform.isAndroid ? 46.0 : 54.0);
    // Android já está aumentado; iOS recebe +50% para visibilidade melhor no mapa.
    final platformScale = Platform.isAndroid ? 1.33 : 1.5;
    final width = base * platformScale;

    return Size(width, width * _pinHeightRatio);
  }

  /// Pixel ratio padrão ajustado por plataforma
  static double get _defaultPixelRatio => Platform.isAndroid ? 2.5 : 3.0;

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
      getDescriptor(UserType.sales),
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

    final Color primaryColor = switch (userType) {
      UserType.band => AppColors.accent,
      UserType.sales => AppColors.salesColor,
      UserType.hiring => AppColors.hiringColor,
      UserType.musician => AppColors.musicianColor,
    };

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

  /// Converte Color para string RGB no formato 'rgb(R,G,B)'.
  /// NOTA: No Flutter 3.x+, color.r/g/b retornam valores 0.0-1.0, não 0-255.
  /// Usamos color.red/green/blue que retornam int 0-255.
  String _toRgb(Color color) => 'rgb(${color.red},${color.green},${color.blue})';

  /// Converte Color para string hexadecimal no formato '#RRGGBB'.
  /// NOTA: No Flutter 3.x+, color.r/g/b retornam valores 0.0-1.0, não 0-255.
  /// Usamos color.red/green/blue que retornam int 0-255.
  String _toHex(Color color) {
    String toHex(int value) => value.toRadixString(16).padLeft(2, '0');
    return '#${toHex(color.red)}${toHex(color.green)}${toHex(color.blue)}'
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
