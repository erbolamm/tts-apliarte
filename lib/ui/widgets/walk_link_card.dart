import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../services/walk_link_service.dart';
import 'section_card.dart';

/// Enlace WebRTC P2P (modo directo/paseo).
///
/// Ofrece dos botones táctiles independientes y destacados:
/// - 🎙️ Audio (micrófono del móvil transmitiendo al directo)
/// - 📹 Cámara (vídeo del móvil transmitiendo a OBS)
///
/// Decisión de diseño:
/// - Cada botón es totalmente independiente (activa/desactiva su pista).
/// - NUNCA se muestra vista previa local del vídeo en la pantalla del móvil
///   (ahorra batería y mantiene la interfaz despejada).
/// - El vídeo y el audio se visualizan en el PC añadiendo en OBS la fuente:
///   `http://<servidor>/walk.html?session=<sesion>`.
class WalkLinkCard extends StatelessWidget {
  const WalkLinkCard({super.key, required this.appController});

  final AppController appController;

  @override
  Widget build(BuildContext context) {
    if (!appController.isInitialized) {
      return const SizedBox.shrink();
    }
    return SectionCard(
      title: '📡 Retransmisión Móvil (Audio y Cámara)',
      initiallyExpanded: true,
      child: _WalkLinkBody(appController: appController),
    );
  }
}

class _WalkLinkBody extends StatelessWidget {
  const _WalkLinkBody({required this.appController});

  final AppController appController;

  static const String defaultTailscaleUrl = 'http://100.75.119.108:8790';
  static const String defaultLanUrl = 'http://192.168.1.10:8790';

