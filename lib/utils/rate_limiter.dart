import 'dart:async';

class RateLimiter {
  RateLimiter({required this.maxEvents, required this.interval});

  final int maxEvents;
  final Duration interval;
  final List<DateTime> _events = [];

  Future<void> waitForSlot() async {
    while (true) {
      final now = DateTime.now();
      _events.removeWhere((time) => now.difference(time) > interval);
      if (_events.length < maxEvents) {
        _events.add(now);
        return;
      }
      final oldest = _events.first;
      final wait = interval - now.difference(oldest);
      if (wait.isNegative) {
        _events.removeAt(0);
      } else {
        await Future<void>.delayed(wait);
      }
    }
  }
}
