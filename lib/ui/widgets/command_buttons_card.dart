import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/remote_studio_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/community_models.dart';
import '../../utils/app_strings.dart';
import 'section_card.dart';

/// Ancla para que el sub-Drawer de Twitch (paso 9) pueda desplazar la
/// pantalla hasta esta tarjeta con [Scrollable.ensureVisible], en vez de
/// navegar a una pantalla aparte que no existe.
final GlobalKey comandosUsuariosCanalesKey = GlobalKey();

/// Botonera de comandos rápidos para el chat de Twitch.
///
/// Incluye:
/// - Favoritos con estrella (⭐)
/// - Asistente modal para plantillas parametrizadas (`[usuario]`, `[canal]`, `[mensaje]`)
/// - Barra rápida de moderación (`Time Out 10m`, `Ban/Unban`, `Mute TTS`)
/// - Menciones, shoutouts, raids y anuncios persistentes
class CommandButtonsCard extends StatefulWidget {
  const CommandButtonsCard({super.key});

  @override
  State<CommandButtonsCard> createState() => _CommandButtonsCardState();
}

class _CommandButtonsCardState extends State<CommandButtonsCard> {
  static const String _shoutoutFijoApliArte = 'apliarte';

  String _tipoSeleccionado = 'todos'; // 'todos' | 'usuario' | 'canal' | 'mensaje'
  final TextEditingController _mentionCtrl = TextEditingController();
  final TextEditingController _shoutoutCtrl = TextEditingController();
  final TextEditingController _channelCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();
  final TextEditingController _modTargetCtrl = TextEditingController();

