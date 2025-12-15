/// WeGig - NotificationNew Skeleton Tile
///
/// Skeleton loading placeholder para item de notificação.
/// Usado durante carregamento inicial para melhor UX.
library;

import 'package:flutter/material.dart';

/// Widget skeleton para item de notificação
///
/// Mostra placeholder animado enquanto dados carregam.
/// Segue dimensões do NotificationNewItem real.
class NotificationNewSkeletonTile extends StatelessWidget {
  /// Cria skeleton tile
  const NotificationNewSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar skeleton
          const _SkeletonBox(
            width: 48,
            height: 48,
            borderRadius: 24,
          ),
          const SizedBox(width: 12),
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                const _SkeletonBox(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                // Message skeleton (2 lines)
                const _SkeletonBox(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 4),
                _SkeletonBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                // Time skeleton
                const _SkeletonBox(
                  width: 80,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Box com shimmer effect para skeleton
class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
