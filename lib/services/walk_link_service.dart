import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Estado observable del enlace WebRTC P2P del modo paseo (paso 3 de la
/// cadena directo/tts-apliarte). El servicio expone este enum y los
/// interruptores `micEnabled` / `camEnabled` para que la UI muestre
/// "Apagado", "Pidiendo permiso…", "Enlazando…", "En directo" o
/// "Sin señal" sin tocar directamente la lógica interna.
enum WalkLinkState {
  idle,
  requestingPermissions,
  connecting,
  connected,
  error,
}

/// Error específico del enlace: lo lanza el servicio cuando falla un
/// permiso o una captura de medios, para que la UI lo diferencie de
/// errores genéricos.
class WalkLinkError implements Exception {
  const WalkLinkError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Enlace WebRTC P2P entre el móvil (esta app) y
/// `directo/public/walk.html` (servido por el mismo Express que ya tiene
/// `/api/escena` y `/api/categoria`). Sin SFU, sin VDO.Ninja: la oferta,
/// respuesta y candidatos ICE viajan por un WebSocket de signaling nuevo
/// (`/ws/walk`) que añade directo/src/walk-signaling.js.
///
/// La app **no** muestra preview local de la cámara (decisión de Javier,
/// 2026-09-16, para no cargar el dispositivo emisor): nunca monta un
/// `RTCVideoRenderer` ni un `<video>` propio. La pista sale al peer y se
/// ve solo en el directo del PC.
///
/// Los dos interruptores (voz y cámara) son independientes: se pueden
/// encender los dos a la vez, solo uno, o ninguno. Cada uno pide su
/// permiso (micro o cámara) la primera vez que se activa.
///
/// Si `scenesServerBaseUrl` está vacío, el servicio no intenta nada —
/// mismo patrón que `EscenaServerClient`: cero infraestructura por
/// defecto, cada usuario pone la suya.
class WalkLinkService extends ChangeNotifier {
  WalkLinkService({required String initialServerBaseUrl})
      : _serverBaseUrl = initialServerBaseUrl;

  String _serverBaseUrl;
  String get serverBaseUrl => _serverBaseUrl;
  set serverBaseUrl(String value) {
    if (_serverBaseUrl == value) return;
    _serverBaseUrl = value;
    // Cambio de servidor: cerrar todo y dejar que el usuario reactive.
    unawaited(_teardown(reason: 'URL del servidor de escenas cambiada'));
  }

  // ── Estado observable ─────────────────────────────────────────────────
  WalkLinkState _state = WalkLinkState.idle;
  WalkLinkState get state => _state;
  String? _stateDetail;
  String? get stateDetail => _stateDetail;

  bool _micEnabled = false;
  bool get micEnabled => _micEnabled;

  bool _camEnabled = false;
  bool get camEnabled => _camEnabled;

  String? _sessionId;
  String? get sessionId => _sessionId;
  bool _disposed = false;

  /// Número de pistas de medios activas (audio o vídeo). La UI puede
  /// usarlo para mostrar un contador "1/2 pistas" si quiere.
  int get activeTrackCount =>
      (_audioTrack != null ? 1 : 0) + (_videoTrack != null ? 1 : 0);

  // ── Recursos internos ────────────────────────────────────────────────
  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  RTCPeerConnection? _pc;
  MediaStreamTrack? _audioTrack;
  MediaStreamTrack? _videoTrack;

  void _setState(WalkLinkState nuevo, {String? detail}) {
    if (_disposed) return;
    _state = nuevo;
    _stateDetail = detail;
    notifyListeners();
  }

  // ── API pública ──────────────────────────────────────────────────────
  /// Activa o desactiva el envío de audio (micro) al peer.
  Future<void> setMicEnabled(bool value) async {
    if (_micEnabled == value || _disposed) return;
    _micEnabled = value;
    notifyListeners();
    try {
      if (value) {
        await _ensureAudioTrack();
      } else {
        await _dropAudioTrack();
      }
      await _reconcilePeerConnection();
    } catch (e) {
      _micEnabled = false;
      _setState(WalkLinkState.error, detail: 'mic: $e');
    }
  }

  /// Activa o desactiva el envío de vídeo (cámara) al peer. La pista
  /// nunca se renderiza localmente — solo se adjunta al peer para que
  /// llegue al directo del PC.
  Future<void> setCamEnabled(bool value) async {
    if (_camEnabled == value || _disposed) return;
    _camEnabled = value;
    notifyListeners();
    try {
      if (value) {
        await _ensureVideoTrack();
      } else {
        await _dropVideoTrack();
      }
      await _reconcilePeerConnection();
    } catch (e) {
      _camEnabled = false;
      _setState(WalkLinkState.error, detail: 'cam: $e');
    }
  }

  /// Cambia la sesión de signaling (texto corto que el usuario mete en
  /// la app y en `walk.html?session=…`). Si está vacío, no conecta.
  Future<void> setSessionId(String? value) async {
    final limpio = (value ?? '').trim();
    if (_sessionId == limpio) return;
    _sessionId = limpio.isEmpty ? null : limpio;
    if (_sessionId == null) {
      await _teardown(reason: 'sin sesión de signaling');
      return;
    }
    await _reconcilePeerConnection();
  }

  // ── Permisos y captura de medios ─────────────────────────────────────
  Future<void> _ensureAudioTrack() async {
    if (_audioTrack != null) return;
    _setState(WalkLinkState.requestingPermissions, detail: 'micrófono');
    final ok = await Permission.microphone.request();
    if (!ok.isGranted) {
      throw const WalkLinkError('Permiso de micrófono denegado.');
    }
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    final tracks = stream.getAudioTracks();
    if (tracks.isEmpty) {
      throw const WalkLinkError('No se obtuvo pista de audio del sistema.');
    }
    _audioTrack = tracks.first;
  }

  Future<void> _dropAudioTrack() async {
    final t = _audioTrack;
    _audioTrack = null;
    if (t != null) {
      await _stopTrack(t);
    }
  }

  Future<void> _ensureVideoTrack() async {
    if (_videoTrack != null) return;
    _setState(WalkLinkState.requestingPermissions, detail: 'cámara');
    final ok = await Permission.camera.request();
    if (!ok.isGranted) {
      throw const WalkLinkError('Permiso de cámara denegado.');
    }
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': false,
      'video': true,
    });
    final tracks = stream.getVideoTracks();
    if (tracks.isEmpty) {
      throw const WalkLinkError('No se obtuvo pista de vídeo del sistema.');
    }
    _videoTrack = tracks.first;
  }

  Future<void> _dropVideoTrack() async {
    final t = _videoTrack;
    _videoTrack = null;
    if (t != null) {
      await _stopTrack(t);
    }
  }

  Future<void> _stopTrack(MediaStreamTrack track) async {
    try {
      await track.stop();
    } catch (_) {
      // El sistema ya la paró; ignorar.
    }
  }

  // ── Peer connection y signaling ───────────────────────────────────────
  Future<void> _reconcilePeerConnection() async {
    final base = _serverBaseUrl;
    final sid = _sessionId;
    final tienePistas = _audioTrack != null || _videoTrack != null;

    if (base.isEmpty || sid == null || !tienePistas) {
      // No hay nada que enlazar: si hay un peer viejo, cerrarlo.
      await _closePeer();
      _setState(WalkLinkState.idle);
      return;
    }

    try {
      _setState(WalkLinkState.connecting);
      await _ensureSocket(base);
      await _ensurePeerConnection();

      // Ajustar senders/transceivers al estado real de las pistas.
      final senders = await _pc!.senders;
      if (_audioTrack != null) {
        await _ensureSenderFor(senders, _audioTrack!);
      }
      if (_videoTrack != null) {
        await _ensureSenderFor(senders, _videoTrack!);
      }

      // Renegociar: enviar nueva oferta para que el peer vea las pistas
      // que ahora están activas.
      final offer = await _pc!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await _pc!.setLocalDescription(offer);
      _ws?.sink.add(jsonEncode({
        'type': 'offer',
        'sessionId': _sessionId,
        'sdp': offer.sdp,
        'sdpType': offer.type,
      }));

      _setState(WalkLinkState.connected);
    } catch (err) {
      _setState(WalkLinkState.error, detail: err.toString());
      // No relanzamos: el servicio expone el error en `stateDetail` y
      // `state`, y el usuario puede volver a tocar el interruptor.
    }
  }

  /// Garantiza que el peer connection tiene un sender para la pista
  /// dada. Si ya existe uno del mismo `kind`, lo reemplaza; si no, añade
  /// un transceiver nuevo con la pista.
  Future<void> _ensureSenderFor(
    List<RTCRtpSender> senders,
    MediaStreamTrack track,
  ) async {
    for (final s in senders) {
      if (s.track?.kind == track.kind) {
        if (s.track?.id != track.id) {
          await s.replaceTrack(track);
        }
        return;
      }
    }
    // No hay sender de ese tipo: añadir transceiver nuevo y reasignar.
    final transceiver = await _pc!.addTransceiver(
      track: track,
      kind: track.kind == 'audio'
          ? RTCRtpMediaType.RTCRtpMediaTypeAudio
          : RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendOnly),
    );
    await transceiver.sender.replaceTrack(track);
  }

  Future<void> _ensureSocket(String base) async {
    if (_ws != null) return;
    final wsBase = _wsBaseFromHttpBase(base);
    final encodedSession = Uri.encodeComponent(_sessionId!);
    final uri = Uri.parse('$wsBase/ws/walk?session=$encodedSession');
    final canal = WebSocketChannel.connect(uri);
    await canal.ready;
    _ws = canal;
    _wsSub = canal.stream.listen(
      _onSignalingMessage,
      onError: (_) => _onSocketDown(),
      onDone: _onSocketDown,
      cancelOnError: false,
    );
  }

  String _wsBaseFromHttpBase(String base) {
    final u = Uri.parse(base);
    final scheme = u.scheme == 'https' ? 'wss' : 'ws';
    final host = u.host;
    final port = u.hasPort ? ':${u.port}' : '';
    return '$scheme://$host$port';
  }

  Future<void> _ensurePeerConnection() async {
    if (_pc != null) return;
    // LAN estricta (paso 3): sin servidores STUN ni TURN. Las IPs
    // las anuncia el centro en la misma WiFi.
    _pc = await createPeerConnection({
      'iceServers': <dynamic>[],
      'sdpSemantics': 'unified-plan',
    });
    _pc!.onIceCandidate = (RTCIceCandidate c) {
      if (c.candidate == null || c.candidate!.isEmpty) return;
      _ws?.sink.add(jsonEncode({
        'type': 'ice-candidate',
        'sessionId': _sessionId,
        'candidate': c.candidate,
        'sdpMid': c.sdpMid,
        'sdpMLineIndex': c.sdpMLineIndex,
      }));
    };
  }

  void _onSignalingMessage(dynamic crudo) {
    try {
      final msg = jsonDecode(crudo as String) as Map<String, dynamic>;
      final tipo = msg['type'] as String?;
      switch (tipo) {
        case 'answer':
          _pc?.setRemoteDescription(
            RTCSessionDescription(
              msg['sdp'] as String? ?? '',
              msg['sdpType'] as String? ?? 'answer',
            ),
          );
          break;
        case 'ice-candidate':
          final c = msg['candidate'] as String?;
          if (c == null || c.isEmpty) return;
          _pc?.addCandidate(
            RTCIceCandidate(
              c,
              msg['sdpMid'] as String?,
              msg['sdpMLineIndex'] as int?,
            ),
          );
          break;
        case 'peer-joined':
        case 'peer-left':
        case 'peer-status':
          // Telemetría útil para depurar. No cambia estado.
          break;
      }
    } catch (_) {
      // Mensaje malformado: ignorar. El signaling es auxiliar.
    }
  }

  void _onSocketDown() {
    if (_disposed) return;
    _setState(WalkLinkState.error, detail: 'signaling cerrado');
  }

  Future<void> _closePeer() async {
    await _pc?.close();
    _pc = null;
  }

  Future<void> _teardown({String? reason}) async {
    await _dropAudioTrack();
    await _dropVideoTrack();
    await _closePeer();
    await _wsSub?.cancel();
    _wsSub = null;
    try {
      await _ws?.sink.close();
    } catch (_) {}
    _ws = null;
    _setState(WalkLinkState.idle, detail: reason);
  }

  /// Llamado por `AppController.dispose()` — también seguro de llamar
  /// múltiples veces.
  @override
  Future<void> dispose() async {
    _disposed = true;
    await _teardown(reason: 'servicio cerrado');
    super.dispose();
  }
}