import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controllers/settings_controller.dart';

/// Ventana de chat de Twitch embebido (popout oficial de Twitch).
/// URL: https://www.twitch.tv/popout/{canal}/chat?popout=
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _channel;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsController>().settings;
    _channel = settings.twitchChannel.isNotEmpty
        ? settings.twitchChannel
        : settings.twitchUsername;

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
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (request) {
            // Solo permite quedarse en el chat de Twitch
            if (request.url.contains('twitch.tv')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _channel != null && _channel!.isNotEmpty
              ? '💬 Chat · #$_channel'
              : '💬 Chat Twitch',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar chat',
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
