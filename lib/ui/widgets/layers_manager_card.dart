import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/settings_controller.dart';
import 'section_card.dart';

class LayersManagerCard extends StatefulWidget {
  final AppController appController;

  const LayersManagerCard({super.key, required this.appController});

  @override
  State<LayersManagerCard> createState() => _LayersManagerCardState();
}

class _LayersManagerCardState extends State<LayersManagerCard> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  String _getLayerName(String key) {
    switch (key) {
      case 'bg': return 'Fondo web ErBolamm';
      case 'streamelements': return 'StreamElements';
      case 'kofi': return 'Ko-fi Donaciones';
      case 'kofi_animated': return 'Ko-fi Animado';
      case 'kofi_goal': return 'Ko-fi Meta';
      case 'soundalerts': return 'SoundAlerts';
      case 'chat': return 'Chat TTS Burbujas';
      default: return key;
    }
  }

  String _getLayerEmoji(String key) {
    switch (key) {
      case 'bg': return '🌐';
      case 'streamelements': return '⭐';
      case 'kofi': return '☕';
      case 'kofi_animated': return '🎉';
      case 'kofi_goal': return '🎯';
      case 'soundalerts': return '🔊';
      case 'chat': return '💬';
      default: return '👁️‍🗨️';
    }
  }

  void _showAddCustomLayerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('➕ Añadir Overlay Personalizado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre corto (ej. Mi Alerta)',
                  hintText: 'Sin espacios recomendados',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL (Browser Source)',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5ECEF5)),
              onPressed: () {
                final name = _nameController.text.trim();
                final url = _urlController.text.trim();
                if (name.isNotEmpty && url.isNotEmpty) {
                  final settingsCtrl = context.read<SettingsController>();
                  final currentCustom = Map<String, String>.from(settingsCtrl.settings.customLayers);
                  
                  // Formatear la clave para que sea segura (sin espacios)
                  final safeKey = name.replaceAll(' ', '_').toLowerCase();
                  currentCustom[safeKey] = url;
                  
                  settingsCtrl.updateWith((s) => s.copyWith(customLayers: currentCustom));
                  
                  _nameController.clear();
                  _urlController.clear();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Añadir Capa'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCustomLayer(BuildContext context, String key) {
    final settingsCtrl = context.read<SettingsController>();
    final currentCustom = Map<String, String>.from(settingsCtrl.settings.customLayers);
    currentCustom.remove(key);
    settingsCtrl.updateWith((s) => s.copyWith(customLayers: currentCustom));
  }

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = context.watch<SettingsController>();
    final customLayersKeys = settingsCtrl.settings.customLayers.keys.toList();

    return SectionCard(
      title: 'Control de Capas (OBS en Vivo)',
      child: Column(
        children: [
          for (final layer in widget.appController.layers.entries)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              dense: true,
              leading: Text(
                _getLayerEmoji(layer.key),
                style: const TextStyle(fontSize: 20),
              ),
              title: Text(
                _getLayerName(layer.key),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (customLayersKeys.contains(layer.key)) ...[
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                      onPressed: () => _deleteCustomLayer(context, layer.key),
                      tooltip: 'Borrar Custom Layer',
                    ),
                  ],
                  IconButton(
                    icon: Icon(
                      layer.value ? Icons.visibility : Icons.visibility_off,
                      color: layer.value ? const Color(0xFF5ECEF5) : Colors.grey,
                    ),
                    onPressed: () {
                      widget.appController.toggleLayer(layer.key, !layer.value);
                    },
                  ),
                ],
              ),
            ),
            
          const Divider(),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: const Icon(Icons.add_circle, color: Color(0xFF5ECEF5)),
            title: const Text('Añadir Overlay Personalizado'),
            onTap: () => _showAddCustomLayerDialog(context),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }
}
