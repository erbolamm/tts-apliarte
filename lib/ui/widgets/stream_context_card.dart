import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/remote_studio_controller.dart';
import '../../models/community_models.dart';
import 'section_card.dart';

/// Tarjeta de control del contexto del directo (`!contexto`), chips rápidos
/// y selector de tema claro/oscuro para el overlay de OBS.
class StreamContextCard extends StatefulWidget {
  const StreamContextCard({super.key});

  @override
  State<StreamContextCard> createState() => _StreamContextCardState();
}

class _StreamContextCardState extends State<StreamContextCard> {
  final TextEditingController _contextCtrl = TextEditingController();

  @override
  void dispose() {
    _contextCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<RemoteStudioController>();
    final currentContext = studio.studioState.streamContext;
    final isLight = studio.studioState.overlayTheme == 'light';

    return SectionCard(
      title: '📌 Contexto del Directo (!contexto)',
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner actual
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1117),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1D9BF0).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF1D9BF0)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentContext.isNotEmpty
                        ? currentContext
                        : 'Sin contexto activo en pantalla',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentContext.isNotEmpty
                          ? Colors.white
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                if (currentContext.isNotEmpty)
                  IconButton(
                    tooltip: 'Limpiar contexto',
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _contextCtrl.clear();
                      studio.setStreamContext('');
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Campo de texto + botón actualizar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _contextCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Escribir nuevo contexto del directo…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (val) => studio.setStreamContext(val),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9BF0),
                ),
                onPressed: () => studio.setStreamContext(_contextCtrl.text),
                child: const Text('Aplicar'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chips de presets rápidos
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RemoteStudioState.defaultContextPresets.map((preset) {
              final active = currentContext == preset;
              return ActionChip(
                backgroundColor: active
                    ? const Color(0xFF1D9BF0).withValues(alpha: 0.25)
                    : null,
                label: Text(preset),
                onPressed: () {
                  _contextCtrl.text = preset;
                  studio.setStreamContext(preset);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Selector de tema del overlay OBS (Dark / Light)
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Tema claro en Overlay OBS'),
            subtitle: Text(
              isLight ? 'Modo claro (Light)' : 'Modo oscuro (Dark #0E1117)',
            ),
            value: isLight,
            onChanged: (val) =>
                studio.setOverlayTheme(val ? 'light' : 'dark'),
          ),
        ],
      ),
    );
  }
}
