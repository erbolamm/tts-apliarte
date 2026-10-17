import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Inicializador seguro y no bloqueante de Firebase para [TtsApliArteApp].
///
/// Sigue el ajuste Argon M1-A: nunca bloquea `runApp()` ni lanza excepciones
/// si el dispositivo está offline o carece de configuración nativa de Firebase.
class FirebaseInitService {
  static const Duration kFirebaseInitTimeout = Duration(seconds: 4);

  static bool isAvailable = false;

  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp().timeout(kFirebaseInitTimeout);
      isAvailable = true;
      return true;
    } on TimeoutException catch (e) {
      debugPrint('FirebaseInitService timeout (${kFirebaseInitTimeout.inSeconds}s): $e');
      isAvailable = false;
      return false;
    } on FirebaseException catch (e) {
      debugPrint('FirebaseInitService FirebaseException: ${e.code} - ${e.message}');
      isAvailable = false;
      return false;
    } catch (e) {
      debugPrint('FirebaseInitService fallback offline mode: $e');
      isAvailable = false;
      return false;
    }
  }
}
