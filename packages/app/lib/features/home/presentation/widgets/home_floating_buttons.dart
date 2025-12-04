// WEGIG – HOME FLOATING BUTTONS
// Extracted from HomePage for better maintainability
// Handles GPS and close card floating buttons

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class HomeFloatingButtons extends StatelessWidget {
  const HomeFloatingButtons({
    super.key,
    required this.onCenterLocation,
    required this.onCloseCard,
    required this.isCenteringLocation,
    required this.showCloseButton,
  });

  final VoidCallback onCenterLocation;
  final VoidCallback onCloseCard;
  final bool isCenteringLocation;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: showCloseButton ? 240 : 180,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // GPS Center Button
          FloatingActionButton(
            heroTag: 'gps_button',
            mini: true,
            backgroundColor: Colors.white,
            onPressed: isCenteringLocation ? null : onCenterLocation,
            child: isCenteringLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Iconsax.gps, color: Colors.blue, size: 22),
          ),
          
          // Close Card Button (conditional)
          if (showCloseButton) ...[
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'close_button',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: onCloseCard,
              child: const Icon(Iconsax.close_circle, color: Colors.grey, size: 22),
            ),
          ],
        ],
      ),
    );
  }
}
