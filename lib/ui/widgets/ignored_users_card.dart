import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../utils/app_strings.dart';
import 'section_card.dart';

/// GlobalKey para que el Drawer o cualquier botón pueda hacer scroll
/// hasta la tarjeta de usuarios silenciados.
final GlobalKey ignoredUsersCardKey = GlobalKey();

/// Tarjeta visual para gestionar la lista de usuarios y bots silenciados
/// en el TTS al vuelo.
///
/// Permite añadir usuarios introduciendo su nombre en un campo de texto y
/// sacarlos de la lista interactuando con los chips borrables (X).
class IgnoredUsersCard extends StatefulWidget {
  const IgnoredUsersCard({
    super.key,
    this.initiallyExpanded = true,
  });

  final bool initiallyExpanded;

  @override
  State<IgnoredUsersCard> createState() => _IgnoredUsersCardState();
}

class _IgnoredUsersCardState extends State<IgnoredUsersCard> {
  final TextEditingController _userCtrl = TextEditingController();

  @override
  void dispose() {
    _userCtrl.dispose();
    super.dispose();
  }

  void _addUser(AppController appController) {
    final raw = _userCtrl.text;
    var name = raw.trim();
    while (name.startsWith('@')) {
      name = name.substring(1).trim();
    }
    if (name.isEmpty) return;

    appController.ignoreUser(name);
    _userCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    final appController = context.watch<AppController>();
    final settings = settingsController.settings;
    final s = AppStrings(settings.uiLanguage);
    final theme = Theme.of(context);

    final ignoredList = settings.ignoredUsers;

    return SectionCard(
      key: ignoredUsersCardKey,
      title: '🚫 ${s.ignoredUsersTitle}',
      initiallyExpanded: widget.initiallyExpanded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.ignoredUsersSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),

          // ── Campo de texto para añadir usuario al vuelo ──
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userCtrl,
                  decoration: InputDecoration(
                    labelText: s.ignoredUserInputLabel,
                    hintText: s.ignoredUserInputHint,
                    prefixIcon: const Icon(Icons.person_add_outlined),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addUser(appController),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _addUser(appController),
                icon: const Icon(Icons.add, size: 18),
                label: Text(s.addBtn),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Cabecera de la lista con contador y botón de restablecer ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${s.ignoredUsersCount} (${ignoredList.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => appController.resetIgnoredUsers(),
                icon: const Icon(Icons.restore, size: 16),
                label: Text(
                  s.resetIgnoredUsersBtn,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Chips de usuarios silenciados ──
          if (ignoredList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                s.ignoredUsersEmpty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ignoredList
                  .map(
                    (username) => InputChip(
                      avatar: const Icon(
                        Icons.volume_off,
                        size: 16,
                        color: Colors.orangeAccent,
                      ),
                      label: Text(username),
                      tooltip: '${s.removeIgnoredTooltip}: $username',
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => appController.unignoreUser(username),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
