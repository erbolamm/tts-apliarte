import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../utils/obs_qr_parser.dart';

/// Escanea el QR de "Mostrar información de conexión" de OBS y devuelve los
/// datos ya interpretados con `Navigator.pop`. No guarda nada por sí misma
/// — quien la abre decide qué hacer con el resultado.
class ObsQrScannerScreen extends StatefulWidget {
  const ObsQrScannerScreen({super.key});

  @override
  State<ObsQrScannerScreen> createState() => _ObsQrScannerScreenState();
}

class _ObsQrScannerScreenState extends State<ObsQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _yaLeido = false;

  void _alDetectar(BarcodeCapture captura) {
    if (_yaLeido) return;
    for (final codigo in captura.barcodes) {
      final texto = codigo.rawValue;
      if (texto == null) continue;
      final datos = parsearQrObs(texto);
      if (datos != null) {
        _yaLeido = true;
        Navigator.pop(context, datos);
        return;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR de OBS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Linterna',
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _alDetectar),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              'Apunta a la ventana "Mostrar información de conexión" de OBS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
