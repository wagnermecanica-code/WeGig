/// WeGig - NotificationNew Empty State
///
/// Widget para exibir estado vazio (sem notificações).
/// Mostra ilustração e mensagem amigável.
library;

import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Widget para estado vazio de notificações
///
/// Exibe ilustração e mensagem quando não há notificações.
class NotificationNewEmptyState extends StatelessWidget {
  /// Cria estado vazio
  const NotificationNewEmptyState({
    this.isInterestsTab = false,
    super.key,
  });

  /// Se true, mostra mensagem específica para aba de interesses
  final bool isInterestsTab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone ilustrativo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isInterestsTab ? Iconsax.heart : Iconsax.notification,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            // Título
            Text(
              isInterestsTab
                  ? 'Nenhum interesse ainda'
                  : 'Nenhuma notificação',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // Mensagem
            Text(
              isInterestsTab
                  ? 'Quando alguém demonstrar interesse em seus posts, você verá aqui.'
                  : 'Você receberá notificações sobre interesses, mensagens e novidades.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
