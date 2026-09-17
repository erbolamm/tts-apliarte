import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';
import 'section_card.dart';

/// Escenas reales de OBS, leídas por `obs-websocket` (paso nuevo, pedido por
/// Javier el 2026-09-16 en directo). Si no hay conexión, no se dibuja nada
/// — nunca un error ni una lista vacía que parezca real.
class ObsScenesCard extends StatelessWidget {
  const ObsScenesCard({super.key, required this.appController});

  final AppController appController;

  @override
  Widget build(BuildContext context) {
    if (!appController.obsConectado) {
      return const SizedBox.shrink();
    }
    final escenas = appController.obsEscenas;
    return SectionCard(
      title: '🎬 Escenas de OBS',
      initiallyExpanded: true,
      trailing: IconButton(
        icon: const Icon(Icons.refresh, size: 20),
        tooltip: 'Reconectar con OBS',
        onPressed: () => appController.reconectarObs(),
      ),
      child: escenas.isEmpty
          ? const Text(
              'Conectado a OBS, pero no encontró ninguna escena.',
              style: TextStyle(color: Colors.grey),
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: escenas
                  .map(
                    (escena) => FilledButton.tonal(
                      onPressed: () => appController.cambiarEscenaObs(escena.name),
                      child: Text(escena.name),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
