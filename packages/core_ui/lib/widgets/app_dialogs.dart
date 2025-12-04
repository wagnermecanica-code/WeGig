import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Utility class for showing consistent dialogs across the app
/// 
/// Features:
/// - Automatic mounted check (prevents crashes)
/// - Consistent styling (colors, spacing, animations)
/// - Three types: confirmation, loading, error
/// - Destructive action support with red button
/// 
/// Usage:
/// ```dart
/// final confirmed = await AppDialogs.showConfirmation(
///   context,
///   'Deletar Post?',
///   'Esta ação não pode ser desfeita.',
///   isDestructive: true,
/// );
/// if (confirmed == true) { /* delete */ }
/// 
/// AppDialogs.showLoading(context, 'Carregando...');
/// await someLongOperation();
/// Navigator.pop(context);
/// 
/// AppDialogs.showError(context, 'Erro ao salvar', onRetry: _retry);
/// ```
class AppDialogs {
  AppDialogs._(); // Private constructor

  /// Show confirmation dialog with Yes/No buttons
  /// 
  /// Returns true if user taps "Confirmar", false if "Cancelar", null if dismissed
  /// 
  /// Set [isDestructive] to true for dangerous actions (delete, logout, etc.)
  /// which will show the confirm button in red
  static Future<bool?> showConfirmation(
    BuildContext context,
    String title,
    String message, {
    bool isDestructive = false,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) async {
    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              isDestructive ? Iconsax.danger : Iconsax.info_circle,
              color: isDestructive ? Colors.red : Colors.blue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Show loading dialog with message and timeout
  /// 
  /// IMPORTANT: Caller must pop the dialog when done:
  /// ```dart
  /// AppDialogs.showLoading(context, 'Salvando...');
  /// await saveData();
  /// if (context.mounted) Navigator.pop(context);
  /// ```
  /// 
  /// [timeout] automatically dismisses dialog after duration (default 30s)
  static Future<void> showLoading(
    BuildContext context,
    String message, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button dismissal
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Auto-dismiss after timeout
    Future.delayed(timeout, () {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  /// Show error dialog with optional retry action
  /// 
  /// Returns true if user taps "Tentar Novamente", false if "Fechar"
  static Future<bool?> showError(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    String title = 'Erro',
  }) async {
    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Iconsax.danger, color: Colors.red),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tentar Novamente'),
            ),
        ],
      ),
    );
  }

  /// Show success dialog with checkmark animation
  /// 
  /// Auto-dismisses after 2 seconds
  static Future<void> showSuccess(
    BuildContext context,
    String message, {
    String title = 'Sucesso',
    Duration duration = const Duration(seconds: 2),
  }) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.tick_circle,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    // Auto-dismiss
    Future.delayed(duration, () {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  /// Show info dialog with single OK button
  static Future<void> showInfo(
    BuildContext context,
    String title,
    String message,
  ) async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Iconsax.info_circle, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
