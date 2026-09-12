import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pedir permisos de cámara y micro al arrancar.
  // Así OBS Ninja en el WebView no los vuelve a pedir.
  await [
    Permission.camera,
    Permission.microphone,
  ].request();

  runApp(const TtsApliArteApp());
}
