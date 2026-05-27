import 'dart:ui';

import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Overlay de carregamento global com blur premium
/// Usa cores da identidade visual para manter consistência no app.
class AppLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? backgroundColor;
  final double blurSigma;
  final String? message;
  final String? description;

  const AppLoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.backgroundColor,
    this.blurSigma = 16.0,
    this.message,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: blurSigma,
                      sigmaY: blurSigma,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: backgroundColor ??
                            Colors.black.withValues(alpha: 0.18),
                        gradient: backgroundColor == null
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.10),
                                  Colors.black.withValues(alpha: 0.20),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.96, end: 1),
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 304),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 28),
                          padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant.withValues(
                                    alpha: 0.08,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const AppBrandCircularLoader(
                                  size: 62,
                                  strokeWidth: 5,
                                ),
                              ),
                              if (message != null && message!.isNotEmpty) ...[
                                const SizedBox(height: 22),
                                Text(
                                  message!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                              if (description != null &&
                                  description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  description!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class AppBrandCircularLoader extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color color;
  final Color? backgroundColor;

  const AppBrandCircularLoader({
    super.key,
    this.size = 48,
    this.strokeWidth = 4,
    this.color = AppColors.accent,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        strokeCap: StrokeCap.round,
        color: color,
        backgroundColor: backgroundColor ??
            (color == Colors.white
                ? Colors.white.withValues(alpha: 0.28)
                : AppColors.surfaceContainerHighest.withValues(alpha: 0.7)),
      ),
    );
  }
}

class AppRadioPulseLoader extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const AppRadioPulseLoader({
    super.key,
    this.size = 48,
    this.color = AppColors.accent,
    this.strokeWidth = 4,
  });

  @override
  Widget build(BuildContext context) {
    return AppBrandCircularLoader(
      size: size,
      strokeWidth: strokeWidth,
      color: color,
    );
  }
}
