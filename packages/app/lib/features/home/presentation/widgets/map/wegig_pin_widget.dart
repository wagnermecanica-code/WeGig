import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:core_ui/models/user_type.dart';
import 'package:core_ui/theme/app_colors.dart';

/// Widget responsável por desenhar o marcador em formato de gota usando SVG.
///
/// O SVG base vem de [assets/pin_template.svg] e recebe uma cor dinâmica
/// para o preenchimento antes de ser convertido em [BitmapDescriptor].
class WeGigPinWidget extends StatelessWidget {
  const WeGigPinWidget({
    super.key,
    required this.svgContent,
    required this.userType,
    required this.size,
    this.isHighlighted = false,
  });

  /// Conteúdo SVG já com a cor substituída.
  final String svgContent;

  /// Tipo do usuário (define cor e ícone interno).
  final UserType userType;

  /// Largura base do marcador.
  final double size;

  /// Quando verdadeiro aplica um brilho suave no pin ativo.
  final bool isHighlighted;

  static const double _heightRatio = 1.28;

  Color get _primaryColor =>
      userType.isBand ? AppColors.accent : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * _heightRatio,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (isHighlighted)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: size * 1.15,
                    height: size * _heightRatio * 1.15,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: size * 0.12,
                        sigmaY: size * 0.12,
                      ),
                      child: Opacity(
                        opacity: 0.45,
                        child: SvgPicture.string(
                          svgContent,
                          fit: BoxFit.contain,
                          allowDrawingOutsideViewBox: true,
                          colorFilter: ColorFilter.mode(
                            _primaryColor.withValues(alpha: 0.9),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: SvgPicture.string(
              svgContent,
              fit: BoxFit.contain,
              allowDrawingOutsideViewBox: true,
            ),
          ),
        ],
      ),
    );
  }
}
