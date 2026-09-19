import 'dart:async';
import 'package:flutter/material.dart';

/// Capa superpuesta en pantalla completa que emula el apagado de la pantalla
/// para ahorro de batería y control térmico durante el paseo.
///
/// Fondo negro puro (#000000): En paneles OLED/AMOLED, cada píxel negro está
/// físicamente inactivo (consumo nulo).
///
/// Interacción:
/// - Absorbe cualquier toque para evitar pulsaciones accidentales en el bolsillo.
/// - Un toque muestra un indicador tenue de desbloqueo durante 2,5 segundos.
/// - Un **doble toque** en cualquier parte de la pantalla restaura la visualización
///   completa y el brillo original de inmediato.
/// - La pulsación del botón Atrás del sistema también enciende la pantalla de forma segura.
class ScreenOffOverlay extends StatefulWidget {
  const ScreenOffOverlay({
    super.key,
    required this.onWakeUp,
  });

  /// Callback para reactivar la pantalla y salir del modo de bajo consumo.
  final VoidCallback onWakeUp;

  @override
  State<ScreenOffOverlay> createState() => _ScreenOffOverlayState();
}

class _ScreenOffOverlayState extends State<ScreenOffOverlay> {
  bool _showHint = false;
  Timer? _hintTimer;

  void _onTap() {
    _hintTimer?.cancel();
    setState(() {
      _showHint = true;
    });
    _hintTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showHint = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            widget.onWakeUp();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          onDoubleTap: widget.onWakeUp,
          child: Container(
            color: Colors.black,
            child: AnimatedOpacity(
              opacity: _showHint ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.touch_app_outlined,
                        size: 40,
                        color: Colors.white38,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Doble toque para encender',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Modo paseo activo • Ahorro OLED',
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white54,
                          backgroundColor: Colors.white10,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                        label: const Text('Encender pantalla'),
                        onPressed: widget.onWakeUp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
