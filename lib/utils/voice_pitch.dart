/// Deriva un `pitch` determinista para `flutter_tts` a partir del username,
/// para que cada usuario sin voz manual asignada (`!speak -config`) suene
/// con un tono distinto en lugar de compartir siempre el mismo.
double pitchForUsername(String username, {double min = 0.8, double max = 1.3}) {
  final hash = _stableHash(username.toLowerCase());
  final normalized = hash / _hashModulus;
  return min + normalized * (max - min);
}

const int _hashModulus = 1000003;

// Hash polinómico simple (base 31, acotado por _hashModulus en cada paso)
// en lugar de String.hashCode: así el resultado es estable entre ejecuciones
// y plataformas, y las multiplicaciones se mantienen dentro del rango entero
// seguro tanto en VM/AOT como al compilar a JS.
int _stableHash(String input) {
  var hash = 0;
  for (final unit in input.codeUnits) {
    hash = (hash * 31 + unit) % _hashModulus;
  }
  return hash;
}
