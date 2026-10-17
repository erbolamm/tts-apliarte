import 'dart:async';
import 'dart:collection';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
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

    // En iOS: configurar categoría 'playback' con mezcla y bluetooth
    // para que el TTS continúe sonando con la pantalla apagada o bloqueada.
    if (!kIsWeb && Platform.isIOS) {
      try {
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.defaultMode,
        );
      } catch (e) {
        debugPrint('Error configurando iOS audio category en TTS: $e');
      }
    }
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
    double? rate,
    String? prefix,
    String? suffix,
  }) async {
    final formattedText = _formatWithAffixes(text, prefix: prefix, suffix: suffix);
    if (formattedText.isEmpty) return;
    _queue.add(
      _TtsJob(
        text: formattedText,
        voice: voice,
        language: language,
        pitch: pitch,
        rate: rate,
        prefix: prefix,
        suffix: suffix,
      ),
    );
    if (!_busy) {
      _processQueue();
    }
  }

  Future<void> speakTest({
    required String text,
    String? voice,
    String? language,
    double? pitch,
    double? rate,
    String? prefix,
    String? suffix,
  }) {
    return enqueue(
      text: text,
      voice: voice,
      language: language,
      pitch: pitch,
      rate: rate,
      prefix: prefix,
      suffix: suffix,
    );
  }

  String _formatWithAffixes(String text, {String? prefix, String? suffix}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final pre = prefix ?? '';
    final suf = suffix ?? '';
    return '$pre$trimmed$suf'.trim();
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

    // Se fija siempre rate y pitch en cada trabajo para que no queden pegados
    // en el motor nativo para el siguiente mensaje (Argon M2-C).
    await _tts.setSpeechRate((job.rate ?? 0.5).clamp(0.1, 1.0));
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
    this.rate,
    this.prefix,
    this.suffix,
  });

  final String text;
  final String? voice;
  final String? language;
  final double? pitch;
  final double? rate;
  final String? prefix;
  final String? suffix;
}

