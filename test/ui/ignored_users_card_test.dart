import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tts_apliarte/app.dart';
import 'package:tts_apliarte/controllers/app_controller.dart';
import 'package:tts_apliarte/controllers/settings_controller.dart';
import 'package:tts_apliarte/ui/settings/advanced_settings_screens.dart';
import 'package:tts_apliarte/ui/widgets/ignored_users_card.dart';

Widget _buildTestWrapper({
  required SettingsController settingsController,
  required AppController appController,
  required Widget child,
  bool wrapInScaffold = true,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsController>.value(value: settingsController),
      ChangeNotifierProvider<AppController>.value(value: appController),
    ],
    child: MaterialApp(
      home: wrapInScaffold ? Scaffold(body: SingleChildScrollView(child: child)) : child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IgnoredUsersCard widget tests', () {
    late SettingsController settingsController;
    late AppController appController;

    setUp(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
        if (call.method == 'getVoices') return <dynamic>[];
        return 1;
      });

      SharedPreferences.setMockInitialValues({});
      settingsController = SettingsController();
      await settingsController.load();
      appController = AppController(settingsController: settingsController);
      while (!appController.isInitialized) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });

    tearDown(() {
      appController.dispose();
      settingsController.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });

    testWidgets('muestra chips para usuarios silenciados por defecto', (tester) async {
      await tester.pumpWidget(
        _buildTestWrapper(
          settingsController: settingsController,
          appController: appController,
          child: const IgnoredUsersCard(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('streamelements'), findsOneWidget);
      expect(find.text('nightbot'), findsOneWidget);
      expect(find.text('streamlabs'), findsOneWidget);
      expect(find.byType(InputChip), findsWidgets);
    });

    testWidgets('anadir usuario crea un chip nuevo y persiste en SharedPreferences', (tester) async {
      await tester.pumpWidget(
        _buildTestWrapper(
          settingsController: settingsController,
          appController: appController,
          child: const IgnoredUsersCard(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('pesado_de_turno'), findsNothing);

      await tester.enterText(find.byType(TextField), 'pesado_de_turno');
      await tester.tap(find.widgetWithText(FilledButton, 'Añadir'));
      await tester.pumpAndSettle();

      expect(find.text('pesado_de_turno'), findsOneWidget);
      expect(appController.isUserIgnored('pesado_de_turno'), isTrue);

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('app_settings') ?? '';
      expect(stored, contains('pesado_de_turno'));
    });

    testWidgets('eliminar chip quita el usuario de la lista negra y persiste', (tester) async {
      await tester.pumpWidget(
        _buildTestWrapper(
          settingsController: settingsController,
          appController: appController,
          child: const IgnoredUsersCard(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('nightbot'), findsOneWidget);

      final nightbotChip = find.ancestor(
        of: find.text('nightbot'),
        matching: find.byType(InputChip),
      );

      final deleteIcon = find.descendant(
        of: nightbotChip,
        matching: find.byIcon(Icons.close),
      );

      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      expect(find.text('nightbot'), findsNothing);
      expect(appController.isUserIgnored('nightbot'), isFalse);

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('app_settings') ?? '';
      expect(stored, isNot(contains('"nightbot"')));
    });

    testWidgets('restablecer bots restaura la lista inicial', (tester) async {
      await tester.pumpWidget(
        _buildTestWrapper(
          settingsController: settingsController,
          appController: appController,
          child: const IgnoredUsersCard(),
        ),
      );
      await tester.pumpAndSettle();

      // Borrar streamelements
      final seChip = find.ancestor(
        of: find.text('streamelements'),
        matching: find.byType(InputChip),
      );
      await tester.tap(find.descendant(of: seChip, matching: find.byIcon(Icons.close)));
      await tester.pumpAndSettle();
      expect(find.text('streamelements'), findsNothing);

      // Pulsar restablecer
      await tester.tap(find.text('Restablecer bots por defecto'));
      await tester.pumpAndSettle();

      expect(find.text('streamelements'), findsOneWidget);
    });

    testWidgets('FiltersConfigScreen incluye IgnoredUsersCard', (tester) async {
      await tester.pumpWidget(
        _buildTestWrapper(
          settingsController: settingsController,
          appController: appController,
          child: const FiltersConfigScreen(),
          wrapInScaffold: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IgnoredUsersCard), findsOneWidget);
      expect(find.text('streamelements'), findsOneWidget);
    });

    testWidgets('HomeScreen en rail Comandos muestra IgnoredUsersCard', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const TtsApliArteApp());
      await tester.pumpAndSettle();

      final comandosTab = find.text('Comandos');
      if (comandosTab.evaluate().isNotEmpty) {
        await tester.tap(comandosTab);
        await tester.pumpAndSettle();
      }

      await tester.scrollUntilVisible(
        find.byType(IgnoredUsersCard),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(IgnoredUsersCard), findsOneWidget);
    });
  });
}
