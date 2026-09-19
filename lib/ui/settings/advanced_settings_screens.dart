import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/app_settings.dart';
import '../../utils/app_strings.dart';
import '../../utils/obs_qr_parser.dart';
import '../widgets/ignored_users_card.dart';
import '../widgets/section_card.dart';
import '../widgets/settings_field.dart';
import 'obs_qr_scanner_screen.dart';

class _LanguageOption {
  const _LanguageOption(this.code, this.label);
  final String code;
  final String label;
}

const _languageOptions = [
  _LanguageOption('auto', 'Auto'),
  _LanguageOption('es', 'Español'),
  _LanguageOption('en', 'English'),
  _LanguageOption('pt', 'Português'),
  _LanguageOption('pt-BR', 'Português BR'),
  _LanguageOption('fr', 'Français'),
  _LanguageOption('de', 'Deutsch'),
  _LanguageOption('it', 'Italiano'),
  _LanguageOption('ja', 'Japanese'),
  _LanguageOption('ko', 'Korean'),
  _LanguageOption('zh', 'Chinese'),
  _LanguageOption('ru', 'Russian'),
  _LanguageOption('ar', 'Arabic'),
];

class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: _languageOptions
          .map(
            (option) =>
                DropdownMenuItem(value: option.code, child: Text(option.label)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class VoiceDropdown extends StatelessWidget {
  const VoiceDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.voices,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<VoiceOption> voices;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      const DropdownMenuItem(value: 'auto', child: Text('Auto')),
      ...voices.map(
        (voice) =>
            DropdownMenuItem(value: voice.storageKey, child: Text(voice.label)),
      ),
    ];

    return DropdownButtonFormField<String>(
      key: ValueKey(value.isEmpty ? 'auto' : value),
      initialValue: value.isEmpty ? 'auto' : value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: items,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

void _updateSettings(
  BuildContext context,
  AppSettings Function(AppSettings current) update,
) {
  context.read<SettingsController>().updateWith(update);
}

// ──────────────────────────────────────────────────────────────────────
// Pantalla de Traducción y Captura de Voz
// ──────────────────────────────────────────────────────────────────────
class TranslationConfigScreen extends StatelessWidget {
  const TranslationConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>().settings;
    final appController = context.watch<AppController>();
    final s = AppStrings(settings.uiLanguage);

    return Scaffold(
      appBar: AppBar(title: Text('🗣️ ${s.translationTitle} y Micro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: s.translationTitle,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: LanguageDropdown(
                    label: s.sourceLang,
                    value: settings.sourceLanguage,
                    onChanged: (value) => _updateSettings(
                      context,
                      (current) => current.copyWith(sourceLanguage: value),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: LanguageDropdown(
                    label: s.destLang,
                    value: settings.targetLanguage,
                    onChanged: (value) => _updateSettings(
                      context,
                      (current) => current.copyWith(targetLanguage: value),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SettingsSwitch(
                  label: s.autoTranslate,
                  value: settings.autoTranslateEnabled,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(autoTranslateEnabled: value),
                  ),
                ),
                SettingsSwitch(
                  label: s.sendTranslations,
                  value: settings.autoTranslateToChannel,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(autoTranslateToChannel: value),
                  ),
                ),
                SettingsSwitch(
                  label: s.skipIdentical,
                  value: settings.skipTranslationIfSame,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(skipTranslationIfSame: value),
                  ),
                ),
              ],
            ),
          ),
          
          SectionCard(
            title: s.micTitle,
            child: Column(
              children: [
                SettingsSwitch(
                  label: s.useSpeech,
                  value: settings.useSpeechToText,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(useSpeechToText: value),
                  ),
                ),
                SettingsSwitch(
                  label: s.pauseTts,
                  value: settings.pauseTtsWhenSpeaking,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(pauseTtsWhenSpeaking: value),
                  ),
                ),
                const SizedBox(height: 12),
                SettingsNumberField(
                  label: s.secondsAfterSpeech,
                  value: settings.pauseSecondsAfterSpeaking,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(
                      pauseSecondsAfterSpeaking: value.toInt(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SettingsTextField(
                  label: s.poofPatternLabel,
                  value: settings.poofPattern,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(poofPattern: value),
                  ),
                ),
                const SizedBox(height: 12),
                SettingsTextField(
                  label: s.banPatternLabel,
                  value: settings.banPattern,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(banPattern: value),
                  ),
                ),
                const SizedBox(height: 12),
                SettingsTextField(
                  label: s.banPhraseLabel,
                  value: settings.banConfirmationPhrase,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(banConfirmationPhrase: value),
                  ),
                ),
                SettingsSwitch(
                  label: s.sendDictation,
                  value: settings.sendDictationToChannel,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(sendDictationToChannel: value),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: appController.isSpeechListening
                          ? null
                          : () => appController.startSpeech(),
                      child: Text(s.startMic),
                    ),
                    OutlinedButton(
                      onPressed: appController.isSpeechListening
                          ? () => appController.stopSpeech()
                          : null,
                      child: Text(s.stopMic),
                    ),
                    TextButton(
                      onPressed: () => appController.stopTts(),
                      child: Text(s.stopTts),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Pantalla de Filtros y Moderación
// ──────────────────────────────────────────────────────────────────────
class FiltersConfigScreen extends StatelessWidget {
  const FiltersConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>().settings;
    final s = AppStrings(settings.uiLanguage);

    return Scaffold(
      appBar: AppBar(title: Text('🛡️ ${s.ttsFiltersTitle}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: s.ttsFiltersTitle,
            child: Column(
              children: [
                SettingsSwitch(
                  label: s.ttsEnabled,
                  value: settings.ttsEnabled,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(ttsEnabled: value),
                  ),
                ),
                SettingsSwitch(
                  label: s.deleteBang,
                  value: settings.deleteBangCommands,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(deleteBangCommands: value),
                  ),
                ),
                SettingsSwitch(
                  label: s.allowEveryone,
                  value: settings.allowEveryone,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(allowEveryone: value),
                  ),
                ),
                SettingsSwitch(
                  label: s.allowMods,
                  value: settings.allowMods,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(allowMods: value),
                  ),
                ),
                SettingsSwitch(
                  label: s.allowVips,
                  value: settings.allowVips,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(allowVips: value),
                  ),
                ),
                SettingsSwitch(
                  label: s.allowSubs,
                  value: settings.allowSubs,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(allowSubs: value),
                  ),
                ),
                SettingsSwitch(
                  label: s.replaceUsernames,
                  value: settings.replaceAtUsernames,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(replaceAtUsernames: value),
                  ),
                ),
                SettingsSwitch(
                  label: s.speakMentions,
                  value: settings.speakMentions,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(speakMentions: value),
                  ),
                ),
                SettingsSwitch(
                  label: s.speakEmotes,
                  value: settings.speakEmotes,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(speakEmotes: value),
                  ),
                ),
                SettingsSwitch(
                  label: s.dedupEmotes,
                  value: settings.dedupEmotes,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(dedupEmotes: value),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SettingsNumberField(
                        label: s.userSimilarity,
                        value: settings.userSimilarityPercent,
                        onChanged: (value) => _updateSettings(
                          context,
                          (current) => current.copyWith(
                            userSimilarityPercent: value.toDouble(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SettingsNumberField(
                        label: s.userSimilarityTime,
                        value: settings.userSimilarityWindowSeconds,
                        onChanged: (value) => _updateSettings(
                          context,
                          (current) => current.copyWith(
                            userSimilarityWindowSeconds: value.toInt(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SettingsNumberField(
                        label: s.globalSimilarity,
                        value: settings.globalSimilarityPercent,
                        onChanged: (value) => _updateSettings(
                          context,
                          (current) => current.copyWith(
                            globalSimilarityPercent: value.toDouble(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SettingsNumberField(
                        label: s.globalSimilarityTime,
                        value: settings.globalSimilarityWindowSeconds,
                        onChanged: (value) => _updateSettings(
                          context,
                          (current) => current.copyWith(
                            globalSimilarityWindowSeconds: value.toInt(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const IgnoredUsersCard(),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Pantalla de Voces de Sistema
// ──────────────────────────────────────────────────────────────────────
class SystemVoicesConfigScreen extends StatefulWidget {
  const SystemVoicesConfigScreen({super.key});

  @override
  State<SystemVoicesConfigScreen> createState() => _SystemVoicesConfigScreenState();
}

class _SystemVoicesConfigScreenState extends State<SystemVoicesConfigScreen> {
  final _testController = TextEditingController();

  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>().settings;
    final appController = context.watch<AppController>();
    final s = AppStrings(settings.uiLanguage);

    return Scaffold(
      appBar: AppBar(title: Text('🎤 ${s.ttsEngineTitle}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: s.ttsEngineTitle,
            child: Column(
              children: [
                LanguageDropdown(
                  label: s.systemLang,
                  value: settings.systemLanguage,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(systemLanguage: value),
                  ),
                ),
                const SizedBox(height: 12),
                VoiceDropdown(
                  label: s.systemVoice,
                  value: settings.systemVoice,
                  voices: appController.voices,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(systemVoice: value),
                  ),
                ),
              ],
            ),
          ),
          
          SectionCard(
            title: s.testTitle,
            child: Column(
              children: [
                TextField(
                  controller: _testController,
                  decoration: InputDecoration(
                    labelText: s.testPlaceholder,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () =>
                          appController.speakTest(_testController.text),
                      child: Text(s.speakTestBtn),
                    ),
                    OutlinedButton(
                      onPressed: () => appController.stopTts(),
                      child: Text(s.stopTts),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Configura la URL del servidor propio de escenas (paso 4/5 de la cadena
/// directo/tts-apliarte). Sin valor por defecto: la app publicada no debe
/// apuntar a la infraestructura de Javier.
class ScenesServerConfigScreen extends StatelessWidget {
  const ScenesServerConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>().settings;
    final s = AppStrings(settings.uiLanguage);

    return Scaffold(
      appBar: AppBar(title: Text('🎬 ${s.scenesServerTitle}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: s.scenesServerTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsTextField(
                  label: s.scenesServerUrlLabel,
                  hint: s.scenesServerUrlHint,
                  value: settings.scenesServerBaseUrl,
                  keyboardType: TextInputType.url,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(scenesServerBaseUrl: value),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.scenesServerHelp,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Conexión al WebSocket nativo de OBS Studio (obs-websocket v5, puerto 4455
/// por defecto). Distinto del "Servidor de escenas" de arriba. Sin valor por
/// defecto: la app publicada no debe apuntar a la infraestructura de nadie.
class ObsConnectionConfigScreen extends StatelessWidget {
  const ObsConnectionConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>().settings;
    final s = AppStrings(settings.uiLanguage);

    return Scaffold(
      appBar: AppBar(title: Text('🔌 ${s.obsWebSocketTitle}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: s.obsWebSocketTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Escanear QR de OBS'),
                  onPressed: () async {
                    final datos = await Navigator.push<ObsQrDatos>(
                      context,
                      MaterialPageRoute(builder: (_) => const ObsQrScannerScreen()),
                    );
                    if (datos == null || !context.mounted) return;
                    _updateSettings(
                      context,
                      (current) => current.copyWith(
                        obsWebSocketHost: datos.host,
                        obsWebSocketPort: datos.port,
                        obsWebSocketPassword: datos.password,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SettingsTextField(
                  label: s.obsWebSocketHostLabel,
                  hint: s.obsWebSocketHostHint,
                  value: settings.obsWebSocketHost,
                  keyboardType: TextInputType.url,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(obsWebSocketHost: value.trim()),
                  ),
                ),
                const SizedBox(height: 8),
                SettingsNumberField(
                  label: s.obsWebSocketPortLabel,
                  value: settings.obsWebSocketPort,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(obsWebSocketPort: value.toInt()),
                  ),
                ),
                const SizedBox(height: 8),
                SettingsTextField(
                  label: s.obsWebSocketPasswordLabel,
                  value: settings.obsWebSocketPassword,
                  obscureText: true,
                  onChanged: (value) => _updateSettings(
                    context,
                    (current) => current.copyWith(obsWebSocketPassword: value),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.obsWebSocketHelp,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