  @override
  Widget build(BuildContext context) {
    final walk = appController.walkLink;
    final settingsCtrl = context.watch<SettingsController>();

    return AnimatedBuilder(
      animation: walk,
      builder: (context, _) {
        final estado = walk.state;
        final detalle = walk.stateDetail;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dos botones grandes e independientes ─────────────────────────
            Row(
              children: [
                Expanded(
                  child: _TransmissionButton(
                    icon: walk.micEnabled ? Icons.mic : Icons.mic_off,
                    label: 'AUDIO',
                    statusText: walk.micEnabled ? 'TRANSMITIENDO' : 'APAGADO',
                    isActive: walk.micEnabled,
                    activeColor: Colors.greenAccent.shade400,
                    onTap: () => _toggleMic(context, walk.micEnabled),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TransmissionButton(
                    icon: walk.camEnabled ? Icons.videocam : Icons.videocam_off,
                    label: 'CÁMARA',
                    statusText: walk.camEnabled ? 'TRANSMITIENDO' : 'APAGADA',
                    subtitle: 'Sin preview en móvil',
                    isActive: walk.camEnabled,
                    activeColor: Colors.lightBlueAccent,
                    onTap: () => _toggleCam(context, walk.camEnabled),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Estado de la señal WebRTC ───────────────────────────────────
            _StatusLine(estado: estado, detalle: detalle),
            const SizedBox(height: 12),

            // ── Botón de apagar pantalla (ahorro de batería) ─────────────────
            FilledButton.icon(
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Apagar pantalla (ahorro batería)'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => appController.enterScreenOffMode(),
            ),
            const SizedBox(height: 12),

            // ── Configuración y Enlace para OBS (plegable) ──────────────────
            _ConfigAndObsSection(
              appController: appController,
              settingsCtrl: settingsCtrl,
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleMic(BuildContext context, bool currentlyEnabled) async {
    final settingsCtrl = context.read<SettingsController>();
    _ensureDefaults(settingsCtrl);
    await settingsCtrl.updateWith(
      (s) => s.copyWith(walkMicEnabled: !currentlyEnabled),
    );
  }

  Future<void> _toggleCam(BuildContext context, bool currentlyEnabled) async {
    final settingsCtrl = context.read<SettingsController>();
    _ensureDefaults(settingsCtrl);
    await settingsCtrl.updateWith(
      (s) => s.copyWith(walkCamEnabled: !currentlyEnabled),
    );
  }

  void _ensureDefaults(SettingsController settingsCtrl) {
    if (settingsCtrl.settings.scenesServerBaseUrl.trim().isEmpty) {
      settingsCtrl.updateWith(
        (s) => s.copyWith(scenesServerBaseUrl: defaultTailscaleUrl),
      );
    }
    if (appController.walkLink.sessionId == null ||
        appController.walkLink.sessionId!.trim().isEmpty) {
      appController.setWalkSessionId('directo');
    }
  }
}

class _TransmissionButton extends StatelessWidget {
  const _TransmissionButton({
    required this.icon,
    required this.label,
    required this.statusText,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String statusText;
  final String? subtitle;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isActive
        ? activeColor.withValues(alpha: 0.18)
        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100);
    final borderColor = isActive
        ? activeColor
        : (isDark ? Colors.white24 : Colors.grey.shade400);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isActive ? 2.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 34,
                color: isActive
                    ? activeColor
                    : (isDark ? Colors.white54 : Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                  color: isActive ? activeColor : null,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? activeColor : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? activeColor : Colors.grey,
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigAndObsSection extends StatefulWidget {
  const _ConfigAndObsSection({
    required this.appController,
    required this.settingsCtrl,
  });

  final AppController appController;
  final SettingsController settingsCtrl;

  @override
  State<_ConfigAndObsSection> createState() => _ConfigAndObsSectionState();
}

class _ConfigAndObsSectionState extends State<_ConfigAndObsSection> {
  late final TextEditingController _serverCtrl;
  late final TextEditingController _sessionCtrl;

  @override
  void initState() {
    super.initState();
    final currentServer = widget.settingsCtrl.settings.scenesServerBaseUrl;
    _serverCtrl = TextEditingController(
      text: currentServer.isNotEmpty
          ? currentServer
          : _WalkLinkBody.defaultTailscaleUrl,
    );
    final currentSession = widget.appController.walkLink.sessionId ?? '';
    _sessionCtrl = TextEditingController(
      text: currentSession.isNotEmpty ? currentSession : 'directo',
    );
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    _sessionCtrl.dispose();
    super.dispose();
  }

  String get _obsSourceUrl {
    final server = _serverCtrl.text.trim();
    final session = _sessionCtrl.text.trim();
    if (server.isEmpty) return '';
    final cleanServer =
        server.endsWith('/') ? server.substring(0, server.length - 1) : server;
    return '$cleanServer/walk.html?session=${session.isNotEmpty ? session : "directo"}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: const Icon(Icons.settings, size: 20),
        title: const Text(
          'Configurar servidor y enlace OBS',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Dirección del Mac y URL para Browser Source',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: _serverCtrl,
            decoration: const InputDecoration(
              labelText: 'Servidor directo (Mac)',
              helperText: 'Puerto :8790 del Mac (Tailscale o LAN)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              widget.settingsCtrl.updateWith(
                (s) => s.copyWith(scenesServerBaseUrl: val.trim()),
              );
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Tailscale'),
                avatar: const Icon(Icons.vpn_lock, size: 14),
                onPressed: () {
                  _serverCtrl.text = _WalkLinkBody.defaultTailscaleUrl;
                  widget.settingsCtrl.updateWith(
                    (s) => s.copyWith(
                      scenesServerBaseUrl: _WalkLinkBody.defaultTailscaleUrl,
                    ),
                  );
                },
              ),
              ActionChip(
                label: const Text('LAN'),
                avatar: const Icon(Icons.wifi, size: 14),
                onPressed: () {
                  _serverCtrl.text = _WalkLinkBody.defaultLanUrl;
                  widget.settingsCtrl.updateWith(
                    (s) => s.copyWith(
                      scenesServerBaseUrl: _WalkLinkBody.defaultLanUrl,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sessionCtrl,
            decoration: const InputDecoration(
              labelText: 'ID de sesión',
              helperText: 'Identificador para enlazar teléfono y OBS',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              widget.appController.setWalkSessionId(val.trim());
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar URL para OBS (Cámara/Audio)'),
            onPressed: () {
              final url = _obsSourceUrl;
              if (url.isEmpty) return;
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'URL copiada: $url\nAgrégala en OBS como fuente Navegador.',
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.estado, required this.detalle});
  final WalkLinkState estado;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String texto;
    switch (estado) {
      case WalkLinkState.idle:
        color = Colors.grey;
        texto = 'Señal apagada';
        break;
      case WalkLinkState.requestingPermissions:
        color = Colors.amber;
        texto = detalle == null
            ? 'Pidiendo permiso…'
            : 'Pidiendo permiso de $detalle…';
        break;
      case WalkLinkState.connecting:
        color = Colors.blue;
        texto = 'Enlazando con el Mac…';
        break;
      case WalkLinkState.connected:
        color = Colors.green;
        texto = 'En directo (WebRTC P2P)';
        break;
      case WalkLinkState.error:
        color = Colors.red;
        texto = detalle == null ? 'Sin señal' : 'Error: $detalle';
        break;
    }
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto, style: TextStyle(color: color, fontSize: 13)),
        ),
      ],
    );
  }
}