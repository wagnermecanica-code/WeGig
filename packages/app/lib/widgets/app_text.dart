import 'dart:ui' as ui show TextHeightBehavior;

import 'package:flutter/material.dart';

/// AppText - Widget de texto com proteção contra overflow
///
/// Este widget envolve o Text padrão do Flutter com configurações
/// seguras para evitar overflow em layouts Android/iOS:
/// - overflow: TextOverflow.ellipsis (por padrão)
/// - softWrap: true (por padrão)
/// - maxLines: 1 (por padrão, mas pode ser sobrescrito)
///
/// Uso:
/// ```dart
/// AppText('Texto longo que será truncado...')
/// AppText('Texto multilinha', maxLines: 3)
/// AppText('Texto customizado', style: TextStyle(fontSize: 16))
/// ```
class AppText extends StatelessWidget {
  /// Cria um widget de texto com proteção contra overflow.
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap = true,
    this.overflow = TextOverflow.ellipsis,
    this.textScaler,
    this.maxLines = 1,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  /// O texto a ser exibido.
  final String data;

  /// O estilo do texto (cor, fonte, tamanho, etc).
  final TextStyle? style;

  /// Define a altura das linhas do texto.
  final StrutStyle? strutStyle;

  /// Alinhamento horizontal do texto.
  final TextAlign? textAlign;

  /// Direção do texto (LTR ou RTL).
  final TextDirection? textDirection;

  /// Locale para internacionalização.
  final Locale? locale;

  /// Se o texto deve quebrar em múltiplas linhas.
  /// Padrão: true
  final bool softWrap;

  /// Comportamento quando o texto excede o espaço disponível.
  /// Padrão: TextOverflow.ellipsis (adiciona "...")
  final TextOverflow overflow;

  /// Escala do texto para acessibilidade.
  final TextScaler? textScaler;

  /// Número máximo de linhas.
  /// Padrão: 1 (para evitar overflow)
  /// Use null para linhas ilimitadas (com cuidado!)
  final int? maxLines;

  /// Label para leitores de tela (acessibilidade).
  final String? semanticsLabel;

  /// Base para calcular a largura do texto.
  final TextWidthBasis? textWidthBasis;

  /// Comportamento da altura do texto.
  final ui.TextHeightBehavior? textHeightBehavior;

  /// Cor de seleção do texto.
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      key: key,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

/// AppText.rich - Para textos com spans múltiplos (TextSpan)
///
/// Uso:
/// ```dart
/// AppText.rich(
///   TextSpan(
///     text: 'Olá, ',
///     children: [
///       TextSpan(text: 'mundo!', style: TextStyle(fontWeight: FontWeight.bold)),
///     ],
///   ),
/// )
/// ```
class AppTextRich extends StatelessWidget {
  /// Cria um widget de texto rico com proteção contra overflow.
  const AppTextRich(
    this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap = true,
    this.overflow = TextOverflow.ellipsis,
    this.textScaler,
    this.maxLines = 1,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  /// O TextSpan a ser exibido.
  final InlineSpan textSpan;

  /// O estilo base do texto.
  final TextStyle? style;

  /// Define a altura das linhas do texto.
  final StrutStyle? strutStyle;

  /// Alinhamento horizontal do texto.
  final TextAlign? textAlign;

  /// Direção do texto (LTR ou RTL).
  final TextDirection? textDirection;

  /// Locale para internacionalização.
  final Locale? locale;

  /// Se o texto deve quebrar em múltiplas linhas.
  final bool softWrap;

  /// Comportamento quando o texto excede o espaço disponível.
  final TextOverflow overflow;

  /// Escala do texto para acessibilidade.
  final TextScaler? textScaler;

  /// Número máximo de linhas.
  final int? maxLines;

  /// Label para leitores de tela.
  final String? semanticsLabel;

  /// Base para calcular a largura do texto.
  final TextWidthBasis? textWidthBasis;

  /// Comportamento da altura do texto.
  final ui.TextHeightBehavior? textHeightBehavior;

  /// Cor de seleção do texto.
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      textSpan,
      key: key,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}
