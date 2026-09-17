import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tts_apliarte/app.dart';

// Paso 9 de la cadena directo/tts-apliarte: sub-Drawer de Twitch dentro del
// Drawer general, con "Chat en vivo" (antes inalcanzable: ChatScreen no
// estaba enlazada desde ningún sitio) y un atajo a la botonera de comandos.

Future<void> _abrirDrawer(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(const TtsApliArteApp());
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el Drawer tiene un grupo "Twitch" con sus dos subpartes', (tester) async {
    await _abrirDrawer(tester);

    expect(find.text('Twitch'), findsOneWidget);
    await tester.tap(find.text('Twitch'));
    await tester.pumpAndSettle();

    expect(find.text('Chat en vivo'), findsOneWidget);
    expect(find.text('Comandos, usuarios y canales'), findsOneWidget);
  });

  testWidgets('"Chat en vivo" dispara la navegación hacia ChatScreen', (tester) async {
    // ChatScreen crea un WebViewController real en initState. Sin un
    // WebViewPlatform.instance registrado (no hay uno de pruebas en este
    // proyecto), Flutter lanza una excepción de plataforma al construirla —
    // limitación conocida de testear WebViews, no un fallo de la navegación.
    // Lo que sí se puede probar sin esa infraestructura es que el tap
    // realmente intenta empujar la ruta (llega a construir ChatScreen y
    // falla ahí, no antes ni por otro motivo).
    await _abrirDrawer(tester);
    await tester.tap(find.text('Twitch'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat en vivo'));
    await tester.pump();

    final excepcion = tester.takeException();
    expect(excepcion, isNotNull);
    expect(excepcion.toString(), contains('WebViewPlatform'));
  });

  testWidgets('"Comandos, usuarios y canales" cierra el Drawer sin lanzar', (tester) async {
    await _abrirDrawer(tester);
    await tester.tap(find.text('Twitch'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Comandos, usuarios y canales'));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
