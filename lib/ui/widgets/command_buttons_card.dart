import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../utils/app_strings.dart';
import 'section_card.dart';

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
  final TextEditingController _mentionCtrl = TextEditingController();
  final TextEditingController _shoutoutCtrl = TextEditingController();

  @override
  void dispose() {
    _mentionCtrl.dispose();
    _shoutoutCtrl.dispose();
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

    return SectionCard(
      title: s.commandButtonsTitle,
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          if (settings.shoutoutUsers.isEmpty)
            Text(
              s.shoutoutsEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: settings.shoutoutUsers
                  .map(
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
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
