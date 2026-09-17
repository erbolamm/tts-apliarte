/// Normaliza la URL base del servidor propio de escenas (paso 4 de la cadena
/// directo/tts-apliarte). Función pura para poder probarla sin red ni Flutter.
///
/// Devuelve null si `raw` está vacío o no es una URL http(s) usable — nunca
/// una cadena a medias que rompa una llamada de red silenciosamente.
String? normalizarBaseUrlEscenas(String raw) {
  final valor = raw.trim();
  if (valor.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(valor);
  if (uri == null || !uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
    return null;
  }
  final sinBarraFinal = valor.endsWith('/') ? valor.substring(0, valor.length - 1) : valor;
  return sinBarraFinal;
}

/// Construye la URL completa de `/api/escena` a partir de la base ya
/// normalizada. Asume que `baseNormalizada` viene de
/// [normalizarBaseUrlEscenas] (sin barra final).
String urlApiEscena(String baseNormalizada) => '$baseNormalizada/api/escena';
