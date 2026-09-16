import 'dart:async';
import 'dart:collection';

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  final Queue<_TtsJob> _queue = Queue<_TtsJob>();
  bool _busy = false;
  String? _currentVoice;
  String? _currentLanguage;

  Future<void> init() async {
    await _tts.awaitSpeakCompletion(true);
    _tts.setCompletionHandler(() {
      _busy = false;
      _processQueue();
    });
    _tts.setCancelHandler(() {
      _busy = false;
      _processQueue();
    });
    _tts.setErrorHandler((message) {
      _busy = false;
      _processQueue();
    });
  }

  Future<List<dynamic>> getVoices() async {
    final voices = await _tts.getVoices;
    if (voices is List<dynamic>) {
      return voices;
    }
    return [];
  }

  Future<void> setVoice(String? voice) async {
    if (voice == null || voice == 'auto') {
      _currentVoice = null;
      return;
    }
    _currentVoice = voice;
  }

  Future<void> setLanguage(String? language) async {
    if (language == null || language == 'auto') {
      _currentLanguage = null;
      return;
    }
    _currentLanguage = language;
    await _tts.setLanguage(language);
  }

  Future<void> enqueue({
    required String text,
    String? voice,
    String? language,
    double? pitch,
  }) async {
    _queue.add(
      _TtsJob(text: text, voice: voice, language: language, pitch: pitch),
    );
    if (!_busy) {
      _processQueue();
    }
  }

  Future<void> stop() async {
    _queue.clear();
    await _tts.stop();
    _busy = false;
  }

  Future<void> _processQueue() async {
    if (_busy || _queue.isEmpty) {
      return;
    }
    final job = _queue.removeFirst();
    _busy = true;

    final voice = job.voice ?? _currentVoice;
    final language = job.language ?? _currentLanguage;

    if (language != null && language.isNotEmpty && language != 'auto') {
      await _tts.setLanguage(language);
    }

    if (voice != null && voice.isNotEmpty && voice != 'auto') {
      final voiceMap = <String, String>{'name': voice};
      if (language != null && language.isNotEmpty && language != 'auto') {
        voiceMap['locale'] = language;
      }
      await _tts.setVoice(voiceMap);
    }

    // Se fija siempre, incluso al valor por defecto: si no se reinicia aquí,
    // el pitch de un job anterior se queda pegado en el motor para el siguiente.
    await _tts.setPitch(job.pitch ?? 1.0);

    await _tts.speak(job.text);
  }
}

class _TtsJob {
  _TtsJob({
    required this.text,
    required this.voice,
    required this.language,
    required this.pitch,
  });

  final String text;
  final String? voice;
  final String? language;
  final double? pitch;
}
