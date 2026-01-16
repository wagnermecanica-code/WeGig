import 'location_utils.dart';

/// Gerador de deep links para compartilhamento
class DeepLinkGenerator {
  // Base URL do app (domínio registrado)
  static const String baseUrl = 'https://wegig.com.br';
  
  /// Gera link para perfil
  static String generateProfileLink({
    required String userId,
    required String profileId,
  }) {
    return '$baseUrl/profile/$userId/$profileId';
  }
  
  /// Gera link para post
  static String generatePostLink({
    required String postId,
  }) {
    return '$baseUrl/post/$postId';
  }
  
  /// Gera mensagem de compartilhamento de perfil
  static String generateProfileShareMessage({
    required String name,
    required bool isBand,
    required String city,
    required String userId,
    required String profileId,
    String? neighborhood,
    String? state,
    List<String> instruments = const [],
    List<String> genres = const [],
  }) {
    final tipo = isBand ? 'Banda' : 'Músico';
    final link = generateProfileLink(userId: userId, profileId: profileId);
    final locationText = formatCleanLocation(
      neighborhood: neighborhood,
      city: city,
      state: state,
      fallback: city,
    );

    String message = '🎵 Confira este perfil no WeGig!\n\n';
    message += '📛 $name\n';
    message += '🎸 Tipo: $tipo\n';
    if (locationText.isNotEmpty) {
      message += '📍 $locationText\n';
    }
    
    if (instruments.isNotEmpty) {
      message += '🎹 Instrumentos: ${instruments.join(", ")}\n';
    }
    
    if (genres.isNotEmpty) {
      message += '🎼 Gêneros: ${genres.join(", ")}\n';
    }
    
    message += '\n🔗 Link:\n<$link>\n\n';
    message += 'Baixe o app e conecte-se com músicos na sua região!';
    
    return message;
  }
  
  /// Gera mensagem de compartilhamento de post
  static String generatePostShareMessage({
    required String postId,
    required String authorName,
    required String postType,
    required String city,
    String? neighborhood,
    String? state,
    String? content,
    List<String> instruments = const [],
    List<String> genres = const [],
    String? title,
    String? salesType,
    double? price,
    String? discountMode,
    double? discountValue,
  }) {
    final link = generatePostLink(postId: postId);
    final locationText = formatCleanLocation(
      neighborhood: neighborhood,
      city: city,
      state: state,
      fallback: city,
    );

    String message;
    
    if (postType == 'band') {
      // Banda procurando músicos
      message = '🎵 Banda procurando músicos no WeGig!\n\n';
      message += '🎸 Banda: $authorName\n';
      if (locationText.isNotEmpty) {
        message += '📍 $locationText\n';
      }
      
      if (content != null && content.isNotEmpty) {
        message += '\n💬 "$content"\n';
      }
      
      if (instruments.isNotEmpty) {
        message += '\n🔍 Procurando: ${instruments.join(", ")}';
      }
      
      if (genres.isNotEmpty) {
        message += '\n🎼 Gêneros: ${genres.join(", ")}';
      }
    } else if (postType == 'hiring') {
      // Contratação/divulgação de oportunidade
      message = '📣 Oportunidade de contratação no WeGig!\n\n';
      message += '🏢 $authorName\n';
      if (locationText.isNotEmpty) {
        message += '📍 $locationText\n';
      }

      if (content != null && content.isNotEmpty) {
        message += '\n💬 "$content"\n';
      }

      if (instruments.isNotEmpty) {
        message += '\n🎯 Perfil desejado: ${instruments.join(", ")}';
      }

      if (genres.isNotEmpty) {
        message += '\n🎼 Gêneros: ${genres.join(", ")}';
      }
    } else if (postType == 'sales') {
      // Anúncio/venda
      final titleText = (title != null && title.isNotEmpty) ? title : 'Anúncio';
      message = '🏷️ Anúncio no WeGig!\n\n';
      message += '📦 $titleText\n';
      message += '👤 $authorName\n';
      if (locationText.isNotEmpty) {
        message += '📍 $locationText\n';
      }

      if (content != null && content.isNotEmpty) {
        message += '\n💬 "$content"\n';
      }

      if (salesType != null && salesType.isNotEmpty) {
        message += '\n🗂️ Categoria: $salesType';
      }

      if (price != null && price > 0) {
        message += '\n💰 Preço: ${_formatPrice(price)}';
      }

      final discountLabel = _formatDiscountLabel(discountMode, discountValue);
      if (discountLabel.isNotEmpty) {
        message += '\n🏷️ Desconto: $discountLabel';
      }
    } else {
      // Músico procurando banda
      message = '🎵 Músico procurando banda no WeGig!\n\n';
      message += '👤 $authorName\n';
      if (locationText.isNotEmpty) {
        message += '📍 $locationText\n';
      }
      
      if (content != null && content.isNotEmpty) {
        message += '\n💬 "$content"\n';
      }
      
      if (instruments.isNotEmpty) {
        message += '\n🎹 Instrumentos: ${instruments.join(", ")}';
      }
      
      if (genres.isNotEmpty) {
        message += '\n🎼 Gêneros: ${genres.join(", ")}';
      }
    }
    
    message += '\n🔗 Link:\n<$link>\n\n';
    message += 'Baixe o app e conecte-se com músicos na sua região!';
    
    return message;
  }

  static String _formatPrice(double value) {
    final normalized = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $normalized';
  }

  static String _formatDiscountLabel(String? mode, double? value) {
    if (value == null || value <= 0) return '';
    if (mode == 'percentage') {
      final percent = value.toStringAsFixed(0);
      return '$percent%';
    }
    if (mode == 'fixed') {
      return _formatPrice(value);
    }
    return '';
  }
}
