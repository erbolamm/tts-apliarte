import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

typedef SetBrightnessFn = Future<void> Function(double brightness);
typedef ResetBrightnessFn = Future<void> Function();
typedef SetWakelockFn = Future<void> Function(bool enable);
typedef SetSystemUiModeFn = Future<void> Function(SystemUiMode mode);

/// Servicio para gestionar el modo de pantalla apagada en la app (modo paseo).
///
/// ## Limitación de los sistemas operativos (Android e iOS):
/// Ni Android (sin privilegios de Device Admin / root) ni iOS permiten que una
/// aplicación de terceros apague físicamente la pantalla del dispositivo mediante software
/// sin bloquear el terminal (Keyguard). Si se bloqueara el sistema, el sistema operativo
/// suspende la captura de cámara de primer plano (`Camera2` / `AVCaptureSession`) por políticas
/// estrictas de privacidad del hardware.
///
/// ## Solución técnica (Modo bajo consumo / Ahorro OLED):
/// 1. Se despliega una interfaz completamente negra (`#000000`) en modo inmersivo total
///    (`SystemUiMode.immersiveSticky`, ocultando barras de estado y navegación).
///    En pantallas OLED/AMOLED (como la del Google Pixel 10 Pro XL), los píxeles negros
///    están **físicamente apagados** (0 nits, disipación de calor prácticamente nula y
///    consumo eléctrico de panel mínimo).
/// 2. Se reduce el brillo de pantalla al mínimo mediante `screen_brightness`.
/// 3. Se activa `wakelock_plus` para evitar que el temporizador de inactividad del sistema
///    bloquee el terminal y suspenda el hardware mientras el usuario camina con el móvil en mano o bolsillo.
/// 4. Todos los servicios en segundo plano y tiempo real (enlace WebRTC de voz y cámara,
///    reconocimiento de voz y dictado, lectura por TTS de Twitch) siguen operando
///    con normalidad en primer plano.
/// 5. El usuario puede encender de nuevo la pantalla en cualquier momento mediante un
///    doble toque o pulsando el botón de salida, restaurando el brillo original y la UI
///    sin perder ningún dato de la sesión en curso.
class ScreenOffService extends ChangeNotifier {
  ScreenOffService({
    SetBrightnessFn? setBrightness,
    ResetBrightnessFn? resetBrightness,
    SetWakelockFn? setWakelock,
    SetSystemUiModeFn? setSystemUiMode,
  })  : _setBrightness = setBrightness ?? _defaultSetBrightness,
        _resetBrightness = resetBrightness ?? _defaultResetBrightness,
        _setWakelock = setWakelock ?? _defaultSetWakelock,
        _setSystemUiMode = setSystemUiMode ?? _defaultSetSystemUiMode;

  final SetBrightnessFn _setBrightness;
  final ResetBrightnessFn _resetBrightness;
  final SetWakelockFn _setWakelock;
  final SetSystemUiModeFn _setSystemUiMode;

  bool _isScreenOff = false;

  /// Indica si el modo de pantalla apagada / bajo consumo está activo.
  bool get isScreenOff => _isScreenOff;

  static Future<void> _defaultSetBrightness(double brightness) async {
    try {
      await ScreenBrightness().setApplicationScreenBrightness(brightness);
    } catch (e) {
      debugPrint('ScreenBrightness.setApplicationScreenBrightness error: $e');
    }
  }

  static Future<void> _defaultResetBrightness() async {
    try {
      await ScreenBrightness().resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint('ScreenBrightness.resetApplicationScreenBrightness error: $e');
    }
  }

  static Future<void> _defaultSetWakelock(bool enable) async {
    try {
      if (enable) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (e) {
      debugPrint('WakelockPlus error: $e');
    }
  }

  static Future<void> _defaultSetSystemUiMode(SystemUiMode mode) async {
    try {
      await SystemChrome.setEnabledSystemUIMode(mode);
    } catch (e) {
      debugPrint('SystemChrome error: $e');
    }
  }

  /// Activa el modo de pantalla apagada.
  Future<void> enterScreenOffMode() async {
    if (_isScreenOff) return;
    _isScreenOff = true;
    notifyListeners();

    await _setSystemUiMode(SystemUiMode.immersiveSticky);
    await _setBrightness(0.0);
    await _setWakelock(true);
  }

  /// Desactiva el modo de pantalla apagada y restaura brillo y barras del sistema.
  Future<void> exitScreenOffMode() async {
    if (!_isScreenOff) return;
    _isScreenOff = false;
    notifyListeners();

    await _setSystemUiMode(SystemUiMode.edgeToEdge);
    await _resetBrightness();
    await _setWakelock(false);
  }

  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_isScreenOff) {
      _setSystemUiMode(SystemUiMode.edgeToEdge);
      _resetBrightness();
      _setWakelock(false);
      _isScreenOff = false;
    }
    super.dispose();
  }
}
