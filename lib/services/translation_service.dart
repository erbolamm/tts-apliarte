import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Motor de traducción integrado.
/// Funciona sin configuración usando proveedores gratuitos.
/// Acepta un endpoint personalizado como alternativa avanzada.
class TranslationService {
  TranslationService({this.customBaseUrl = '', this.apiKey = ''});

  final String customBaseUrl;
  final String apiKey;

  // URL antigua que guardaban instalaciones previas — ignorar como si fuera vacía.
  static const _legacyDefault = 'https://libretranslate.com';

  Future<String> translate({
    required String text,
    required String source,
    required String target,
  }) async {
    if (text.trim().isEmpty) return text;

    final url = customBaseUrl.trim();
    if (url.isNotEmpty && url != _legacyDefault) {
      return _translateCustom(text, source, target, url);
    }

    // Motor integrado: MyMemory primero, Lingva como fallback.
    try {
      return await _translateMyMemory(text, source, target);
    } catch (_) {
      try {
        return await _translateLingva(text, source, target);
      } catch (_) {
        return text;
      }
    }
  }

  Future<String> _translateMyMemory(
    String text,
    String source,
    String target,
  ) async {
    final langPair = source == 'auto'
        ? 'autodetect|$target'
        : '$source|$target';
    final uri = Uri.https('api.mymemory.translated.net', '/get', {
      'q': text,
      'langpair': langPair,
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      throw HttpException('MyMemory ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final responseData = data['responseData'];
    if (responseData is Map) {
      final translated = responseData['translatedText'];
      if (translated is String && translated.isNotEmpty) {
        // Javier: Evitar que MyMemory inyecte sus errores o avisos como si fueran la traducción
        if (translated.contains('PLEASE SELECT TWO DISTINCT LANGUAGES') ||
            translated.contains('MYMEMORY WARNING') ||
            translated.contains('INVALID TARGET LANGUAGE')) {
          return text; // Devolver el texto original
        }
        return translated;
      }
    }
    throw const FormatException('No translation');
  }

  Future<String> _translateLingva(
    String text,
    String source,
    String target,
  ) async {
    final src = source == 'auto' ? 'auto' : source;
    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('https://lingva.ml/api/v1/$src/$target/$encoded');
    final response = await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      throw HttpException('Lingva ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final translation = data['translation'];
    if (translation is String && translation.isNotEmpty) {
      return translation;
    }
    throw const FormatException('No translation');
  }

  Future<String> _translateCustom(
    String text,
    String source,
    String target,
    String baseUrl,
  ) async {
    final uri = Uri.parse(baseUrl).resolve('/translate');
    final payload = {
      'q': text,
      'source': source,
      'target': target,
      'format': 'text',
      if (apiKey.trim().isNotEmpty) 'api_key': apiKey.trim(),
    };
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Custom endpoint ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final translated = decoded['translatedText'];
    if (translated is String) return translated;
    return text;
  }
}
