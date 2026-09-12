import 'levenshtein.dart';

class SimilarityFilter {
  final Map<String, List<_TimedMessage>> _messagesByKey = {};

  bool isSimilar({
    required String key,
    required String text,
    required double thresholdPercent,
    required Duration window,
  }) {
    if (thresholdPercent <= 0) {
      return false;
    }

    final normalized = _normalize(text);
    if (normalized.isEmpty) {
      return false;
    }

    final now = DateTime.now();
    final items = _messagesByKey.putIfAbsent(key, () => <_TimedMessage>[]);

    items.removeWhere((item) => now.difference(item.timestamp) > window);

    for (final item in items) {
      final similarity = _similarityPercent(normalized, item.message);
      if (similarity >= thresholdPercent) {
        return true; // Bloqueo instantáneo basado en el porcentaje configurado por el usuario
      }
    }

    items.add(_TimedMessage(message: normalized, timestamp: now));
    return false;
  }

  double _similarityPercent(String a, String b) {
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) {
      return 100;
    }
    final distance = levenshteinDistance(a, b);
    final score = 1 - (distance / maxLen);
    return (score * 100).clamp(0, 100);
  }

  String _normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _TimedMessage {
  _TimedMessage({required this.message, required this.timestamp});

  final String message;
  final DateTime timestamp;
}
