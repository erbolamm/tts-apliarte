import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/remote_studio_controller.dart';
import '../../models/community_models.dart';

/// Abre la Ficha CRM de un usuario en un BottomSheet modal adaptable.
Future<void> showUserFichaSheet(BuildContext context, CommunityUser user) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0E1117),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) => UserFichaSheet(
        initialUser: user,
        scrollController: scrollController,
      ),
    ),
  );
}

class UserFichaSheet extends StatefulWidget {
  const UserFichaSheet({
    super.key,
    required this.initialUser,
    this.scrollController,
  });

  final CommunityUser initialUser;
  final ScrollController? scrollController;

  @override
  State<UserFichaSheet> createState() => _UserFichaSheetState();
}

class _UserFichaSheetState extends State<UserFichaSheet> {
  late String _rol;
  late bool _esSuscriptor;
  late bool _silenciadoTts;
  late bool _baneado;
  late String _presetId;
  late double _pitch;
  late double _rate;
  late final TextEditingController _notasCtrl;
  late final TextEditingController _saludoCtrl;
  late final TextEditingController _mentionMsgCtrl;

  @override
  void initState() {
    super.initState();
    final u = widget.initialUser;
    _rol = u.rol;
    _esSuscriptor = u.esSuscriptor;
    _silenciadoTts = u.silenciadoTts;
    _baneado = u.baneado;
    final defaultPreset = TtsVoiceCatalog.assignAutomaticPreset(u.usuario);
    final cfg = u.vozConfig ?? defaultPreset.toConfig();
    _presetId = cfg.presetId;
    _pitch = cfg.pitch.clamp(0.5, 2.0);
    _rate = cfg.rate.clamp(0.1, 1.0);
    _notasCtrl = TextEditingController(text: u.notasContexto);
    _saludoCtrl = TextEditingController(
      text: u.sugerenciaSaludo.isNotEmpty
          ? u.sugerenciaSaludo
          : '¡Hola @${u.usuario}, qué alegría verte por el directo!',
    );
    _mentionMsgCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<RemoteStudioController>()
          .loadUserMessagesFromRepository(u.id);
    });
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    _saludoCtrl.dispose();
    _mentionMsgCtrl.dispose();
    super.dispose();
  }

  TtsVoiceConfig _buildCurrentVoiceConfig() {
    final preset = TtsVoiceCatalog.byId(_presetId);
    return TtsVoiceConfig(
      presetId: preset.id,
      lang: preset.lang,
      pitch: _pitch,
      rate: _rate,
      prefix: preset.prefix,
      suffix: preset.suffix,
    );
  }

  Future<void> _saveChanges(RemoteStudioController studio) async {
    final updated = widget.initialUser.copyWith(
      rol: _rol,
      esSuscriptor: _esSuscriptor,
      silenciadoTts: _silenciadoTts,
      baneado: _baneado,
      vozConfig: _buildCurrentVoiceConfig(),
      notasContexto: _notasCtrl.text.trim(),
      sugerenciaSaludo: _saludoCtrl.text.trim(),
      actualizadoEn: DateTime.now(),
    );
    await studio.saveUserFicha(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ficha de @${updated.usuario} guardada.'),
        backgroundColor: const Color(0xFF1D9BF0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<RemoteStudioController>();
    final appCtrl = context.read<AppController?>();
    final liveUser = studio.getUser(widget.initialUser.id) ?? widget.initialUser;
    final messages = studio.getMessagesForUser(liveUser.id);
    final chronologicalMessages = messages.reversed.toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E1117),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          // Cabecera de usuario
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF1D9BF0).withValues(alpha: 0.2),
                child: Text(
                  liveUser.nombreVisible.isNotEmpty
                      ? liveUser.nombreVisible[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFF1D9BF0),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            liveUser.nombreVisible,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: liveUser.plataforma == 'youtube'
                                ? Colors.redAccent.withValues(alpha: 0.2)
                                : const Color(0xFF9146FF).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            liveUser.plataforma.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: liveUser.plataforma == 'youtube'
                                  ? Colors.redAccent
                                  : const Color(0xFFB98EFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '@${liveUser.usuario} · ${liveUser.totalMensajes} mensajes',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9BF0),
                ),
                onPressed: () => _saveChanges(studio),
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Guardar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0x22FFFFFF)),

          // Selector de Rol y Suscriptor
          const SizedBox(height: 8),
          const Text(
            'Rol y Estado en la Comunidad',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFB400),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['normal', 'vip', 'mod', 'admin'].map((role) {
              final selected = _rol == role;
              return ChoiceChip(
                label: Text(role.toUpperCase()),
                selected: selected,
                selectedColor: const Color(0xFF1D9BF0),
                onSelected: (_) => setState(() => _rol = role),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('⭐ Suscriptor'),
                  value: _esSuscriptor,
                  onChanged: (v) => setState(() => _esSuscriptor = v),
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('🔇 Silenciar TTS'),
                  value: _silenciadoTts,
                  onChanged: (v) => setState(() => _silenciadoTts = v),
                ),
              ),
            ],
          ),

          const Divider(color: Color(0x22FFFFFF)),
          const SizedBox(height: 8),

          // Configuración de Voz TTS
          const Text(
            '🎙️ Voz TTS Personalizada',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFB400),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: TtsVoiceCatalog.presets.any((p) => p.id == _presetId)
                ? _presetId
                : 'normal',
            decoration: const InputDecoration(
              labelText: 'Preset de Voz (Normal / Animal / Cómica / Efecto / Acento)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: TtsVoiceCatalog.presets
                .map(
                  (preset) => DropdownMenuItem<String>(
                    value: preset.id,
                    child: Text(
                      '${preset.emoji} ${preset.label} [${preset.category.toUpperCase()}]',
                    ),
                  ),
                )
                .toList(),
            onChanged: (newId) {
              if (newId == null) return;
              final preset = TtsVoiceCatalog.byId(newId);
              setState(() {
                _presetId = preset.id;
                _pitch = preset.pitch;
                _rate = preset.rate;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tono (Pitch): ${_pitch.toStringAsFixed(2)}'),
                    Slider(
                      value: _pitch,
                      min: 0.5,
                      max: 2.0,
                      divisions: 30,
                      onChanged: (v) => setState(() => _pitch = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Velocidad (Rate): ${_rate.toStringAsFixed(2)}'),
                    Slider(
                      value: _rate,
                      min: 0.1,
                      max: 1.0,
                      divisions: 18,
                      onChanged: (v) => setState(() => _rate = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.volume_up, color: Color(0xFFFFB400)),
              label: const Text('Probar voz'),
              onPressed: () {
                final cfg = _buildCurrentVoiceConfig();
                final sampleText =
                    'Hola soy ${liveUser.nombreVisible} probando mi voz en el directo';
                appCtrl?.speakPreviewWithConfig(sampleText, cfg);
              },
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0x22FFFFFF)),
          const SizedBox(height: 8),

          // Notas de Contexto y Sugerencia de Saludo
          const Text(
            '📝 Notas CRM y Saludo Rápido',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFB400),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notasCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notas de contexto sobre este espectador',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _saludoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sugerencia de saludo',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB400),
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  final saludo = _saludoCtrl.text.trim();
                  if (saludo.isEmpty) return;
                  final msg = saludo.contains('@${liveUser.usuario}')
                      ? saludo
                      : '@${liveUser.usuario} $saludo';
                  appCtrl?.sendChatMessage(msg);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saludo enviado: $msg')),
                  );
                },
                icon: const Icon(Icons.waving_hand, size: 16),
                label: const Text('Enviar saludo'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Mención directa @usuario
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mentionMsgCtrl,
                  decoration: InputDecoration(
                    labelText: 'Responder a @${liveUser.usuario} en el chat…',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  final txt = _mentionMsgCtrl.text.trim();
                  if (txt.isEmpty) return;
                  appCtrl?.sendChatMessage('@${liveUser.usuario} $txt');
                  _mentionMsgCtrl.clear();
                },
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Mencionar'),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0x22FFFFFF)),
          const SizedBox(height: 8),

          // Historial de mensajes estilo WhatsApp (limit 50)
          Text(
            '💬 Historial de Mensajes (${chronologicalMessages.length}/50)',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D9BF0),
            ),
          ),
          const SizedBox(height: 8),
          if (chronologicalMessages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Sin mensajes registrados todavía en esta sesión.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...chronologicalMessages.map((msg) {
              final projected = studio.isMessageProjected(msg);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: projected
                      ? const Color(0xFF1D9BF0).withValues(alpha: 0.22)
                      : const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: projected
                        ? const Color(0xFF1D9BF0)
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
                            msg.texto,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            msg.fechaHora,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: projected
                          ? 'Ocultar de OBS'
                          : 'Proyectar mensaje en OBS',
                      icon: Icon(
                        projected ? Icons.visibility : Icons.visibility_outlined,
                        color: projected
                            ? const Color(0xFFFFB400)
                            : Colors.grey.shade400,
                      ),
                      onPressed: () => studio.toggleProjectedMessage(msg),
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
