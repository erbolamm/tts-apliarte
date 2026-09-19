import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../services/walk_link_service.dart';
import 'section_card.dart';

/// Enlace WebRTC P2P del modo paseo (paso 3 de la cadena
/// directo/tts-apliarte). Tarjeta que vive en la vista de Escenas
/// (rail 0) debajo de `ObsScenesCard` y antes de `StreamDeckCard`.
///
/// Si `scenesServerBaseUrl` está vacío, la tarjeta se oculta entera —
/// mismo patrón que `ObsScenesCard`: si no hay infraestructura, no se
/// muestra nada.
///
/// Regla canónica de iconos con tooltip a 3 s (AGENTS.md §3.2): los
/// interruptores son SwitchListTile con etiquetas claras, sin título
/// HTML nativo, sin preview local de la cámara (decisión de Javier,
/// 2026-09-16).
class WalkLinkCard extends StatelessWidget {
  const WalkLinkCard({super.key, required this.appController});

  final AppController appController;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>().settings;
    if (settings.scenesServerBaseUrl.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return SectionCard(
      title: '🚶 Enlace en directo (modo paseo)',
      initiallyExpanded: true,
      child: _WalkLinkBody(appController: appController),
    );
  }
}

class _WalkLinkBody extends StatelessWidget {
  const _WalkLinkBody({required this.appController});

  final AppController appController;

  @override
  Widget build(BuildContext context) {
    // El servicio emite cambios (estado, errores, mic/cam); los
    // reenviamos a través del AppController para refrescar la UI.
    final walk = appController.walkLink;
    return AnimatedBuilder(
      animation: walk,
      builder: (context, _) {
        final estado = walk.state;
        final detalle = walk.stateDetail;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SessionIdField(appController: appController),
            const SizedBox(height: 8),
            _SwitchTile(
              icon: Icons.mic,
              label: 'Voz',
              enabled: walk.micEnabled,
              onChanged: (v) => _toggleMic(context, v),
            ),
            _SwitchTile(
              icon: Icons.videocam,
              label: 'Cámara',
              enabled: walk.camEnabled,
              onChanged: (v) => _toggleCam(context, v),
            ),
            const SizedBox(height: 8),
            _StatusLine(estado: estado, detalle: detalle),
            const SizedBox(height: 8),
            const Text(
              'El móvil no muestra lo que está enviando — se ve solo en el '
              'directo de tu PC.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleMic(BuildContext context, bool value) async {
    final settings = context.read<SettingsController>();
    await settings.updateWith((s) => s.copyWith(walkMicEnabled: value));
  }

  Future<void> _toggleCam(BuildContext context, bool value) async {
    final settings = context.read<SettingsController>();
    await settings.updateWith((s) => s.copyWith(walkCamEnabled: value));
  }
}

class _SessionIdField extends StatefulWidget {
  const _SessionIdField({required this.appController});
  final AppController appController;

  @override
  State<_SessionIdField> createState() => _SessionIdFieldState();
}

class _SessionIdFieldState extends State<_SessionIdField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.appController.walkLink.sessionId ?? '',
    );
  }

  @override
  void didUpdateWidget(_SessionIdField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = widget.appController.walkLink.sessionId ?? '';
    if (_ctrl.text != current && !_ctrl.selection.isValid) {
      _ctrl.text = current;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      decoration: const InputDecoration(
        labelText: 'ID de sesión',
        helperText: 'Misma cadena que en walk.html?session=… (6 caracteres)',
        isDense: true,
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        widget.appController.setWalkSessionId(value);
      },
      onSubmitted: (value) {
        widget.appController.setWalkSessionId(value);
      },
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      secondary: Icon(icon, size: 20),
      title: Text(label),
      value: enabled,
      onChanged: onChanged,
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
        texto = 'Apagado';
        break;
      case WalkLinkState.requestingPermissions:
        color = Colors.amber;
        texto = detalle == null
            ? 'Pidiendo permiso…'
            : 'Pidiendo permiso de $detalle…';
        break;
      case WalkLinkState.connecting:
        color = Colors.blue;
        texto = 'Enlazando…';
        break;
      case WalkLinkState.connected:
        color = Colors.green;
        texto = 'En directo';
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
          child: Text(texto, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}