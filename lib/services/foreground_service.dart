import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Callback de nivel superior requerido por flutter_foreground_task para
/// inicializar el handler dentro del isolate en segundo plano.
@pragma('vm:entry-point')
void ttsForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_TtsForegroundTaskHandler());
}

class _TtsForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Servicio que orquesta el Foreground Service en Android y el modo
/// en segundo plano para permitir que el TTS, el dictado por voz
/// y el enlace de voz/cámara sigan funcionando con la pantalla apagada.
class ForegroundService {
  ForegroundService({bool? enablePlatformCheck})
      : _enablePlatformCheck = enablePlatformCheck ?? true;

  final bool _enablePlatformCheck;
  bool _initialized = false;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  bool get isSupported {
    if (!_enablePlatformCheck) return true;
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  Future<void> init() async {
    if (!isSupported || _initialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tts_apliarte_foreground',
        channelName: 'TTS ApliArte - En segundo plano',
        channelDescription:
            'Mantiene activos el TTS, el dictado por voz y el modo paseo con la pantalla apagada.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _initialized = true;
  }

  /// Inicia el Foreground Service o actualiza el texto de la notificación
  /// persistente si ya está en ejecución.
  Future<bool> startOrUpdate({
    required String title,
    required String text,
  }) async {
    if (!isSupported) {
      _isRunning = true;
      return true;
    }

    if (!_initialized) {
      await init();
    }

    try {
      final running = await FlutterForegroundTask.isRunningService;
      if (running) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
        _isRunning = true;
        return true;
      }

      if (Platform.isAndroid) {
        final permission =
            await FlutterForegroundTask.checkNotificationPermission();
        if (permission != NotificationPermission.granted) {
          await FlutterForegroundTask.requestNotificationPermission();
        }
      }

      final result = await FlutterForegroundTask.startService(
        serviceId: 256,
        serviceTypes: [
          ForegroundServiceTypes.mediaPlayback,
          ForegroundServiceTypes.microphone,
        ],
        notificationTitle: title,
        notificationText: text,
        callback: ttsForegroundTaskCallback,
      );

      _isRunning = result is ServiceRequestSuccess;
      return _isRunning;
    } catch (e) {
      debugPrint('Error iniciando/actualizando ForegroundService: $e');
      return false;
    }
  }

  /// Detiene el Foreground Service si está activo.
  Future<bool> stop() async {
    if (!isSupported) {
      _isRunning = false;
      return true;
    }

    try {
      final running = await FlutterForegroundTask.isRunningService;
      if (running) {
        final result = await FlutterForegroundTask.stopService();
        _isRunning = result is! ServiceRequestSuccess;
        return result is ServiceRequestSuccess;
      }
      _isRunning = false;
      return true;
    } catch (e) {
      debugPrint('Error deteniendo ForegroundService: $e');
      return false;
    }
  }
}
