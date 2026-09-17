import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tts_apliarte/app.dart';
import 'package:tts_apliarte/ui/widgets/command_buttons_card.dart';

// Paso 6 de la cadena directo/tts-apliarte: la entrada fija de shoutout de
// ApliArte debe estar siempre visible y no ser borrable por el usuario.
//
// CommandButtonsCard vive en un ListView largo: hay que hacer scroll hasta
// verlo, si no el sliver ni siquiera construye su Element (find.* no lo ve).

Future<void> _pumpHomeScrolledToCommandButtons(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(const TtsApliArteApp());
  await tester.pumpAndSettle();
  final comandosTab = find.text('Comandos');
  if (comandosTab.evaluate().isNotEmpty) {
    await tester.tap(comandosTab);
    await tester.pumpAndSettle();
  }
  await tester.scrollUntilVisible(
    find.byType(CommandButtonsCard),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el shoutout fijo de apliarte esta siempre presente', (tester) async {
    await _pumpHomeScrolledToCommandButtons(tester);

    expect(find.text('!so apliarte'), findsOneWidget);
  });

  testWidgets('el shoutout fijo no tiene icono de borrar (no se puede quitar)', (tester) async {
    await _pumpHomeScrolledToCommandButtons(tester);

    final chip = tester.widget<InputChip>(
      find.ancestor(of: find.text('!so apliarte'), matching: find.byType(InputChip)),
    );
    expect(chip.onDeleted, isNull);
  });

  testWidgets('sin canal de Javier por defecto en los comandos de canal (/raid)', (tester) async {
    await _pumpHomeScrolledToCommandButtons(tester);

    // Bug real corregido: la lista de canales traía 'erbolamm' hardcodeado,
    // justo el dato personal que el paso 5 quitó a propósito de la app.
    expect(find.text('/raid erbolamm'), findsNothing);
    expect(find.text('/raid apliarte'), findsNothing);
  });

  testWidgets('un canal agregado persiste de verdad (no solo en memoria del widget)', (tester) async {
    await _pumpHomeScrolledToCommandButtons(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Nombre del canal…'), 'otroStreamer');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar').first);
    await tester.pumpAndSettle();

    expect(find.text('/raid otroStreamer'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString('app_settings') ?? '';
    expect(guardado, contains('otroStreamer'));
  });
}
