import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'controllers/app_controller.dart';
import 'controllers/settings_controller.dart';
import 'ui/home_screen.dart';

class TtsApliArteApp extends StatelessWidget {
  const TtsApliArteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController()..load()),
        ChangeNotifierProxyProvider<SettingsController, AppController>(
          create: (context) => AppController(
            settingsController: context.read<SettingsController>(),
          ),
          update: (context, settings, controller) {
            controller ??= AppController(settingsController: settings);
            controller.attachSettings(settings);
            return controller;
          },
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          final baseTheme = ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF005FA9), // Azul ApliArte
              primary: const Color(0xFF005FA9),
              secondary: const Color(0xFF5ECEF5), // Acentos activos
              surface: const Color(0xFF303030), // Tarjetas ApliArte
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF1A1A1A), // Fondo carbón
            useMaterial3: true,
          );

          return MaterialApp(
            title: 'TTS ApliArte',
            debugShowCheckedModeBanner: false,
            theme: baseTheme.copyWith(
              scaffoldBackgroundColor: const Color(0xFF1A1A1A),
              textTheme: GoogleFonts.soraTextTheme(baseTheme.textTheme).apply(
                bodyColor: const Color(0xFFFDFDFD),
                displayColor: const Color(0xFFFDFDFD),
              ),
              cardTheme: const CardThemeData(
                color: Color(0xFF303030),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  side: BorderSide(color: Color(0x22FFFFFF)),
                ),
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF00467B), // Azul corporativo oscuro
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
              ),
              drawerTheme: const DrawerThemeData(
                backgroundColor: Color(0xFF1A1A1A),
              ),
            ),
            home: settings.isReady
                ? const HomeScreen()
                : const _LoadingScreen(),
          );
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}
