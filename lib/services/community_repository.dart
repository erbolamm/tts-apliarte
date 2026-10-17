import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/community_models.dart';
import 'firebase_init_service.dart';

/// Repositorio de persistencia para el CRM de Comunidad y el Estudio Remoto.
///
/// Sigue la estructura de documentos definida en `firestore.rules`:
/// - `channels/{channelId}/usuarios/{userId}`
/// - `channels/{channelId}/usuarios/{userId}/mensajes/{msgId}`
/// - `channels/{channelId}/sms/{smsId}`
/// - `channels/{channelId}/runtime/studio_state`
///
/// Si [FirebaseInitService.isAvailable] es `false` (o en entornos de test sin
/// Firebase), opera de forma segura en memoria sin lanzar excepciones y
/// contabiliza las escrituras solicitadas en [writeCount] para auditoría de
/// costes (Argon Adjustment M2-A).
class CommunityRepository {
  CommunityRepository({
    String channelId = 'apliarte',
    FirebaseFirestore? firestore,
  })  : _channelId = _normalizeChannel(channelId),
        _customFirestore = firestore;

  String _channelId;
  final FirebaseFirestore? _customFirestore;

  int _writeCount = 0;

  /// Número total de escrituras de repositorio ejecutadas en la sesión actual.
  int get writeCount => _writeCount;

  void resetWriteCount() {
    _writeCount = 0;
  }

  String get channelId => _channelId;

  void setChannelId(String channelId) {
    final normalized = _normalizeChannel(channelId);
    if (normalized.isNotEmpty) {
      _channelId = normalized;
    }
  }

  static String _normalizeChannel(String raw) {
    var clean = raw.trim().toLowerCase();
    while (clean.startsWith('#') || clean.startsWith('@')) {
      clean = clean.substring(1).trim();
    }
    return clean.isEmpty ? 'apliarte' : clean;
  }

  FirebaseFirestore? get _db {
    if (_customFirestore != null) return _customFirestore;
    if (!FirebaseInitService.isAvailable) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  DocumentReference<Map<String, dynamic>>? get _channelDoc {
    final db = _db;
    if (db == null) return null;
    return db.collection('channels').doc(_channelId);
  }

  Future<List<CommunityUser>> fetchUsers() async {
    final doc = _channelDoc;
    if (doc == null) return const [];
    try {
      final snap = await doc
          .collection('usuarios')
          .orderBy('ultimoMensajeEn', descending: true)
          .limit(200)
          .get();
      return snap.docs
          .map((d) => CommunityUser.fromMap(d.data(), docId: d.id))
          .toList();
    } catch (e) {
      debugPrint('CommunityRepository.fetchUsers fallback: $e');
      return const [];
    }
  }

  Future<List<CommunityMessage>> fetchUserMessages(String userId) async {
    final doc = _channelDoc;
    if (doc == null) return const [];
    final normalizedId = CommunityUser.normalizeRawId(userId);
    try {
      final snap = await doc
          .collection('usuarios')
          .doc(normalizedId)
          .collection('mensajes')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      return snap.docs
          .map((d) => CommunityMessage.fromMap(d.data(), docId: d.id))
          .toList();
    } catch (e) {
      debugPrint('CommunityRepository.fetchUserMessages fallback: $e');
      return const [];
    }
  }

  Future<List<SmsInboxItem>> fetchSmsInbox() async {
    final doc = _channelDoc;
    if (doc == null) return const [];
    try {
      final snap = await doc
          .collection('sms')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      return snap.docs
          .map((d) => SmsInboxItem.fromMap(d.data(), docId: d.id))
          .toList();
    } catch (e) {
      debugPrint('CommunityRepository.fetchSmsInbox fallback: $e');
      return const [];
    }
  }

  Future<RemoteStudioState?> fetchStudioState() async {
    final doc = _channelDoc;
    if (doc == null) return null;
    try {
      final snap = await doc.collection('runtime').doc('studio_state').get();
      if (!snap.exists) return null;
      return RemoteStudioState.fromMap(snap.data());
    } catch (e) {
      debugPrint('CommunityRepository.fetchStudioState fallback: $e');
      return null;
    }
  }

  /// Escritura individual de una ficha de usuario (1 write).
  Future<void> saveUser(CommunityUser user) async {
    _writeCount++;
    final doc = _channelDoc;
    if (doc == null) return;
    final normalizedId = CommunityUser.normalizeRawId(user.id);
    try {
      await doc
          .collection('usuarios')
          .doc(normalizedId)
          .set(user.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CommunityRepository.saveUser error: $e');
    }
  }

  /// Escritura diferida en lote para usuarios modificados en memoria.
  Future<void> flushUsersBatch(Iterable<CommunityUser> users) async {
    final list = users.toList();
    if (list.isEmpty) return;
    _writeCount++;
    final db = _db;
    final doc = _channelDoc;
    if (db == null || doc == null) return;
    try {
      final batch = db.batch();
      for (final user in list) {
        final ref = doc
            .collection('usuarios')
            .doc(CommunityUser.normalizeRawId(user.id));
        batch.set(ref, user.toFirestore(), SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('CommunityRepository.flushUsersBatch error: $e');
    }
  }

  /// Escritura del estado de proyección / contexto del estudio (1 write).
  Future<void> saveStudioState(RemoteStudioState state) async {
    _writeCount++;
    final doc = _channelDoc;
    if (doc == null) return;
    try {
      await doc
          .collection('runtime')
          .doc('studio_state')
          .set(state.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CommunityRepository.saveStudioState error: $e');
    }
  }

  /// Guarda un SMS en el buzón cuando se proyecta o persiste explícitamente (1 write).
  Future<void> saveSmsItem(SmsInboxItem item) async {
    _writeCount++;
    final doc = _channelDoc;
    if (doc == null) return;
    try {
      await doc
          .collection('sms')
          .doc(item.id)
          .set(item.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CommunityRepository.saveSmsItem error: $e');
    }
  }

  /// Elimina un SMS del buzón (1 write).
  Future<void> deleteSmsItem(String smsId) async {
    _writeCount++;
    final doc = _channelDoc;
    if (doc == null) return;
    try {
      await doc.collection('sms').doc(smsId).delete();
    } catch (e) {
      debugPrint('CommunityRepository.deleteSmsItem error: $e');
    }
  }

  /// Vacía el buzón de SMS en lote (1 operación de repositorio).
  Future<void> clearSmsInbox(Iterable<String> smsIds) async {
    _writeCount++;
    final db = _db;
    final doc = _channelDoc;
    if (db == null || doc == null) return;
    try {
      final batch = db.batch();
      for (final id in smsIds) {
        batch.delete(doc.collection('sms').doc(id));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('CommunityRepository.clearSmsInbox error: $e');
    }
  }
}
