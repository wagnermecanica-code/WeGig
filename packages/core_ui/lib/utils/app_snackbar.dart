import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Utility class for showing consistent SnackBars across the app
/// 
/// Features:
/// - Automatic mounted check (prevents crashes)
/// - Consistent styling (icons, colors, animations)
/// - Three types: success, error, info
/// - Optional retry action for errors
/// 
/// Usage:
/// ```dart
/// AppSnackBar.showSuccess(context, 'Post criado com sucesso!');
/// AppSnackBar.showError(context, 'Erro ao deletar', onRetry: _retry);
/// AppSnackBar.showInfo(context, 'Aguarde...');
/// ```
class AppSnackBar {
  AppSnackBar._(); // Private constructor

  /// Show success message (green with check icon)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.tick_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show error message (red with error icon)
  /// 
  /// Optionally provide [onRetry] callback for retry action
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onRetry,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.close_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Tentar Novamente',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show info message (blue with info icon)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.info_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show warning message (orange with warning icon)
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.danger, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Mostra uma mensagem flutuante usando o `Overlay` raiz.
  ///
  /// Use esta variante quando a chamada vem de dentro de um
  /// `showModalBottomSheet` (ou outro overlay), pois o `ScaffoldMessenger`
  /// ancora a `SnackBar` no `Scaffold` da página por baixo do sheet,
  /// deixando-a invisível para o usuário.
  static void showOverlayError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showOverlay(
      context,
      message: message,
      icon: Iconsax.close_circle,
      background: Colors.red,
      duration: duration,
    );
  }

  /// Variante de sucesso para uso em bottom sheets / overlays.
  static void showOverlaySuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showOverlay(
      context,
      message: message,
      icon: Iconsax.tick_circle,
      background: Colors.green,
      duration: duration,
    );
  }

  /// Variante de aviso para uso em bottom sheets / overlays.
  static void showOverlayWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showOverlay(
      context,
      message: message,
      icon: Iconsax.danger,
      background: Colors.orange,
      duration: duration,
    );
  }

  static void _showOverlay(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color background,
    required Duration duration,
  }) {
    if (!context.mounted) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom; // teclado
    final safeBottom = mediaQuery.padding.bottom;

    entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          left: 16,
          right: 16,
          bottom: 16 + bottomInset + safeBottom,
          child: _OverlayToast(
            message: message,
            icon: icon,
            background: background,
            duration: duration,
            onDismissed: () {
              if (entry.mounted) entry.remove();
            },
          ),
        );
      },
    );

    overlay.insert(entry);
  }
}

class _OverlayToast extends StatefulWidget {
  const _OverlayToast({
    required this.message,
    required this.icon,
    required this.background,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final IconData icon;
  final Color background;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_OverlayToast> createState() => _OverlayToastState();
}

class _OverlayToastState extends State<_OverlayToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.3),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    _dismissTimer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.background,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(color: Colors.white),
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
