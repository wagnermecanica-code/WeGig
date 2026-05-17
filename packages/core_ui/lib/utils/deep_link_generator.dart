import 'package:core_ui/utils/location_utils.dart';

/// Gerador de deep links para compartilhamento
class DeepLinkGenerator {
  // Base URL do app (domínio registrado)
  static const String baseUrl = 'https://wegig.com.br';

  static const int _maxPreviewTextLength = 140;
  static const int _maxListItems = 4;

  /// Gera link para perfil
  static String generateProfileLink({
    required String profileId,
    String? userId,
  }) {
    return _generateShareLink(type: 'profile', id: profileId);
  }

  /// Gera link para post
  static String generatePostLink({
    required String postId,
  }) {
    return _generateShareLink(type: 'post', id: postId);
  }

  static String _generateShareLink({
    required String type,
    required String id,
  }) {
    return Uri.parse('$baseUrl/share.html').replace(
      queryParameters: <String, String>{
        'type': type,
        'id': id,
      },
    ).toString();
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
    final details = <String>[
      tipo,
      if (locationText.isNotEmpty) locationText,
      if (instruments.isNotEmpty) _compactList(instruments),
      if (genres.isNotEmpty) _compactList(genres),
    ];

    return _composeShareMessage(
      headline: 'Conheça $name no WeGig',
      details: details,
      callToAction: 'Abra o perfil e conecte-se pela sua rede musical:',
      link: link,
    );
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

    final headline = _postShareHeadline(
      postType: postType,
      authorName: authorName,
      title: title,
    );
    final details = <String>[
      if (locationText.isNotEmpty) locationText,
    ];

    final previewText = _compactPreviewText(content);
    if (previewText.isNotEmpty) {
      details.add('"$previewText"');
    }

    if (postType == 'band') {
      if (instruments.isNotEmpty) {
        details.add('Procura: ${_compactList(instruments)}');
      }
      if (genres.isNotEmpty) {
        details.add('Som: ${_compactList(genres)}');
      }
    } else if (postType == 'hiring') {
      if (instruments.isNotEmpty) {
        details.add('Perfil desejado: ${_compactList(instruments)}');
      }
      if (genres.isNotEmpty) {
        details.add('Estilo: ${_compactList(genres)}');
      }
    } else if (postType == 'sales') {
      if (salesType != null && salesType.isNotEmpty) {
        details.add(salesType);
      }
      if (price != null && price > 0) {
        details.add(_formatPrice(price));
      }
      final discountLabel = _formatDiscountLabel(discountMode, discountValue);
      if (discountLabel.isNotEmpty) {
        details.add('Desconto: $discountLabel');
      }
    } else {
      if (instruments.isNotEmpty) {
        details.add(_compactList(instruments));
      }
      if (genres.isNotEmpty) {
        details.add(_compactList(genres));
      }
    }

    return _composeShareMessage(
      headline: headline,
      details: details,
      callToAction: 'Veja o post no WeGig:',
      link: link,
    );
  }

  static String _composeShareMessage({
    required String headline,
    required List<String> details,
    required String callToAction,
    required String link,
  }) {
    final visibleDetails = details
        .map((detail) => detail.trim())
        .where((detail) => detail.isNotEmpty)
        .take(4)
        .toList(growable: false);

    return [
      headline.trim(),
      if (visibleDetails.isNotEmpty) visibleDetails.join(' • '),
      callToAction.trim(),
      link,
    ].join('\n\n');
  }

  static String _postShareHeadline({
    required String postType,
    required String authorName,
    String? title,
  }) {
    final cleanAuthor = authorName.trim().isEmpty ? 'WeGig' : authorName.trim();
    final cleanTitle = title?.trim() ?? '';

    if (postType == 'band') {
      return '$cleanAuthor está procurando músicos';
    }
    if (postType == 'hiring') {
      return '$cleanAuthor publicou uma oportunidade';
    }
    if (postType == 'sales') {
      return cleanTitle.isEmpty
          ? '$cleanAuthor publicou um anúncio'
          : '$cleanTitle no WeGig';
    }
    return '$cleanAuthor está procurando banda';
  }

  static String _compactPreviewText(String? value) {
    final normalized = (value ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= _maxPreviewTextLength) {
      return normalized;
    }
    return '${normalized.substring(0, _maxPreviewTextLength - 1).trimRight()}…';
  }

  static String _compactList(List<String> values) {
    final normalized = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (normalized.length <= _maxListItems) {
      return normalized.join(', ');
    }

    final visible = normalized.take(_maxListItems).join(', ');
    final remaining = normalized.length - _maxListItems;
    return '$visible +$remaining';
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
