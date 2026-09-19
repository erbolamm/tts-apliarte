import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tts_apliarte/ui/widgets/screen_off_overlay.dart';

void main() {
  group('ScreenOffOverlay', () {
    testWidgets('renderiza contenedor negro y responde a doble toque para encender', (tester) async {
      var wakeUpCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Fondo app')),
                ScreenOffOverlay(
                  onWakeUp: () => wakeUpCalled = true,
                ),
              ],
            ),
          ),
        ),
      );

      // Debe encontrarse el widget
      expect(find.byType(ScreenOffOverlay), findsOneWidget);

      // Doble toque en el centro
      await tester.tap(find.byType(ScreenOffOverlay));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(ScreenOffOverlay));
      await tester.pumpAndSettle();

      expect(wakeUpCalled, isTrue);
    });

    testWidgets('un solo toque muestra la pista de desbloqueo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ScreenOffOverlay(
                  onWakeUp: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Al inicio la opacidad es 0
      final animatedOpacityFinder = find.byType(AnimatedOpacity);
      expect(animatedOpacityFinder, findsOneWidget);
      final initialOpacity = tester.widget<AnimatedOpacity>(animatedOpacityFinder).opacity;
      expect(initialOpacity, equals(0.0));

      // Hacemos un solo toque
      await tester.tap(find.byType(ScreenOffOverlay));
      // Damos 300 ms para que la animación de opacidad complete (200 ms) antes de que venza el timer de 2500 ms
      await tester.pump(const Duration(milliseconds: 300));

      // Tras el toque, la pista es visible (opacidad 1.0)
      final visibleOpacity = tester.widget<AnimatedOpacity>(animatedOpacityFinder).opacity;
      expect(visibleOpacity, equals(1.0));
      expect(find.text('Doble toque para encender'), findsOneWidget);

      // Esperar a que expire el temporizador de 2.5s y se oculte
      await tester.pump(const Duration(milliseconds: 2600));
      expect(tester.widget<AnimatedOpacity>(animatedOpacityFinder).opacity, equals(0.0));

      // Tras pasar los 2500 ms del timer + 200 ms de animación, la pista vuelve a ocultarse
      await tester.pump(const Duration(milliseconds: 2600));
      final hiddenOpacity = tester.widget<AnimatedOpacity>(animatedOpacityFinder).opacity;
      expect(hiddenOpacity, equals(0.0));
    });

    testWidgets('el botón "Encender pantalla" también activa onWakeUp', (tester) async {
      var wakeUpCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ScreenOffOverlay(
                  onWakeUp: () => wakeUpCalled = true,
                ),
              ],
            ),
          ),
        ),
      );

      // Hacemos tap para hacer visible la pista y el botón
      await tester.tap(find.byType(ScreenOffOverlay));
      await tester.pumpAndSettle();

      // Pulsamos el botón de texto
      final buttonFinder = find.widgetWithText(TextButton, 'Encender pantalla');
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(wakeUpCalled, isTrue);
    });
  });
}
