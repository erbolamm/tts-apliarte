import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../utils/app_strings.dart';
import 'section_card.dart';

/// Ancla para que el sub-Drawer de Twitch (paso 9) pueda desplazar la
/// pantalla hasta esta tarjeta con [Scrollable.ensureVisible], en vez de
/// navegar a una pantalla aparte que no existe.
final GlobalKey comandosUsuariosCanalesKey = GlobalKey();

/// Botonera de comandos rápidos para el chat de Twitch.
///
/// Dos listas editables y persistentes (menciones y shoutouts). Cada entrada
/// se muestra como un botón/chip: pulsarlo manda el mensaje correspondiente
/// al chat en directo reutilizando [AppController.mentionUser] /
/// [AppController.shoutoutUser], que a su vez usan la conexión IRC ya
/// existente ([AppController.sendChatMessage]).
class CommandButtonsCard extends StatefulWidget {
  const CommandButtonsCard({super.key});

  @override
  State<CommandButtonsCard> createState() => _CommandButtonsCardState();
}

class _CommandButtonsCardState extends State<CommandButtonsCard> {
  /// Entrada fija de shoutout de ApliArte, creador de la app (paso 6 de la
  /// cadena directo/tts-apliarte). No vive en `shoutoutUsers` — así no hay
  /// forma de que la UI de borrado (`onDeleted`) la elimine por error.
  static const String _shoutoutFijoApliArte = 'apliarte';

  String _tipoSeleccionado = 'todos'; // 'todos' | 'usuario' | 'canal' | 'mensaje'
  final TextEditingController _mentionCtrl = TextEditingController();
  final TextEditingController _shoutoutCtrl = TextEditingController();
  final TextEditingController _channelCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _mentionCtrl.dispose();
    _shoutoutCtrl.dispose();
    _channelCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  String _sanitizeUsername(String raw) {
    var value = raw.trim();
    while (value.startsWith('@')) {
      value = value.substring(1);
    }
    return value.trim();
  }

  void _addMention(SettingsController settingsController) {
    final name = _sanitizeUsername(_mentionCtrl.text);
    if (name.isEmpty) {
      return;
    }
    final current = settingsController.settings.mentionUsers;
    if (current.any((u) => u.toLowerCase() == name.toLowerCase())) {
      _mentionCtrl.clear();
      return;
    }
    settingsController.updateWith(
      (s) => s.copyWith(mentionUsers: [...s.mentionUsers, name]),
    );
    _mentionCtrl.clear();
  }

  void _removeMention(SettingsController settingsController, String name) {
    settingsController.updateWith(
      (s) => s.copyWith(
        mentionUsers: s.mentionUsers.where((u) => u != name).toList(),
      ),
    );
  }

  void _addShoutout(SettingsController settingsController) {
    final name = _sanitizeUsername(_shoutoutCtrl.text);
    if (name.isEmpty) {
      return;
    }
    final current = settingsController.settings.shoutoutUsers;
    if (current.any((u) => u.toLowerCase() == name.toLowerCase())) {
      _shoutoutCtrl.clear();
      return;
    }
    settingsController.updateWith(
      (s) => s.copyWith(shoutoutUsers: [...s.shoutoutUsers, name]),
    );
    _shoutoutCtrl.clear();
  }

  void _removeShoutout(SettingsController settingsController, String name) {
    settingsController.updateWith(
      (s) => s.copyWith(
        shoutoutUsers: s.shoutoutUsers.where((u) => u != name).toList(),
      ),
    );
  }

  void _addChannel(SettingsController settingsController) {
    final ch = _sanitizeUsername(_channelCtrl.text);
    if (ch.isEmpty) return;
    final current = settingsController.settings.savedChannels;
    if (current.any((c) => c.toLowerCase() == ch.toLowerCase())) {
      _channelCtrl.clear();
      return;
    }
    settingsController.updateWith(
      (s) => s.copyWith(savedChannels: [...s.savedChannels, ch]),
    );
    _channelCtrl.clear();
  }

  void _removeChannel(SettingsController settingsController, String channel) {
    settingsController.updateWith(
      (s) => s.copyWith(
        savedChannels: s.savedChannels.where((c) => c != channel).toList(),
      ),
    );
  }

  void _addMessage(SettingsController settingsController) {
    final msg = _messageCtrl.text.trim();
    if (msg.isEmpty) return;
    final current = settingsController.settings.savedMessages;
    if (current.contains(msg)) {
      _messageCtrl.clear();
      return;
    }
    settingsController.updateWith(
      (s) => s.copyWith(savedMessages: [...s.savedMessages, msg]),
    );
    _messageCtrl.clear();
  }