  @override
  void dispose() {
    _mentionCtrl.dispose();
    _shoutoutCtrl.dispose();
    _channelCtrl.dispose();
    _messageCtrl.dispose();
    _modTargetCtrl.dispose();
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

  Future<void> _openParameterizedWizard(
    BuildContext context,
    ParameterizedCommandTemplate tpl,
    AppController ctrl,
    RemoteStudioController? studio,
    AppStrings s,
  ) async {
    final needsUser = tpl.template.contains('[usuario]');
    final needsChannel = tpl.template.contains('[canal]');
    final needsMsg = tpl.template.contains('[mensaje]');

    final userCtrl = TextEditingController(
      text: RemoteStudioController.canonicalUsers.first,
    );
    final chanCtrl = TextEditingController(
      text: RemoteStudioController.canonicalChannels.first,
    );
    final msgCtrl = TextEditingController(
      text: RemoteStudioController.canonicalMessages.first,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0E1117),
          title: Text('⚡ ${tpl.label}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (needsUser) ...[
                  TextField(
                    controller: userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Parámetro [usuario]',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: {
                      ...RemoteStudioController.canonicalUsers,
                      if (studio != null)
                        ...studio.allUsers.take(4).map((u) => u.usuario),
                    }
                        .map(
                          (u) => ActionChip(
                            label: Text('@$u'),
                            onPressed: () => userCtrl.text = u,
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 12),
                ],
                if (needsChannel) ...[
                  TextField(
                    controller: chanCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Parámetro [canal]',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: RemoteStudioController.canonicalChannels
                        .map(
                          (c) => ActionChip(
                            label: Text('#$c'),
                            onPressed: () => chanCtrl.text = c,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (needsMsg) ...[
                  TextField(
                    controller: msgCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Parámetro [mensaje]',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: RemoteStudioController.canonicalMessages
                        .map(
                          (m) => ActionChip(
                            label: Text(
                              m.length > 26 ? '${m.substring(0, 26)}…' : m,
                            ),
                            onPressed: () => msgCtrl.text = m,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1D9BF0),
              ),
              onPressed: () {
                final resolved = tpl.template
                    .replaceAll('[usuario]', _sanitizeUsername(userCtrl.text))
                    .replaceAll('[canal]', _sanitizeUsername(chanCtrl.text))
                    .replaceAll('[mensaje]', msgCtrl.text.trim())
                    .trim();
                Navigator.pop(ctx, resolved);
              },
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Enviar al chat'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      _warnIfNotConnected(ctrl, s);
      await ctrl.sendChatMessage(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    final settings = settingsController.settings;
    final ctrl = context.watch<AppController>();
    final studio = context.watch<RemoteStudioController?>();
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
                children: settings.mentionUsers.map((username) {
                  final cmd = '/shoutout $username';
                  final isFav = studio?.isCommandFavorite(cmd) ?? false;
                  return InputChip(
                    avatar: GestureDetector(
                      onTap: () => studio?.toggleFavoriteCommand(cmd),
                      child: Icon(
                        isFav ? Icons.star : Icons.star_border,
                        size: 16,
                        color: isFav ? const Color(0xFFFFB400) : Colors.grey,
                      ),
                    ),
                    label: Text(cmd),
                    tooltip: s.mentionsSectionTitle,
                    onPressed: () {
                      _warnIfNotConnected(ctrl, s);
                      ctrl.mentionUser(username);
                    },
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () =>
                        _removeMention(settingsController, username),
                  );
                }).toList(),
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
                ...settings.shoutoutUsers.map((username) {
                  final cmd = '!so $username';
                  final isFav = studio?.isCommandFavorite(cmd) ?? false;
                  return InputChip(
                    avatar: GestureDetector(
                      onTap: () => studio?.toggleFavoriteCommand(cmd),
                      child: Icon(
                        isFav ? Icons.star : Icons.star_border,
                        size: 16,
                        color: isFav ? const Color(0xFFFFB400) : Colors.grey,
                      ),
                    ),
                    label: Text(cmd),
                    tooltip: s.shoutoutsSectionTitle,
                    onPressed: () {
                      _warnIfNotConnected(ctrl, s);
                      ctrl.shoutoutUser(username);
                    },
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () =>
                        _removeShoutout(settingsController, username),
                  );
                }),
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

          const Divider(height: 32),

          // ── Favoritos con estrella ⭐ ────────────────────────────────────
          if (studio != null && studio.favoriteCommands.isNotEmpty) ...[
            const Text(
              '⭐ Comandos Favoritos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFB400),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: studio.favoriteCommands.map((cmd) {
                return InputChip(
                  avatar: const Icon(
                    Icons.star,
                    size: 16,
                    color: Color(0xFFFFB400),
                  ),
                  label: Text(cmd),
                  onPressed: () {
                    _warnIfNotConnected(ctrl, s);
                    ctrl.sendChatMessage(cmd);
                  },
                  deleteIcon: const Icon(Icons.star_outline, size: 16),
                  onDeleted: () => studio.toggleFavoriteCommand(cmd),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // ── Plantillas Parametrizadas ([usuario], [canal], [mensaje]) ───
          const Text(
            '🧙‍♂️ Asistente de Comandos Parametrizados',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D9BF0),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RemoteStudioController.commandTemplates.map((tpl) {
              return ActionChip(
                avatar: const Icon(Icons.auto_fix_high, size: 16),
                label: Text(tpl.label),
                onPressed: () =>
                    _openParameterizedWizard(context, tpl, ctrl, studio, s),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Barra Rápida de Moderación ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1117),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '🛡️ Moderación Rápida',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB400),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _modTargetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Usuario objetivo (@usuario)…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.timer_outlined, size: 16),
                      label: const Text('Time Out 10m'),
                      onPressed: () {
                        final target = _sanitizeUsername(_modTargetCtrl.text);
                        if (target.isEmpty) return;
                        _warnIfNotConnected(ctrl, s);
                        ctrl.sendChatMessage('/timeout $target 600');
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.gavel, size: 16),
                      label: const Text('Ban/Unban'),
                      onPressed: () {
                        final target = _sanitizeUsername(_modTargetCtrl.text);
                        if (target.isEmpty) return;
                        final id = CommunityUser.buildId('twitch', target);
                        final user = studio?.getUser(id);
                        final willBan = !(user?.baneado ?? false);
                        studio?.toggleUserBan(id);
                        _warnIfNotConnected(ctrl, s);
                        ctrl.sendChatMessage(
                          willBan ? '/ban $target' : '/unban $target',
                        );
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.volume_off, size: 16),
                      label: const Text('Mute TTS'),
                      onPressed: () {
                        final target = _sanitizeUsername(_modTargetCtrl.text);
                        if (target.isEmpty) return;
                        if (ctrl.isUserIgnored(target)) {
                          ctrl.unignoreUser(target);
                        } else {
                          ctrl.ignoreUser(target);
                        }
                        studio?.toggleUserTtsMute(
                          CommunityUser.buildId('twitch', target),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

