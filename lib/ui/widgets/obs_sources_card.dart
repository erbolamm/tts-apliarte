import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/remote_studio_controller.dart';
import 'section_card.dart';

/// Tarjeta de control de fuentes individuales de OBS Studio (visibilidad 👁️ y
/// silencio de audio 🔇) para la escena activa.
class ObsSourcesCard extends StatefulWidget {
  const ObsSourcesCard({super.key});

  @override
  State<ObsSourcesCard> createState() => _ObsSourcesCardState();
}

class _ObsSourcesCardState extends State<ObsSourcesCard> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<RemoteStudioController>();
    final appCtrl = context.watch<AppController?>();
    final connected = appCtrl?.obsConectado ?? false;
    final sources = studio.filteredObsSources;

    return SectionCard(
      title: '🎛️ Fuentes de Escena OBS (${sources.length})',
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: studio.setObsSourcesSearch,
                  decoration: const InputDecoration(
                    hintText: 'Filtrar fuentes de la escena…',
                    prefixIcon: Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refrescar fuentes OBS',
                icon: const Icon(Icons.refresh, color: Color(0xFF1D9BF0)),
                onPressed: () => studio.refreshObsSources(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!connected && sources.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Conecta OBS WebSocket para listar y alternar fuentes e inputs de audio en tiempo real.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else if (sources.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No hay fuentes en la escena seleccionada.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            ...sources.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1117),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: item.enabled
                        ? const Color(0xFF1D9BF0).withValues(alpha: 0.35)
                        : const Color(0x22FFFFFF),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.sourceName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: item.enabled ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: item.muted ? 'Activar audio' : 'Silenciar audio',
                      icon: Icon(
                        item.muted ? Icons.volume_off : Icons.volume_up,
                        color: item.muted
                            ? Colors.redAccent
                            : const Color(0xFF1D9BF0),
                      ),
                      onPressed: () => studio.toggleObsSourceMute(item),
                    ),
                    IconButton(
                      tooltip: item.enabled
                          ? 'Ocultar fuente en OBS'
                          : 'Mostrar fuente en OBS',
                      icon: Icon(
                        item.enabled
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: item.enabled
                            ? const Color(0xFFFFB400)
                            : Colors.grey,
                      ),
                      onPressed: () => studio.toggleObsSourceVisibility(item),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
