import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/remote_studio_controller.dart';

/// Banner superior que muestra el mensaje o `!sms` actualmente proyectado en OBS
/// con un botón de 1 toque para ocultarlo inmediatamente.
class LiveProjectionBanner extends StatelessWidget {
  const LiveProjectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<RemoteStudioController>();
    final state = studio.studioState;
    final featuredMsg = state.featuredMessage;
    final featuredSms = state.featuredSms;

    if (featuredMsg == null && featuredSms == null) {
      return const SizedBox.shrink();
    }

    final isSms = featuredSms != null;
    final author = isSms
        ? (featuredSms['nombreVisible'] ?? featuredSms['usuario'] ?? '')
        : (featuredMsg?['nombreVisible'] ?? featuredMsg?['usuario'] ?? '');
    final text = isSms
        ? (featuredSms['texto'] ?? '')
        : (featuredMsg?['texto'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB400), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility, color: Color(0xFFFFB400), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSms
                      ? '📩 SMS EN PANTALLA OBS · @$author'
                      : '💬 MENSAJE EN PANTALLA OBS · @$author',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB400),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$text',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFB400),
              foregroundColor: Colors.black,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: studio.clearActiveProjection,
            icon: const Icon(Icons.visibility_off, size: 16),
            label: const Text('Ocultar de OBS'),
          ),
        ],
      ),
    );
  }
}