  void _removeMessage(SettingsController settingsController, String message) {
    settingsController.updateWith(
      (s) => s.copyWith(
        savedMessages: s.savedMessages.where((m) => m != message).toList(),
      ),
    );
  }

  void _warnIfNotConnected(AppController ctrl, AppStrings s) {
    if (ctrl.isConnected) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.notConnectedToSend)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    final settings = settingsController.settings;
    final ctrl = context.watch<AppController>();
    final s = AppStrings(settings.uiLanguage);
    final theme = Theme.of(context);

    final showUsuarios = _tipoSeleccionado == 'todos' || _tipoSeleccionado == 'usuario';
    final showCanales = _tipoSeleccionado == 'todos' || _tipoSeleccionado == 'canal';
    final showMensajes = _tipoSeleccionado == 'todos' || _tipoSeleccionado == 'mensaje';

    return SectionCard(
      key: comandosUsuariosCanalesKey,
      title: s.commandButtonsTitle,
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Selector de Tipo de Argumento ───────────────────────────────
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'todos', label: Text('Todos')),
              ButtonSegment(value: 'usuario', label: Text('👤 Usuario')),
              ButtonSegment(value: 'canal', label: Text('📡 Canal')),
              ButtonSegment(value: 'mensaje', label: Text('💬 Mensaje')),
            ],
            selected: {_tipoSeleccionado},
            onSelectionChanged: (newSelection) {
              setState(() {
                _tipoSeleccionado = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 16),

          // ── Sección Usuarios: Menciones y Shoutouts ─────────────────────
          if (showUsuarios) ...[
            Text(
              s.mentionsSectionTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mentionCtrl,
                    decoration: InputDecoration(
                      labelText: s.mentionInputHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addMention(settingsController),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _addMention(settingsController),
                  child: Text(s.addBtn),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (settings.mentionUsers.isEmpty)
              Text(
                s.mentionsEmpty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: settings.mentionUsers
                    .map(
                      (username) => InputChip(
                        label: Text('/shoutout $username'),
                        tooltip: s.mentionsSectionTitle,
                        onPressed: () {
                          _warnIfNotConnected(ctrl, s);
                          ctrl.mentionUser(username);
                        },
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () =>
                            _removeMention(settingsController, username),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              s.shoutoutsSectionTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _shoutoutCtrl,
                    decoration: InputDecoration(
                      labelText: s.shoutoutInputHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addShoutout(settingsController),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _addShoutout(settingsController),
                  child: Text(s.addBtn),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InputChip(
                  avatar: const Icon(Icons.push_pin_rounded, size: 16),
                  label: const Text('!so $_shoutoutFijoApliArte'),
                  tooltip: s.fixedShoutoutTooltip,
                  onPressed: () {
                    _warnIfNotConnected(ctrl, s);
                    ctrl.shoutoutUser(_shoutoutFijoApliArte);
                  },
                ),
                ...settings.shoutoutUsers.map(
                  (username) => InputChip(
                    label: Text('!so $username'),
                    tooltip: s.shoutoutsSectionTitle,
                    onPressed: () {
                      _warnIfNotConnected(ctrl, s);
                      ctrl.shoutoutUser(username);
                    },
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () =>
                        _removeShoutout(settingsController, username),
                  ),
                ),
              ],
            ),
            if (settings.shoutoutUsers.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                s.shoutoutsEmpty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],

          // ── Sección Canales (/raid) ─────────────────────────────────────
          if (showCanales) ...[
            if (showUsuarios) const Divider(height: 32),
            Text(
              '📡 Comandos de Canal (/raid)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _channelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del canal…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addChannel(settingsController),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _addChannel(settingsController),
                  child: const Text('Guardar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: settings.savedChannels
                  .map(
                    (channel) => InputChip(
                      label: Text('/raid $channel'),
                      tooltip: 'Lanzar raid a $channel',
                      onPressed: () {
                        _warnIfNotConnected(ctrl, s);
                        ctrl.sendChatMessage('/raid $channel');
                      },
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeChannel(settingsController, channel),
                    ),
                  )
                  .toList(),
            ),
          ],

          // ── Sección Mensajes (/announce) ────────────────────────────────
          if (showMensajes) ...[
            if (showUsuarios || showCanales) const Divider(height: 32),
            Text(
              '💬 Comandos de Mensaje (/announce)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje a anunciar…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addMessage(settingsController),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _addMessage(settingsController),
                  child: const Text('Guardar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: settings.savedMessages
                  .map(
                    (message) => InputChip(
                      label: Text('/announce $message'),
                      tooltip: 'Anunciar en el chat',
                      onPressed: () {
                        _warnIfNotConnected(ctrl, s);
                        ctrl.sendChatMessage('/announce $message');
                      },
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeMessage(settingsController, message),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
