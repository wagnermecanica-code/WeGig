import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Text widget that highlights and handles @username mentions.
class MentionText extends StatefulWidget {
  const MentionText({
    super.key,
    required this.text,
    this.style,
    this.mentionStyle,
    this.maxLines,
    this.overflow,
    this.textAlign = TextAlign.start,
    this.selectable = false,
    this.onMentionTap,
  });

  final String text;
  final TextStyle? style;
  final TextStyle? mentionStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign textAlign;
  final bool selectable;
  final void Function(String username)? onMentionTap;

  static final RegExp mentionRegex = RegExp(r'@([a-zA-Z0-9._]+)');

  @override
  State<MentionText> createState() => _MentionTextState();
}

class _MentionTextState extends State<MentionText> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  List<TextSpan> _buildSpans() {
    final text = widget.text;
    if (text.isEmpty) {
      return <TextSpan>[TextSpan(text: text)];
    }

    final spans = <TextSpan>[];
    int currentIndex = 0;

    for (final match in MentionText.mentionRegex.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }

      final mention = match.group(0)!;
      final username = match.group(1)!;

      TapGestureRecognizer? recognizer;
      if (widget.onMentionTap != null) {
        recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onMentionTap?.call(username);
        _recognizers.add(recognizer);
      }

      spans.add(
        TextSpan(
          text: mention,
          style: widget.mentionStyle ??
              widget.style?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ) ??
              const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
          recognizer: recognizer,
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    if (spans.isEmpty) {
      return <TextSpan>[TextSpan(text: text)];
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final spans = _buildSpans();
    final baseSpan = TextSpan(style: widget.style, children: spans);

    if (widget.selectable) {
      return SelectableText.rich(
        baseSpan,
        maxLines: widget.maxLines,
        textAlign: widget.textAlign,
      );
    }

    return RichText(
      text: baseSpan,
      maxLines: widget.maxLines,
      overflow: widget.overflow ?? TextOverflow.visible,
      textAlign: widget.textAlign,
      textScaler: MediaQuery.of(context).textScaler,
    );
  }
}
