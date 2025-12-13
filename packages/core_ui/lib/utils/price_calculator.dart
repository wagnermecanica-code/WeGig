import 'package:core_ui/features/post/domain/entities/post_entity.dart';

/// Utilitário para cálculos de preços de posts
class PriceCalculator {
  /// Calcula o preço final aplicando desconto sobre o preço original
  static double calculateFinalPrice(PostEntity post) {
    final originalPrice = post.price ?? 0.0;
    final discountMode = post.discountMode ?? 'none';
    final discountValue = post.discountValue ?? 0.0;

    if (discountMode == 'percentage' && discountValue > 0) {
      // Desconto percentual: final = original * (1 - desconto%/100)
      return originalPrice * (1 - discountValue / 100);
    } else if (discountMode == 'fixed' && discountValue > 0) {
      // Desconto fixo: final = original - valor fixo
      return originalPrice - discountValue;
    }
    return originalPrice;
  }

  /// Verifica se o post tem desconto válido
  static bool hasDiscount(PostEntity post) {
    final discountMode = post.discountMode;
    final discountValue = post.discountValue ?? 0.0;
    return discountMode != null &&
           discountMode != 'none' &&
           discountValue > 0;
  }

  /// Gera o label do desconto (ex: "-50%" ou "-R$ 20,00")
  static String getDiscountLabel(PostEntity post) {
    final discountMode = post.discountMode ?? 'none';
    final discountValue = post.discountValue ?? 0.0;

    if (discountMode == 'percentage') {
      return '-${discountValue.toStringAsFixed(0)}%';
    } else if (discountMode == 'fixed') {
      return '-R\$ ${discountValue.toStringAsFixed(2).replaceAll('.', ',')}';
    }
    return '';
  }

  /// Retorna dados completos de preço para exibição
  static PriceDisplayData getPriceDisplayData(PostEntity post) {
    final originalPrice = post.price ?? 0.0;
    final hasDiscount = PriceCalculator.hasDiscount(post);
    final finalPrice = calculateFinalPrice(post);
    final discountLabel = hasDiscount ? getDiscountLabel(post) : null;

    return PriceDisplayData(
      originalPrice: originalPrice,
      finalPrice: finalPrice,
      hasDiscount: hasDiscount,
      discountLabel: discountLabel,
    );
  }
}

/// Dados de exibição de preço calculados
class PriceDisplayData {
  const PriceDisplayData({
    required this.originalPrice,
    required this.finalPrice,
    required this.hasDiscount,
    this.discountLabel,
  });

  final double originalPrice;
  final double finalPrice;
  final bool hasDiscount;
  final String? discountLabel;
}