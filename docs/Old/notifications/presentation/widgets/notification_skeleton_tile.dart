import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';

class NotificationSkeletonTile extends StatelessWidget {
  const NotificationSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          const SkeletonLoader(
            width: 48,
            height: 48,
            borderRadius: 24,
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const SkeletonLoader(
                  width: 150,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                // Message
                const SkeletonLoader(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 4),
                const SkeletonLoader(
                  width: 200,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                // Time
                const SkeletonLoader(
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
