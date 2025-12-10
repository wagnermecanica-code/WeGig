/// WeGig - NotificationNew Error State
///
/// Widget para exibir estado de erro com botão de retry.
/// Usado quando falha o carregamento de notificações.
library;

import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Widget para estado de erro com retry
///
/// Exibe mensagem de erro e botão para tentar novamente.
class NotificationNewErrorState extends StatelessWidget {
  /// Cria estado de erro
  const NotificationNewErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  /// Mensagem de erro a exibir
  final String message;

  /// Callback para retry
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone de erro
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.warning_2,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            // Título
            const Text(
              'Algo deu errado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Mensagem
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            // Botão retry
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
