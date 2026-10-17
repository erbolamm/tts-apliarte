import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/remote_studio_controller.dart';
import 'section_card.dart';

/// Tarjeta del buzón privado `!sms` con botón de proyección a OBS y borrado
/// seguro en 2 toques ("Pulsar de nuevo para confirmar").
class SmsInboxCard extends StatefulWidget {
  const SmsInboxCard({super.key});

  @override
  State<SmsInboxCard> createState() => _SmsInboxCardState();
}

class _SmsInboxCardState extends State<SmsInboxCard> {
  String? _armedDeleteId;
  bool _armedClearAll = false;

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<RemoteStudioController>();
    final items = studio.smsInbox;

    return SectionCard(
      title: '📩 Buzón !sms (${items.length})',
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mensajes enviados con !sms <texto> en el chat para proyectar en directo.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              if (items.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: _armedClearAll
                        ? const Color(0xFFFFB400)
                        : Colors.redAccent,
                  ),
                  onPressed: () {
                    if (_armedClearAll) {
                      setState(() => _armedClearAll = false);
                      studio.clearAllSms();
                    } else {
                      setState(() => _armedClearAll = true);
                    }
                  },
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  label: Text(
                    _armedClearAll
                        ? 'Pulsar de nuevo para confirmar'
                        : 'Vaciar buzón',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No hay mensajes !sms pendientes.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...items.map((sms) {
              final projected = studio.isSmsProjected(sms) || sms.enPantalla;
              final armed = _armedDeleteId == sms.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: projected
                      ? const Color(0xFF1D9BF0).withValues(alpha: 0.18)
                      : const Color(0xFF0E1117),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: projected
                        ? const Color(0xFFFFB400)
                        : const Color(0x22FFFFFF),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@${sms.nombreVisible}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D9BF0),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sms.texto,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: projected
                          ? 'Ocultar SMS de OBS'
                          : 'Proyectar SMS en OBS',
                      icon: Icon(
                        projected ? Icons.visibility : Icons.visibility_outlined,
                        color: projected
                            ? const Color(0xFFFFB400)
                            : Colors.grey.shade400,
                      ),
                      onPressed: () => studio.toggleProjectedSms(sms),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor:
                            armed ? const Color(0xFFFFB400) : Colors.redAccent,
                      ),
                      onPressed: () {
                        if (armed) {
                          setState(() => _armedDeleteId = null);
                          studio.deleteSms(sms.id);
                        } else {
                          setState(() => _armedDeleteId = sms.id);
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(
                        armed ? 'Pulsar de nuevo para confirmar' : 'Borrar',
                      ),
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
