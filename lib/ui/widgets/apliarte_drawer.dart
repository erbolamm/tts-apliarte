import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../utils/app_strings.dart';
import '../chat_screen.dart';
import '../home_screen.dart';
import '../settings/advanced_settings_screens.dart';
import 'command_buttons_card.dart';
import 'ignored_users_card.dart';

/// Drawer canónico para el ecosistema ApliArte.
///
/// Agrupa la navegación en 3 bloques limpios (Directo, Ajustes y OBS/Capas),
/// liberando la pantalla principal para la operación en vivo y respetando
/// los colores de marca de ApliArte.
class ApliArteDrawer extends StatelessWidget {
  const ApliArteDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    final appController = context.watch<AppController>();
    final settings = settingsController.settings;
    final s = AppStrings(settings.uiLanguage);
    final theme = Theme.of(context);

    // Colores oficiales Kit de Marca ApliArte
    const cDarkBlue = Color(0xFF00467B);
    const cPrimaryBlue = Color(0xFF005FA9);
    const cActiveCyan = Color(0xFF5ECEF5);

    return Drawer(
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Cabecera de Marca ApliArte ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [cDarkBlue, cPrimaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.record_voice_over_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TTS ApliArte',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Studio Twitch Edition',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Estado y canal Twitch
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: appController.isConnected
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE53935),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        appController.isConnected
                            ? s.twitchOnline
                            : s.twitchOffline,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (settings.twitchChannel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '#${settings.twitchChannel}',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cActiveCyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Lista de Opciones ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Sección Directo
                  _buildSectionHeader('EN DIRECTO', theme),
                  ListTile(
                    leading: const Icon(Icons.dashboard_rounded, color: cActiveCyan),
                    title: const Text('Consola Principal'),
                    selected: true,
                    selectedColor: cActiveCyan,
                    onTap: () => Navigator.pop(context),
                  ),

                  // Sub-Drawer de Twitch (paso 9): agrupa las subpartes que ya
                  // existen tras los pasos 5-8. «Comandos, usuarios y
                  // canales» no es una pantalla aparte — vive en la Consola
                  // Principal, así que aquí solo cierra el Drawer y desplaza
                  // hasta esa tarjeta.
                  ExpansionTile(
                    leading: const Icon(Icons.live_tv_rounded, color: cActiveCyan),
                    title: const Text('Twitch'),
                    childrenPadding: const EdgeInsets.only(left: 8),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.chat_bubble_rounded, color: Colors.white70),
                        title: const Text('Chat en vivo'),
                        subtitle: const Text(
                          'Popout embebido de Twitch',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChatScreen()),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.forum_rounded, color: Colors.white70),
                        title: const Text('Comandos, usuarios y canales'),
                        subtitle: const Text(
                          'Botonera de la Consola Principal',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          HomeScreen.railIndexNotifier.value = 3;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final ctx = comandosUsuariosCanalesKey.currentContext;
                            if (ctx != null) {
                              Scrollable.ensureVisible(
                                ctx,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            }
                          });
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.volume_off_rounded, color: Colors.white70),
                        title: const Text('Usuarios silenciados'),
                        subtitle: const Text(
                          'Muteo de bots y usuarios en TTS',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          HomeScreen.railIndexNotifier.value = 3;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final ctx = ignoredUsersCardKey.currentContext;
                            if (ctx != null) {
                              Scrollable.ensureVisible(
                                ctx,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            }
                          });
                        },
                      ),
                    ],
                  ),

                  const Divider(height: 16),

                  // Sección Ajustes
                  _buildSectionHeader('CONFIGURACIÓN', theme),
                  ListTile(
                    leading: const Icon(Icons.translate_rounded, color: Colors.white70),
                    title: const Text('Traducción y TTS'),
                    subtitle: const Text(
                      'Idiomas y síntesis de voz',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TranslationConfigScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.security_rounded, color: Colors.white70),
                    title: const Text('Filtros y Moderación'),
                    subtitle: const Text(
                      'Antispam, similitud y baneos',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FiltersConfigScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.multitrack_audio_rounded, color: Colors.white70),
                    title: const Text('Voces de Sistema'),
                    subtitle: const Text(
                      'Probar y configurar motores TTS',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SystemVoicesConfigScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.dvr_rounded, color: Colors.white70),
                    title: const Text('Servidor de escenas'),
                    subtitle: const Text(
                      'Conecta tu propio servidor local',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScenesServerConfigScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.cable_rounded,
                      color: appController.obsConectado ? const Color(0xFF4CAF50) : Colors.white70,
                    ),
                    title: const Text('Conexión con OBS'),
                    subtitle: Text(
                      appController.obsConectado ? 'Conectado' : 'Sin conectar',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ObsConnectionConfigScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 16),

                  // Sección OBS y Overlays
                  _buildSectionHeader('OBS Y CONTROL REMOTO', theme),
                  ListTile(
                    leading: const Icon(Icons.video_library_rounded, color: Colors.white70),
                    title: const Text('Copiar Overlay OBS'),
                    subtitle: const Text(
                      'Pega esta URL como Navegador en OBS',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.copy_rounded, size: 18),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: appController.overlayUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL de Overlay OBS copiada al portapapeles.'),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.phonelink_ring_rounded, color: Colors.white70),
                    title: const Text('Copiar Control Móvil'),
                    subtitle: const Text(
                      'Abre en el móvil para manejar el directo',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.copy_rounded, size: 18),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: appController.controlUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL de Control Móvil copiada al portapapeles.'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 16),

                  // Sección Apoyo y Sponsors
                  _buildSectionHeader('APOYO Y SPONSORS', theme),
                  ListTile(
                    leading: const Icon(Icons.coffee_rounded, color: Color(0xFFFF5E5B)),
                    title: const Text('Invítame a un café (Ko-fi)'),
                    subtitle: const Text(
                      'ko-fi.com/C0C11TWR1K',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 16),
                    onTap: () => launchUrl(
                      Uri.parse('https://ko-fi.com/C0C11TWR1K'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.payment_rounded, color: Color(0xFF5ECEF5)),
                    title: const Text('Donar con PayPal'),
                    subtitle: const Text(
                      'paypal.me/erbolamm',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 16),
                    onTap: () => launchUrl(
                      Uri.parse('https://paypal.me/erbolamm'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.live_tv_rounded, color: Color(0xFFB388FF)),
                    title: const Text('Twitch Tip / Canal'),
                    subtitle: const Text(
                      'streamelements.com/apliarte/tip',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 16),
                    onTap: () => launchUrl(
                      Uri.parse('https://streamelements.com/apliarte/tip'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF8B98A5)),
                    title: const Text('GitHub Sponsors'),
                    subtitle: const Text(
                      'github.com/sponsors/erbolamm',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 16),
                    onTap: () => launchUrl(
                      Uri.parse('https://github.com/sponsors/erbolamm'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
            ),

            // ── Pie del Drawer ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
              ),
              child: Row(
                children: [
                  const Text(
                    'v1.0.0',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    '© 2026 ApliArte',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cActiveCyan.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: const Color(0xFF5ECEF5),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
