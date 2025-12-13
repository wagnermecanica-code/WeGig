import 'package:linkify/linkify.dart';

/// Linkifier that detects @username mentions and converts them to linkable elements.
class MentionLinkifier extends Linkifier {
  const MentionLinkifier();

  static final RegExp _mentionRegex = RegExp(r'@([a-zA-Z0-9._]+)');

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final List<LinkifyElement> list = <LinkifyElement>[];

    for (final element in elements) {
      if (element is! TextElement) {
        list.add(element);
        continue;
      }

      final text = element.text;
      final matches = _mentionRegex.allMatches(text);
      if (matches.isEmpty) {
        list.add(element);
        continue;
      }

      var currentIndex = 0;
      for (final match in matches) {
        if (match.start > currentIndex) {
          list.add(
            TextElement(text.substring(currentIndex, match.start)),
          );
        }

        final mention = match.group(0)!;
        final username = match.group(1)!;
        list.add(MentionElement(mention, username));
        currentIndex = match.end;
      }

      if (currentIndex < text.length) {
        list.add(TextElement(text.substring(currentIndex)));
      }
    }

    return list;
  }
}

/// Linkable element representing a mention that stores the username.
class MentionElement extends LinkableElement {
  MentionElement(String text, this.username)
      : super(text, username.toLowerCase());

  final String username;
}
