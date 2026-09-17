/// Datos de conexión leídos de un QR de "Mostrar información de conexión"
/// de OBS (`obs-websocket`).
class ObsQrDatos {
  const ObsQrDatos({required this.host, required this.port, required this.password});
  final String host;
  final int port;
  final String password;
}

/// Parsea el texto de un QR de OBS: `obsws://<ip>:<puerto>/<contraseña>`
/// (contraseña codificada para URL) o `obsws://<ip>:<puerto>` sin contraseña
/// si OBS tiene la autenticación desactivada. Formato verificado contra el
/// código fuente real de obs-websocket (`src/forms/ConnectInfo.cpp`), no
/// inventado.
///
/// Devuelve null si el texto no es un QR de OBS válido — nunca lanza.
ObsQrDatos? parsearQrObs(String texto) {
  final valor = texto.trim();
  final uri = Uri.tryParse(valor);
  if (uri == null || uri.scheme != 'obsws' || uri.host.isEmpty) {
    return null;
  }
  final puerto = uri.hasPort ? uri.port : 4455;
  final contrasenaCodificada = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
  String contrasena;
  try {
    contrasena = contrasenaCodificada.isEmpty ? '' : Uri.decodeComponent(contrasenaCodificada);
  } on FormatException {
    contrasena = contrasenaCodificada;
  }
  return ObsQrDatos(host: uri.host, port: puerto, password: contrasena);
}
