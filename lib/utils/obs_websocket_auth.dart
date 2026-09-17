import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Respuesta de autenticación del protocolo `obs-websocket` v5.
///
/// Algoritmo exacto de la especificación:
/// secreto = base64(sha256(contraseña + sal))
/// respuesta = base64(sha256(secreto + desafío))
///
/// Función pura para poder probarla sin abrir ninguna conexión real.
String calcularAutenticacionObs({
  required String password,
  required String salt,
  required String challenge,
}) {
  final secreto = base64.encode(sha256.convert(utf8.encode(password + salt)).bytes);
  return base64.encode(sha256.convert(utf8.encode(secreto + challenge)).bytes);
}
