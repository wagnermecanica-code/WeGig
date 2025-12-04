import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Widget de transição animada ao trocar de perfil
/// Exibe overlay com animação de fade e profile info
class ProfileTransitionOverlay extends StatefulWidget {
  const ProfileTransitionOverlay({
    required this.profileName,
    required this.isBand,
    required this.onComplete,
    super.key,
    this.photoUrl,
  });
  final String profileName;
  final bool isBand;
  final String? photoUrl;
  final VoidCallback onComplete;

  @override
  State<ProfileTransitionOverlay> createState() =>
      _ProfileTransitionOverlayState();

  /// Mostra o overlay de transição
  /// Retorna um Future que completa quando o overlay é fechado
  static Future<void> show(
    BuildContext context, {
    required String profileName,
    required bool isBand,
    required VoidCallback onComplete,
    String? photoUrl,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => ProfileTransitionOverlay(
        profileName: profileName,
        isBand: isBand,
        photoUrl: photoUrl,
        onComplete: onComplete,
      ),
    );
  }
}

class _ProfileTransitionOverlayState extends State<ProfileTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Inicia animação e fecha após completar
    _controller.forward().then((_) {
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isBand ? AppColors.accent : AppColors.primary;
    final lightColor =
        widget.isBand ? AppColors.accentLight : AppColors.primaryLight;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar com animação de pulso
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: lightColor,
                    backgroundImage:
                        widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(widget.photoUrl!)
                            : null,
                    child: widget.photoUrl == null || widget.photoUrl!.isEmpty
                        ? Icon(
                            widget.isBand ? Iconsax.people : Iconsax.user,
                            size: 50,
                            color: color,
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 24),

                // Texto "Trocando para..."
                Text(
                  'Trocando para',
                  style: AppTypography.captionLight.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                // Nome do perfil
                Text(
                  widget.profileName,
                  style: AppTypography.headlineLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Badge de tipo (músico/banda)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: lightColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isBand ? Icons.groups : Icons.person,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.isBand ? 'Banda' : 'Músico',
                        style: AppTypography.captionLight.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Loading indicator
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
