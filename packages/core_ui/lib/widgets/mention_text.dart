import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/utf16_sanitizer.dart';
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
  String get _text => Utf16Sanitizer.removeInvalidSurrogates(widget.text);

  TextStyle get _mentionStyle =>
      widget.mentionStyle ??
      widget.style?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ) ??
      const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      );

  List<InlineSpan> _buildSpans(String text) {
    if (text.isEmpty) {
      return <TextSpan>[TextSpan(text: text)];
    }

    final spans = <InlineSpan>[];
    int currentIndex = 0;

    for (final match in MentionText.mentionRegex.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }

      final mention = match.group(0)!;
      spans.add(TextSpan(text: mention, style: _mentionStyle));

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

  List<_MentionHitRange> _buildMentionRanges(String text) {
    return MentionText.mentionRegex.allMatches(text).map((match) {
      return _MentionHitRange(
        start: match.start,
        end: match.end,
        username: match.group(1)!,
      );
    }).toList(growable: false);
  }

  void _handleTapUp({
    required BuildContext context,
    required Offset localPosition,
    required BoxConstraints constraints,
    required TextSpan textSpan,
    required List<_MentionHitRange> ranges,
  }) {
    final onMentionTap = widget.onMentionTap;
    if (onMentionTap == null || ranges.isEmpty) return;

    final maxWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : MediaQuery.sizeOf(context).width;
    final painter = TextPainter(
      text: textSpan,
      textAlign: widget.textAlign,
      textDirection: Directionality.of(context),
      maxLines: widget.maxLines,
      ellipsis: widget.overflow == TextOverflow.ellipsis ? '\u2026' : null,
      textScaler: MediaQuery.of(context).textScaler,
    )..layout(maxWidth: maxWidth);

    for (final range in ranges) {
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
      );
      for (final box in boxes) {
        final hitRect = Rect.fromLTRB(
          box.left - 18,
          box.top - 12,
          box.right + 18,
          box.bottom + 12,
        );
        if (hitRect.contains(localPosition)) {
          onMentionTap(range.username);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    final spans = _buildSpans(text);
    final baseSpan = TextSpan(style: widget.style, children: spans);
    final canSelectText = widget.selectable && widget.onMentionTap == null;

    if (canSelectText) {
      return SelectableText.rich(
        baseSpan,
        maxLines: widget.maxLines,
        textAlign: widget.textAlign,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final richText = SizedBox(
          width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
          child: RichText(
            text: baseSpan,
            maxLines: widget.maxLines,
            overflow: widget.overflow ?? TextOverflow.visible,
            textAlign: widget.textAlign,
            textScaler: MediaQuery.of(context).textScaler,
          ),
        );

        if (widget.onMentionTap == null) return richText;

        final ranges = _buildMentionRanges(text);
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerUp: (event) {
            if (event.kind == PointerDeviceKind.mouse &&
                event.buttons != kPrimaryMouseButton) {
              return;
            }
            _handleTapUp(
              context: context,
              localPosition: event.localPosition,
              constraints: constraints,
              textSpan: baseSpan,
              ranges: ranges,
            );
          },
          child: richText,
        );
      },
    );
  }
}

class _MentionHitRange {
  const _MentionHitRange({
    required this.start,
    required this.end,
    required this.username,
  });

  final int start;
  final int end;
  final String username;
}
