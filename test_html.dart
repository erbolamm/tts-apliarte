// ignore_for_file: avoid_print
import 'package:tts_apliarte/services/html_templates.dart';
void main() {
  try {
    String html = buildMasterOverlayHtml({}, subTitle: "TEST TÍTULO", poweredBy: "APLIARTE");
    print("HTML generado exitosamente, longitud: ${html.length}");
    print("Muestra de HTML: \n${html.substring(100, 200)}");
  } catch (e) {
    print("ERROR GENERANDO HTML: $e");
  }
}
