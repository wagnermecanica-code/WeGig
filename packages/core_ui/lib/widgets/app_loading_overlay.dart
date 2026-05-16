import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:core_ui/theme/app_colors.dart';

/// Overlay de carregamento global com blur premium
/// Usa cor laranja (#E47911) para identidade visual consistente
class AppLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? backgroundColor;
  final double blurSigma;

  const AppLoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.backgroundColor,
    this.blurSigma = 16.0,
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
                    child: Container(
                      color: (backgroundColor ?? Colors.black.withOpacity(0.15)),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const SizedBox(
                        width: 72,
                        height: 72,
                        child: AppRadioPulseLoader(),
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

class AppRadioPulseLoader extends StatefulWidget {
  final double size;
  final Color color;

  const AppRadioPulseLoader({
    Key? key,
    this.size = 48,
    this.color = AppColors.accent,
  }) : super(key: key);

  @override
  State<AppRadioPulseLoader> createState() => _AppRadioPulseLoaderState();
}

class _AppRadioPulseLoaderState extends State<AppRadioPulseLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              _PulseRing(
                size: widget.size,
                color: widget.color,
                progress: _ringProgress(progress, 0.0),
              ),
              _PulseRing(
                size: widget.size,
                color: widget.color,
                progress: _ringProgress(progress, 0.22),
              ),
              _PulseRing(
                size: widget.size,
                color: widget.color,
                progress: _ringProgress(progress, 0.44),
              ),
              Container(
                width: widget.size * 0.2,
                height: widget.size * 0.2,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.28),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _ringProgress(double progress, double delay) {
    final shifted = (progress - delay) % 1.0;
    return shifted < 0 ? shifted + 1.0 : shifted;
  }
}

class _PulseRing extends StatelessWidget {
  final double size;
  final Color color;
  final double progress;

  const _PulseRing({
    required this.size,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final curve = Curves.easeOut.transform(progress);
    final ringSize = lerpDouble(size * 0.18, size, curve) ?? size;
    final opacity = (1 - curve).clamp(0.0, 1.0) * 0.9;
    final strokeWidth = lerpDouble(3.2, 1.0, curve) ?? 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        width: ringSize,
        height: ringSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: strokeWidth,
          ),
        ),
      ),
    );
  }
}
