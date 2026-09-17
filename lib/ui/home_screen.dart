import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/app_settings.dart';
import '../models/log_entry.dart';
import '../utils/app_strings.dart';
import 'settings/advanced_settings_screens.dart';
import 'widgets/apliarte_drawer.dart';
import 'widgets/command_buttons_card.dart';
import 'widgets/obs_scenes_card.dart';
import 'widgets/section_card.dart';
import 'widgets/settings_field.dart';
import 'widgets/status_pill.dart';
import 'widgets/stream_deck_card.dart';
import 'widgets/support_banner_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final ValueNotifier<int> railIndexNotifier = ValueNotifier<int>(0);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _testController = TextEditingController();
  int _selectedRailIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedRailIndex = HomeScreen.railIndexNotifier.value;
    HomeScreen.railIndexNotifier.addListener(_onRailIndexChanged);
  }

  void _onRailIndexChanged() {
    if (mounted && _selectedRailIndex != HomeScreen.railIndexNotifier.value) {
      setState(() {
        _selectedRailIndex = HomeScreen.railIndexNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    HomeScreen.railIndexNotifier.removeListener(_onRailIndexChanged);
    _testController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    final appController = context.watch<AppController>();
    final settings = settingsController.settings;
    final s = AppStrings(settings.uiLanguage);

    return Scaffold(
      drawer: const ApliArteDrawer(),
      appBar: AppBar(
        title: const Text('TTS ApliArte'),
        actions: [
          StatusPill(
            label: appController.isConnected
                ? AppStrings(settings.uiLanguage).twitchOnline
                : AppStrings(settings.uiLanguage).twitchOffline,
            isActive: appController.isConnected,
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Restablecer opciones',
            child: IconButton(
              icon: const Icon(Icons.settings_backup_restore),
              onPressed: () {
                context.read<SettingsController>().resetToDefaults();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Configuración restablecida por defecto (Traducción a Español)',
                    ),
                  ),
                );
              },
            ),
          ),
          Tooltip(
            message: AppStrings(settings.uiLanguage).langToggleTooltip,
            child: TextButton(
              onPressed: () => _updateSettings(
                context,
                (s) => s.copyWith(
                  uiLanguage: settings.uiLanguage == 'es' ? 'en' : 'es',
                ),
              ),
              child: Text(
                AppStrings(settings.uiLanguage).langCode,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 1200;
          final logs = _buildLogs(appController, settings.uiLanguage);

          // Vista activa del rail:
          // 0: 🎬 Escenas (OBS WebSocket + Stream Deck)
          // 1: 🎙️ Micrófono / Dictado
          // 2: 🌐 URL OBS (Browser Source)
          // 3: ⚡ Comandos (CommandButtonsCard)
          Widget activeContent;
          switch (_selectedRailIndex) {
            case 0:
              activeContent = Column(
                children: [
                  ObsScenesCard(appController: appController),
                  const SizedBox(height: 16),
                  const StreamDeckCard(),
                ],
              );
              break;
            case 1:
              activeContent = _DictationCard(
                appController: appController,
                settings: settings,
                s: s,
                onUpdateSettings: (update) =>
                    _updateSettings(context, update),
              );
              break;
            case 2:
              activeContent = _ObsBrowserSourceCard(
                appController: appController,
              );
              break;
            case 3:
            default:
              activeContent = const CommandButtonsCard();
              break;
          }

          return Row(
            children: [
              // ── Rail lateral de navegación ──────────────────────────────
              NavigationRail(
                selectedIndex: _selectedRailIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedRailIndex = index);
                  HomeScreen.railIndexNotifier.value = index;
                },
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.movie_outlined),
                    selectedIcon: Icon(Icons.movie),
                    label: Text('Escenas'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.mic_none),
                    selectedIcon: Icon(Icons.mic),
                    label: Text('Dictado'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.language_outlined),
                    selectedIcon: Icon(Icons.language),
                    label: Text('URL OBS'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.bolt_outlined),
                    selectedIcon: Icon(Icons.bolt),
                    label: Text('Comandos'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),

              // ── Contenido central ───────────────────────────────────────
              Expanded(
                flex: 3,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Conexión y apoyo: fijos siempre visibles arriba ──
                    _ConnectionCard(
                      appController: appController,
                      settings: settings,
                      s: s,
                      onUpdateSettings: (update) =>
                          _updateSettings(context, update),
                    ),
                    const SizedBox(height: 12),
                    const SupportBannerCard(),
                    const SizedBox(height: 16),

                    // ── Vista activa del rail ────────────────────────────
                    activeContent,

                    // ── Accesos directos a configuración ─────────────────
                    const SizedBox(height: 24),
                    _buildNavButtons(context),

                    if (!isWide) ...[
                      const SizedBox(height: 16),
                      logs,
                    ],
                  ],
                ),
              ),

              if (isWide) ...[
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 16,
                      bottom: 16,
                      right: 16,
                    ),
                    child: logs,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildNavButton(
            context,
            icon: Icons.record_voice_over,
            color: const Color(0xFF5ECEF5), // Cian activo ApliArte
            title: 'Traducción y TTS',
            subtitle: 'Ajustes automáticos e idiomas',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TranslationConfigScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildNavButton(
            context,
            icon: Icons.shield,
            color: const Color(0xFF005FA9), // Azul primario ApliArte
            title: 'Filtros y Moderación',
            subtitle: 'Antispam, similitud y baneos',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FiltersConfigScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildNavButton(
            context,
            icon: Icons.multitrack_audio,
            color: const Color(0xFF5ECEF5), // Cian activo ApliArte
            title: 'Voces de Sistema',
            subtitle: 'Configurar y probar voces TTS',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SystemVoicesConfigScreen()),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLogs(AppController appController, String lang) {
    final s = AppStrings(lang);
    final logs = appController.logs.reversed.toList();
    return SectionCard(
      title: s.logsTitle,
      initiallyExpanded: false,
      child: SizedBox(
        height: 480,
        child: logs.isEmpty
            ? Center(child: Text(s.logsEmpty))
            : ListView.separated(
                itemCount: logs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final color = _levelColor(log.level);
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.bolt, color: color),
                    title: Text(log.message),
                    subtitle: Text(
                      log.timestamp.toIso8601String(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Color _levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return const Color(0xFF1B998B);
      case LogLevel.warning:
        return const Color(0xFFF4A261);
      case LogLevel.error:
        return const Color(0xFFE63946);
    }
  }

  void _updateSettings(
    BuildContext context,
    AppSettings Function(AppSettings current) update,
  ) {
    context.read<SettingsController>().updateWith(update);
  }
}

// ─── Vista de Micrófono y Dictado por Voz ─────────────────────────────────

class _DictationCard extends StatelessWidget {
  const _DictationCard({
    required this.appController,
    required this.settings,
    required this.s,
    required this.onUpdateSettings,
  });

  final AppController appController;
  final AppSettings settings;
  final AppStrings s;
  final void Function(AppSettings Function(AppSettings)) onUpdateSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isListening = appController.isSpeechListening;

    return SectionCard(
      title: '🎙️ Micrófono y Dictado por Voz',
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isListening
                      ? Colors.redAccent.withValues(alpha: 0.2)
                      : Colors.blueAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: isListening ? Colors.redAccent : Colors.blueAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isListening
                          ? 'Escuchando voz en directo…'
                          : 'Micrófono en reposo',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isListening ? Colors.redAccent : null,
                      ),
                    ),
                    Text(
                      settings.useSpeechToText
                          ? (settings.sendDictationToChannel
                              ? 'El dictado se enviará al chat de Twitch'
                              : 'Reconocimiento activo para traducción/TTS local')
                          : 'Reconocimiento desactivado en opciones',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: isListening
                      ? Colors.redAccent
                      : const Color(0xFF005FA9),
                ),
                onPressed: () {
                  if (isListening) {
                    appController.stopSpeech();
                  } else {
                    appController.startSpeech();
                  }
                },
                icon: Icon(isListening ? Icons.stop : Icons.mic),
                label: Text(isListening ? 'Detener' : 'Escuchar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          SwitchListTile(
            title: Text(s.useSpeech),
            subtitle:
                const Text('Activa el motor de reconocimiento por voz'),
            value: settings.useSpeechToText,
            onChanged: (value) => onUpdateSettings(
              (current) => current.copyWith(useSpeechToText: value),
            ),
          ),
          SwitchListTile(
            title: Text(s.sendDictation),
            subtitle: const Text(
                'Envía las frases reconocidas directamente al chat'),
            value: settings.sendDictationToChannel,
            onChanged: settings.useSpeechToText
                ? (value) => onUpdateSettings(
                      (current) =>
                          current.copyWith(sendDictationToChannel: value),
                    )
                : null,
          ),
        ],
      ),
    );
  }
}

// ─── Vista de URL para OBS (Browser Source) ───────────────────────────────

class _ObsBrowserSourceCard extends StatelessWidget {
  const _ObsBrowserSourceCard({
    required this.appController,
  });

  final AppController appController;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '🌐 URL para OBS (Browser Source) 1920x1080',
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Añade una fuente de tipo "Navegador" en OBS Studio con resolución 1920x1080 y pega la siguiente URL:',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: SelectableText(
              appController.overlayUrl,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar enlace Overlay'),
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: appController.overlayUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'URL de overlay copiada al portapapeles.')),
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.settings_remote, size: 18),
                label: const Text('Copiar Control Móvil'),
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: appController.controlUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('URL de control móvil copiada.')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de conexión inteligente (3 estados) ──────────────────────────

class _ConnectionCard extends StatefulWidget {
  const _ConnectionCard({
    required this.appController,
    required this.settings,
    required this.s,
    required this.onUpdateSettings,
  });

  final AppController appController;
  final AppSettings settings;
  final AppStrings s;
  final void Function(AppSettings Function(AppSettings)) onUpdateSettings;

  @override
  State<_ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<_ConnectionCard> {
  bool _showManual = false;

  AppController get _ctrl => widget.appController;
  AppSettings get _settings => widget.settings;
  AppStrings get _s => widget.s;

  bool get _hasToken => _settings.twitchOauthToken.trim().isNotEmpty;
  bool get _isConnected => _ctrl.isConnected;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final IconData statusIcon;
    final String statusText;

    if (_isConnected) {
      borderColor = Colors.green.shade300;
      statusIcon = Icons.check_circle;
      statusText =
          '${_s.connectedToChannel} #${_settings.twitchChannel.isNotEmpty ? _settings.twitchChannel : _settings.twitchUsername}';
    } else if (_hasToken) {
      borderColor = Colors.amber.shade300;
      statusIcon = Icons.link_off;
      statusText = _s.sessionActive;
    } else {
      borderColor = Colors.red.shade200;
      statusIcon = Icons.cloud_off;
      statusText = _s.notConnected;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cabecera con estado ──
            Row(
              children: [
                Icon(
                  statusIcon,
                  color: _isConnected
                      ? Colors.green.shade700
                      : _hasToken
                      ? Colors.amber.shade800
                      : Colors.red.shade400,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    statusText,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isConnected
                          ? Colors.green.shade900
                          : _hasToken
                          ? Colors.amber.shade900
                          : Colors.red.shade700,
                    ),
                  ),
                ),
                if (_isConnected)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.link_off, size: 16),
                    label: Text(_s.disconnectBtn),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                    onPressed: () => _ctrl.disconnect(),
                  ),
              ],
            ),

            // ── Estado 1: Sin token → Login ──
            if (!_hasToken && !_isConnected) ...[
              const SizedBox(height: 12),
              Text(
                _s.connStep1,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color(0xFF9146FF), // Twitch purple
                ),
                onPressed: _ctrl.isAuthLoading
                    ? null
                    : () => _ctrl.loginWithTwitch(),
                icon: _ctrl.isAuthLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login, size: 20),
                label: Text(_s.loginTwitchBtn),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _showManual = !_showManual),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showManual ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(_s.manualConfig),
                  ],
                ),
              ),
              if (_showManual) _buildManualFields(),
            ],

            // ── Estado 2: Con token, sin conectar → Conectar ──
            if (_hasToken && !_isConnected) ...[
              const SizedBox(height: 12),
              Text(
                _s.connStep2,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              SettingsTextField(
                label: _s.channelLabel,
                value: _settings.twitchChannel,
                onChanged: (value) => widget.onUpdateSettings(
                  (current) => current.copyWith(twitchChannel: value.trim()),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () => _ctrl.connect(),
                icon: const Icon(Icons.power, size: 20),
                label: Text(_s.connectToChat),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: TextButton.icon(
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: Text(
                        _s.changeAccount,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: _ctrl.isAuthLoading
                          ? null
                          : () => _ctrl.loginWithTwitch(),
                    ),
                  ),
                  Flexible(
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _showManual = !_showManual),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showManual ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _s.manualConfig,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_showManual) _buildManualFields(),
            ],

            // ── Estado 3: Conectado → solo cabecera verde (ya se muestra arriba)  ──
          ],
        ),
      ),
    );
  }

  Widget _buildManualFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          SettingsTextField(
            label: _s.usernameLabel,
            value: _settings.twitchUsername,
            onChanged: (value) => widget.onUpdateSettings(
              (current) => current.copyWith(twitchUsername: value.trim()),
            ),
          ),
          const SizedBox(height: 10),
          SettingsTextField(
            label: _s.oauthToken,
            value: _settings.twitchOauthToken,
            obscureText: true,
            onChanged: (value) => widget.onUpdateSettings(
              (current) => current.copyWith(twitchOauthToken: value.trim()),
            ),
          ),
          const SizedBox(height: 10),
          SettingsTextField(
            label: _s.channelLabel,
            value: _settings.twitchChannel,
            onChanged: (value) => widget.onUpdateSettings(
              (current) => current.copyWith(twitchChannel: value.trim()),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Panel de control del directo ─────────────────────────────────────────
