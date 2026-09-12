import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

class SpeechResult {
  SpeechResult({required this.text, required this.isFinal});

  final String text;
  final bool isFinal;
}

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  final _resultController = StreamController<SpeechResult>.broadcast();

  bool _available = false;
  bool _listening = false;

  Stream<SpeechResult> get results => _resultController.stream;
  bool get isListening => _listening;
  bool get isAvailable => _available;

  Future<void> init() async {
    _available = await _speech.initialize();
  }

  Future<void> start({String? localeId}) async {
    if (!_available) {
      _available = await _speech.initialize();
    }
    if (!_available) {
      return;
    }

    _listening = true;
    await _speech.listen(
      localeId: localeId,
      onResult: (result) {
        _resultController.add(
          SpeechResult(text: result.recognizedWords, isFinal: result.finalResult),
        );
      },
    );
  }

  Future<void> stop() async {
    _listening = false;
    await _speech.stop();
  }

  void dispose() {
    _resultController.close();
  }
}
