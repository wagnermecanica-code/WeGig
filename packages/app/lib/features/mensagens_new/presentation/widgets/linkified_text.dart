import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget que renderiza texto com links clicáveis
///
/// Suporta:
/// - URLs web (http/https)
/// - Deep links do WeGig (wegig.app/profile/*, wegig.app/post/*)
/// - Links personalizados para navegação interna
class LinkifiedText extends StatefulWidget {
  const LinkifiedText({
    required this.text,
    required this.style,
    this.linkStyle,
    this.onProfileTap,
    this.onPostTap,
    this.onConversationTap,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    super.key,
  });

  /// Texto a ser renderizado
  final String text;

  /// Estilo base do texto
  final TextStyle style;

  /// Estilo dos links (se null, usa style com cor accent e sublinhado)
  final TextStyle? linkStyle;

  /// Callback quando um link de perfil WeGig é tocado
  /// Recebe o profileId extraído do deep link
  final void Function(String profileId)? onProfileTap;

  /// Callback quando um link de post WeGig é tocado
  /// Recebe o postId extraído do deep link
  final void Function(String postId)? onPostTap;

  /// Callback quando um link de conversa WeGig é tocado
  /// Recebe o conversationId extraído do deep link
  final void Function(String conversationId)? onConversationTap;

  /// Número máximo de linhas
  final int? maxLines;

  /// Comportamento de overflow
  final TextOverflow overflow;

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Limpa recognizers antigos
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final spans = _buildTextSpans();

    return Text.rich(
      TextSpan(children: spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }

  List<InlineSpan> _buildTextSpans() {
    final text = widget.text;
    final spans = <InlineSpan>[];

    // Regex para detectar URLs (incluindo deep links do WeGig)
    // Captura URLs com http/https e também wegig.com.br sem protocolo
    final urlRegex = RegExp(
      r'(https?://[^\s<>\[\]]+|wegig\.com\.br/[^\s<>\[\]]+)',
      caseSensitive: false,
    );

    int lastEnd = 0;
    final matches = urlRegex.allMatches(text);

    for (final match in matches) {
      // Texto antes do link
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: widget.style,
        ));
      }

      // O link em si
      String url = match.group(0)!;
      
      // Remove caracteres de pontuação no final (., ,, ), >, etc.)
      while (url.isNotEmpty && _isTrailingPunctuation(url[url.length - 1])) {
        url = url.substring(0, url.length - 1);
      }

      final linkSpan = _buildLinkSpan(url);
      spans.add(linkSpan);

      lastEnd = match.start + url.length;
      
      // Adiciona a pontuação removida como texto normal
      if (match.end > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.end),
          style: widget.style,
        ));
        lastEnd = match.end;
      }
    }

    // Texto após o último link
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: widget.style,
      ));
    }

    // Se não encontrou nenhum link, retorna o texto simples
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: widget.style));
    }

    return spans;
  }

  bool _isTrailingPunctuation(String char) {
    return ['.', ',', ')', '>', ']', ';', ':', '!', '?'].contains(char);
  }

  TextSpan _buildLinkSpan(String url) {
    final recognizer = TapGestureRecognizer();
    _recognizers.add(recognizer);

    // Detecta tipo de deep link do WeGig
    final deepLinkInfo = _parseWeGigDeepLink(url);

    if (deepLinkInfo != null) {
      // É um deep link do WeGig
      recognizer.onTap = () => _handleWeGigDeepLink(deepLinkInfo);
      
      return TextSpan(
        text: _formatDeepLinkDisplay(deepLinkInfo),
        style: _getLinkStyle(),
        recognizer: recognizer,
      );
    } else {
      // É uma URL externa
      recognizer.onTap = () => _launchUrl(url);
      
      return TextSpan(
        text: _formatExternalUrlDisplay(url),
        style: _getLinkStyle(),
        recognizer: recognizer,
      );
    }
  }

  TextStyle _getLinkStyle() {
    return widget.linkStyle ??
        widget.style.copyWith(
          color: AppColors.accent,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.accent,
        );
  }

  /// Parseia um deep link do WeGig e retorna informações estruturadas
  _WeGigDeepLink? _parseWeGigDeepLink(String url) {
    // Normaliza a URL
    String normalizedUrl = url;
    if (!url.startsWith('http')) {
      normalizedUrl = 'https://$url';
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) return null;

    // Verifica se é do domínio wegig.com.br
    if (uri.host != 'wegig.com.br') return null;

    final segments = uri.pathSegments;
    if (segments.isEmpty) return null;

    // Parseia diferentes tipos de deep links
    switch (segments[0]) {
      case 'profile':
        // /profile/{userId}/{profileId} ou /profile/{profileId}
        if (segments.length >= 2) {
          final profileId = segments.length >= 3 ? segments[2] : segments[1];
          return _WeGigDeepLink(
            type: _DeepLinkType.profile,
            id: profileId,
            originalUrl: url,
          );
        }
        break;

      case 'post':
        // /post/{postId}
        if (segments.length >= 2) {
          return _WeGigDeepLink(
            type: _DeepLinkType.post,
            id: segments[1],
            originalUrl: url,
          );
        }
        break;

      case 'conversation':
      case 'chat':
      case 'chat-new':
        // /conversation/{conversationId} ou /chat/{conversationId}
        if (segments.length >= 2) {
          return _WeGigDeepLink(
            type: _DeepLinkType.conversation,
            id: segments[1],
            originalUrl: url,
          );
        }
        break;
    }

    return null;
  }

  /// Formata o texto de exibição para deep links do WeGig
  String _formatDeepLinkDisplay(_WeGigDeepLink link) {
    switch (link.type) {
      case _DeepLinkType.profile:
        return '👤 Ver perfil';
      case _DeepLinkType.post:
        return '📍 Ver post';
      case _DeepLinkType.conversation:
        return '💬 Abrir conversa';
    }
  }

  /// Formata a exibição de URLs externas (encurta se muito longa)
  String _formatExternalUrlDisplay(String url) {
    // Remove protocolo para exibição mais limpa
    String display = url
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'^www\.'), '');

    // Trunca se muito longo
    if (display.length > 40) {
      display = '${display.substring(0, 37)}...';
    }

    return '🔗 $display';
  }

  /// Trata o toque em um deep link do WeGig
  void _handleWeGigDeepLink(_WeGigDeepLink link) {
    switch (link.type) {
      case _DeepLinkType.profile:
        if (widget.onProfileTap != null) {
          widget.onProfileTap!(link.id);
        } else {
          // Fallback: tenta abrir a URL externa
          _launchUrl(link.originalUrl);
        }
        break;

      case _DeepLinkType.post:
        if (widget.onPostTap != null) {
          widget.onPostTap!(link.id);
        } else {
          _launchUrl(link.originalUrl);
        }
        break;

      case _DeepLinkType.conversation:
        if (widget.onConversationTap != null) {
          widget.onConversationTap!(link.id);
        } else {
          _launchUrl(link.originalUrl);
        }
        break;
    }
  }

  /// Abre uma URL externa no navegador
  Future<void> _launchUrl(String url) async {
    String finalUrl = url;
    if (!url.startsWith('http')) {
      finalUrl = 'https://$url';
    }

    final uri = Uri.tryParse(finalUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Tipos de deep links suportados
enum _DeepLinkType {
  profile,
  post,
  conversation,
}

/// Informações de um deep link do WeGig parseado
class _WeGigDeepLink {
  const _WeGigDeepLink({
    required this.type,
    required this.id,
    required this.originalUrl,
  });

  final _DeepLinkType type;
  final String id;
  final String originalUrl;
}
