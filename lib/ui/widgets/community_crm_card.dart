import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/remote_studio_controller.dart';
import '../../models/community_models.dart';
import 'section_card.dart';
import 'user_ficha_sheet.dart';

/// Tarjeta CRM de Comunidad con buscador debounced (250ms), filtros por
/// plataforma/rol y acceso directo a la ficha de cada espectador.
class CommunityCrmCard extends StatefulWidget {
  const CommunityCrmCard({super.key});

  @override
  State<CommunityCrmCard> createState() => _CommunityCrmCardState();
}

class _CommunityCrmCardState extends State<CommunityCrmCard> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<RemoteStudioController>();
    final users = studio.filteredUsers;

    return SectionCard(
      title: '👥 Comunidad CRM (${users.length})',
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Buscador con debounce de 250ms
          TextField(
            controller: _searchCtrl,
            onChanged: studio.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Buscar espectador, nota o mensaje…',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1D9BF0)),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        studio.setSearchQuery('', immediate: true);
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Chips de filtrado
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FilterChipItem(id: 'todos', label: 'Todos'),
              _FilterChipItem(id: 'twitch', label: 'Twitch'),
              _FilterChipItem(id: 'youtube', label: 'YouTube'),
              _FilterChipItem(id: 'vip', label: 'VIP'),
              _FilterChipItem(id: 'mod', label: 'Mod'),
            ],
          ),
          const SizedBox(height: 12),

          if (users.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No hay espectadores que coincidan con el filtro.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _ViewerCrmTile(user: user);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({required this.id, required this.label});

  final String id;
  final String label;

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<RemoteStudioController>();
    final selected = studio.activeFilter == id;
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF1D9BF0).withValues(alpha: 0.25),
      checkmarkColor: const Color(0xFF1D9BF0),
      onSelected: (_) => studio.setFilter(id),
    );
  }
}

class _ViewerCrmTile extends StatelessWidget {
  const _ViewerCrmTile({required this.user});

  final CommunityUser user;

  @override
  Widget build(BuildContext context) {
    final studio = context.read<RemoteStudioController>();
    final preset = user.vozConfig != null
        ? TtsVoiceCatalog.byId(user.vozConfig!.presetId)
        : TtsVoiceCatalog.assignAutomaticPreset(user.usuario);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showUserFichaSheet(context, user),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1117),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: user.rol == 'vip' || user.esSuscriptor
                ? const Color(0xFFFFB400).withValues(alpha: 0.4)
                : const Color(0x22FFFFFF),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1D9BF0).withValues(alpha: 0.2),
              child: Text(
                preset.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        user.nombreVisible,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      _RoleBadge(role: user.rol),
                      if (user.esSuscriptor)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB400).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '⭐ SUB',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFB400),
                            ),
                          ),
                        ),
                      Text(
                        '(${user.totalMensajes} msj)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  if (user.ultimoTexto.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.ultimoTexto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: user.silenciadoTts ? 'Reactivar TTS' : 'Silenciar TTS',
              icon: Icon(
                user.silenciadoTts ? Icons.volume_off : Icons.volume_up,
                color: user.silenciadoTts
                    ? Colors.redAccent
                    : const Color(0xFF1D9BF0),
              ),
              onPressed: () => studio.toggleUserTtsMute(user.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case 'admin':
        color = Colors.redAccent;
        break;
      case 'mod':
        color = Colors.greenAccent;
        break;
      case 'vip':
        color = const Color(0xFFFFB400);
        break;
      default:
        color = const Color(0xFF1D9BF0);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
