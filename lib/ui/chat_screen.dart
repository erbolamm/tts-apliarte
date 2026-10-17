import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controllers/remote_studio_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/community_models.dart';
import 'widgets/live_projection_banner.dart';
import 'widgets/user_ficha_sheet.dart';

/// Ventana de chat en directo con soporte de proyección a OBS (👁️), apertura
/// de ficha CRM al tocar un usuario y pestaña de popout oficial de Twitch.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.enableWebView = true});

  final bool enableWebView;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  WebViewController? _controller;
  bool _loading = true;
  bool _showWebView = false;
  String? _channel;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsController>().settings;
    _channel = settings.twitchChannel.isNotEmpty
        ? settings.twitchChannel
        : settings.twitchUsername;

    if (widget.enableWebView) {
      final url = _channel != null && _channel!.isNotEmpty
          ? 'https://www.twitch.tv/popout/$_channel/chat?popout=&darkpopout'
          : 'https://www.twitch.tv';
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 12; CPH2669) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _loading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onNavigationRequest: (request) {
              if (request.url.contains('twitch.tv')) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
          ),
        )
        ..loadRequest(Uri.parse(url));
    }

  }

  void _openUserFicha(BuildContext context, CommunityMessage msg) {
    final studio = context.read<RemoteStudioController>();
    final existing = studio.getUser(msg.usuarioId) ??
        CommunityUser(
          id: msg.usuarioId,
          plataforma: msg.plataforma,
          usuario: msg.usuario,
          nombreVisible: msg.nombreVisible,
          primerMensajeEn: msg.timestamp,
          ultimoMensajeEn: msg.timestamp,
          actualizadoEn: msg.timestamp,
          ultimoTexto: msg.texto,
          ultimaFechaHora: msg.fechaHora,
        );
    showUserFichaSheet(context, existing);
  }

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<RemoteStudioController>();
    final messages = studio.recentChatMessages;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _channel != null && _channel!.isNotEmpty
              ? '💬 Chat · #$_channel'
              : '💬 Chat Twitch',
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () => setState(() => _showWebView = !_showWebView),
            icon: Icon(_showWebView ? Icons.list_alt : Icons.public, size: 18),
            label: Text(_showWebView ? 'Chat Estudio' : 'WebView Twitch'),
          ),
          if (_showWebView && _controller != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recargar chat',
              onPressed: () => _controller?.reload(),
            ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: LiveProjectionBanner(),
          ),
          Expanded(
            child: _showWebView && _controller != null
                ? Stack(
                    children: [
                      WebViewWidget(controller: _controller!),
                      if (_loading)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  )
                : messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Esperando mensajes en directo…',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final projected = studio.isMessageProjected(msg);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: projected
                                  ? const Color(0xFF1D9BF0)
                                      .withValues(alpha: 0.2)
                                  : const Color(0xFF0E1117),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: projected
                                    ? const Color(0xFFFFB400)
                                    : const Color(0x22FFFFFF),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        onTap: () =>
                                            _openUserFicha(context, msg),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '@${msg.nombreVisible}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1D9BF0),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              msg.fechaHora,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        msg.texto,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: projected
                                      ? 'Ocultar de OBS'
                                      : 'Proyectar en OBS',
                                  icon: Icon(
                                    projected
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: projected
                                        ? const Color(0xFFFFB400)
                                        : Colors.grey.shade400,
                                  ),
                                  onPressed: () =>
                                      studio.toggleProjectedMessage(msg),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

