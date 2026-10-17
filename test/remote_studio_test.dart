import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tts_apliarte/controllers/remote_studio_controller.dart';
import 'package:tts_apliarte/models/community_models.dart';
import 'package:tts_apliarte/models/twitch_message.dart';
import 'package:tts_apliarte/services/community_repository.dart';
import 'package:tts_apliarte/ui/widgets/community_crm_card.dart';
import 'package:tts_apliarte/ui/widgets/sms_inbox_card.dart';
import 'package:tts_apliarte/ui/widgets/stream_context_card.dart';

TwitchChatMessage _fakeMessage({
  required String id,
  required String username,
  required String text,
  bool isVip = false,
  bool isMod = false,
  bool isSub = false,
}) {
  return TwitchChatMessage(
    id: id,
    channel: 'apliarte',
    username: username,
    displayName: username,
    message: text,
    timestamp: DateTime(2026, 10, 17, 12, 0),
    tags: const {},
    badges: '',
    isMod: isMod,
    isVip: isVip,
    isSub: isSub,
    isBroadcaster: false,
    emotes: '',
  );
}

void main() {
  group('Argon M2-B · Normalización bidireccional de IDs', () {
    test('buildId y normalizeRawId convierten twitch:user y twitch_user a twitch_user', () {
      expect(CommunityUser.buildId('Twitch', ' @ApliArte '), 'twitch_apliarte');
      expect(CommunityUser.normalizeRawId('twitch:apliarte'), 'twitch_apliarte');
      expect(CommunityUser.normalizeRawId('TWITCH_ApliArte'), 'twitch_apliarte');
      expect(CommunityUser.normalizeRawId('youtube:ErBolamm'), 'youtube_erbolamm');
      expect(CommunityUser.normalizeRawId('erbolamm'), 'twitch_erbolamm');
    });
  });

  group('Argon M2-A · Invariante de control de costes en Firestore', () {
    test('Ingestar 20 mensajes en vivo hace 0 escrituras en Firestore; acciones manuales hacen 1 escritura', () async {
      final repo = CommunityRepository(channelId: 'apliarte');
      final studio = RemoteStudioController(repository: repo);

      expect(repo.writeCount, 0);

      for (var i = 1; i <= 20; i++) {
        studio.ingestLiveChatMessage(
          _fakeMessage(
            id: 'msg_$i',
            username: 'espectador1',
            text: 'Mensaje de prueba número $i',
            isSub: true,
          ),
        );
      }

      // 0 escrituras inmediatas a Firestore tras 20 mensajes de chat
      expect(repo.writeCount, 0);

      final user = studio.getUser('twitch', 'espectador1');
      expect(user, isNotNull);
      expect(user!.totalMensajes, 20);
      expect(user.esSuscriptor, isTrue);

      final history = studio.getMessagesForUser(user.id);
      expect(history.length, 20);
      expect(history.first.texto, 'Mensaje de prueba número 20');

      // Guardar ficha manualmente -> exactamente 1 escritura
      await studio.saveUserFicha(
        user.copyWith(notasContexto: 'Espectador veterano de Flutter'),
      );
      expect(repo.writeCount, 1);

      // Proyectar un mensaje manualmente en OBS -> exactamente 1 escritura adicional
      await studio.toggleProjectedMessage(history.first);
      expect(repo.writeCount, 2);
      expect(studio.isMessageProjected(history.first), isTrue);
    });

    test('Extracción en memoria de comandos !sms y !contexto desde el chat en vivo', () {
      final repo = CommunityRepository(channelId: 'apliarte');
      final studio = RemoteStudioController(repository: repo);

      studio.ingestLiveChatMessage(
        _fakeMessage(
          id: 'sms_1',
          username: 'javier',
          text: '!sms ¿Podrías revisar mi PR cuando puedas?',
        ),
      );

      expect(studio.smsInbox.length, 1);
      expect(studio.smsInbox.first.usuario, 'javier');
      expect(
        studio.smsInbox.first.texto,
        '¿Podrías revisar mi PR cuando puedas?',
      );
      expect(repo.writeCount, 0);

      studio.ingestLiveChatMessage(
        _fakeMessage(
          id: 'ctx_1',
          username: 'apliarte',
          text: '!contexto Refactorizando el motor TTS en vivo',
        ),
      );

      expect(
        studio.studioState.streamContext,
        'Refactorizando el motor TTS en vivo',
      );
      expect(repo.writeCount, 0);
    });
  });

  group('Catálogo de Voces TTS (TtsVoiceCatalog)', () {
    test('Incluye categorías normal, animal, comica, efecto y acento y aplica prefijos animales', () {
      final categories =
          TtsVoiceCatalog.presets.map((p) => p.category).toSet();
      expect(
        categories,
        containsAll(['normal', 'animal', 'comica', 'efecto', 'acento']),
      );

      final p1 = TtsVoiceCatalog.assignAutomaticPreset('usuario_test');
      final p2 = TtsVoiceCatalog.assignAutomaticPreset('USUARIO_TEST');
      expect(p1.id, p2.id);

      final gatoConfig = TtsVoiceCatalog.byId('gato').toConfig();
      final transformed = TtsVoiceCatalog.applyPresetToText('Hola chat', gatoConfig);
      expect(transformed, 'Miau, Hola chat, miau.');
    });
  });

  group('Widgets nativos del Estudio Remoto', () {
    testWidgets('Renderiza CommunityCrmCard, StreamContextCard y SmsInboxCard', (tester) async {
      final studio = RemoteStudioController();
      studio.ingestLiveChatMessage(
        _fakeMessage(
          id: 'm1',
          username: 'viewer_vip',
          text: '!sms Hola desde los tests de widgets',
          isVip: true,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<RemoteStudioController>.value(
          value: studio,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    CommunityCrmCard(),
                    StreamContextCard(),
                    SmsInboxCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Comunidad CRM'), findsOneWidget);
      expect(find.textContaining('Contexto del Directo'), findsOneWidget);
      expect(find.textContaining('Buzón !sms'), findsOneWidget);
      expect(find.text('Hola desde los tests de widgets'), findsOneWidget);
    });
  });
}
