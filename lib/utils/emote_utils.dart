class EmoteUtils {
  static String removeEmotesByTag(String message, String emotesTag) {
    if (emotesTag.isEmpty) {
      return message;
    }

    final ranges = <_Range>[];
    final emoteParts = emotesTag.split('/');
    for (final part in emoteParts) {
      final segments = part.split(':');
      if (segments.length != 2) {
        continue;
      }
      final positions = segments[1].split(',');
      for (final position in positions) {
        final bounds = position.split('-');
        if (bounds.length != 2) {
          continue;
        }
        final start = int.tryParse(bounds[0]);
        final end = int.tryParse(bounds[1]);
        if (start == null || end == null) {
          continue;
        }
        ranges.add(_Range(start, end));
      }
    }

    if (ranges.isEmpty) {
      return message;
    }

    ranges.sort((a, b) => b.start.compareTo(a.start));

    var cleaned = message;
    for (final range in ranges) {
      if (range.start < 0 || range.end >= cleaned.length) {
        continue;
      }
      cleaned = cleaned.replaceRange(range.start, range.end + 1, '');
    }

    return _collapseWhitespace(cleaned);
  }

  static String dedupTokens(String message) {
    final tokens = message.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    final result = <String>[];
    for (final token in tokens) {
      if (result.isEmpty || result.last.toLowerCase() != token.toLowerCase()) {
        result.add(token);
      }
    }
    return result.join(' ');
  }

  static String _collapseWhitespace(String message) {
    return message.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _Range {
  _Range(this.start, this.end);

  final int start;
  final int end;
}
