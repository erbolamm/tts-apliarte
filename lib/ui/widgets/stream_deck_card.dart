import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';

// Javier: Este archivo modulariza los botones que controlan escenas y textos del OBS.
class StreamDeckCard extends StatefulWidget {
  const StreamDeckCard({super.key});

  @override
  State<StreamDeckCard> createState() => _StreamDeckCardState();
}

class _StreamDeckCardState extends State<StreamDeckCard> {
  final TextEditingController _subtitleCtrl = TextEditingController(
    text: 'PROGRAMANDO APP',
  );
  final TextEditingController _poweredCtrl = TextEditingController(
    text: 'DIRECTO GESTIONADO POR APLIARTETTS',
  );
  final TextEditingController _timerCtrl = TextEditingController(text: '3');

  @override
  void dispose() {
    _subtitleCtrl.dispose();
    _poweredCtrl.dispose();
    _timerCtrl.dispose();
    super.dispose();
  }

  void _updateSettings(AppController ctrl) {
    ctrl.updateStreamInfo(_subtitleCtrl.text, _poweredCtrl.text);
    final min = int.tryParse(_timerCtrl.text) ?? 3;
    ctrl.setStreamTimer(min);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Textos y Temporizador actualizados en OBS'),
      ),
    );
  }

  Widget _buildSceneBtn(
    AppController ctrl,
    String id,
    String label,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        ctrl.setStreamScene(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎬 Escena cambiada en OBS: $label'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        width: 110, // Fixed width for scroll
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AppController>();
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: -5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dashboard_customize, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'Stream Deck',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _updateSettings(ctrl),
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Actualizar Textos'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Disposición responsiva Wrap para los inputs (sin scroll horizontal)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _subtitleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Subtítulo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _poweredCtrl,
                  decoration: InputDecoration(
                    labelText: 'Powered By',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _timerCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Minutos',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Disposición responsiva Wrap para los botones (sin scroll horizontal)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSceneBtn(ctrl, 'scene-start', 'INICIO', Icons.timer, Colors.orange),
              _buildSceneBtn(ctrl, 'scene-chat', 'CHARLA', Icons.chat_bubble, Colors.blue),
              _buildSceneBtn(ctrl, 'scene-game', 'JUEGO', Icons.videogame_asset, Colors.green),
              _buildSceneBtn(ctrl, 'scene-brb', 'PAUSA (BRB)', Icons.coffee, Colors.redAccent),
              _buildSceneBtn(ctrl, 'scene-dev', 'DEV', Icons.code, Colors.purpleAccent),
            ],
          ),
        ],
      ),
    );
  }
}
