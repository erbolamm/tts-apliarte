import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/twitch_message.dart';

class TwitchConnectionState {
  TwitchConnectionState({
    required this.connected,
    this.error,
  });

  final bool connected;
  final String? error;
}

class TwitchIrcClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _connected = false;

  final _messageController =
      StreamController<TwitchChatMessage>.broadcast();
  final _stateController = StreamController<TwitchConnectionState>.broadcast();

  Stream<TwitchChatMessage> get messages => _messageController.stream;
  Stream<TwitchConnectionState> get states => _stateController.stream;

  bool get isConnected => _connected;

  Future<void> connect({
    required String username,
    required String oauthToken,
    required String channel,
  }) async {
    await disconnect();

    final uri = Uri.parse('wss://irc-ws.chat.twitch.tv:443');
    _channel = WebSocketChannel.connect(uri);

    final token = _normalizeToken(oauthToken);
    _sendRaw('PASS $token');
    _sendRaw('NICK $username');
    _sendRaw('CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership');
    _sendRaw('JOIN #$channel');

    _connected = true;
    _stateController.add(TwitchConnectionState(connected: true));

    _subscription = _channel!.stream.listen(
      (dynamic data) {
        final payload = data.toString();
        final lines = payload.split('\r\n');
        for (final line in lines) {
          if (line.isEmpty) {
            continue;
          }
          _handleLine(line, channel);
        }
      },
      onError: (error) {
        _connected = false;
        _stateController.add(
          TwitchConnectionState(connected: false, error: error.toString()),
        );
      },
      onDone: () {
        _connected = false;
        _stateController.add(TwitchConnectionState(connected: false));
      },
    );
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
    if (_connected) {
      _connected = false;
      _stateController.add(TwitchConnectionState(connected: false));
    }
  }

  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _messageController.close();
    _stateController.close();
  }

  Future<void> sendMessage({
    required String channel,
    required String message,
  }) async {
    if (!_connected) {
      return;
    }
    _sendRaw('PRIVMSG #$channel :$message');
  }

  void _handleLine(String line, String channel) {
    if (line.startsWith('PING')) {
      _sendRaw('PONG :tmi.twitch.tv');
      return;
    }

    if (line.contains('NOTICE') && line.contains('authentication failed')) {
      _stateController.add(
        TwitchConnectionState(
          connected: false,
          error: 'Authentication failed. Check OAuth token.',
        ),
      );
      return;
    }

    final message = _parseMessage(line, channel);
    if (message != null) {
      _messageController.add(message);
    }
  }

  TwitchChatMessage? _parseMessage(String raw, String channel) {
    final parsed = _IrcParser.parse(raw);
    if (parsed.command != 'PRIVMSG') {
      return null;
    }

    final tags = parsed.tags;
    final username = parsed.user ?? 'unknown';
    final displayName = tags['display-name'] ?? username;
    final badges = tags['badges'] ?? '';
    final isMod = tags['mod'] == '1' || badges.contains('moderator/');
    final isVip = badges.contains('vip/');
    final isSub = tags['subscriber'] == '1' || badges.contains('subscriber/');
    final isBroadcaster = badges.contains('broadcaster/');
    final messageId = tags['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final emotes = tags['emotes'] ?? '';

    return TwitchChatMessage(
      id: messageId,
      channel: channel,
      username: username,
      displayName: displayName,
      message: parsed.trailing ?? '',
      timestamp: DateTime.now(),
      tags: tags,
      badges: badges,
      isMod: isMod,
      isVip: isVip,
      isSub: isSub,
      isBroadcaster: isBroadcaster,
      emotes: emotes,
    );
  }

  void _sendRaw(String command) {
    _channel?.sink.add(command);
  }

  String _normalizeToken(String token) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return 'oauth:missing';
    }
    if (trimmed.startsWith('oauth:')) {
      return trimmed;
    }
    return 'oauth:$trimmed';
  }
}

class _IrcMessage {
  _IrcMessage({
    required this.tags,
    required this.command,
    required this.trailing,
    required this.user,
  });

  final Map<String, String> tags;
  final String command;
  final String? trailing;
  final String? user;
}

class _IrcParser {
  static _IrcMessage parse(String raw) {
    var buffer = raw;
    final tags = <String, String>{};

    if (buffer.startsWith('@')) {
      final spaceIndex = buffer.indexOf(' ');
      if (spaceIndex != -1) {
        final tagsPart = buffer.substring(1, spaceIndex);
        buffer = buffer.substring(spaceIndex + 1);
        final tagPairs = tagsPart.split(';');
        for (final pair in tagPairs) {
          final kv = pair.split('=');
          if (kv.isEmpty) {
            continue;
          }
          final key = kv[0];
          final value = kv.length > 1 ? kv[1] : '';
          tags[key] = value;
        }
      }
    }

    String? user;
    if (buffer.startsWith(':')) {
      final spaceIndex = buffer.indexOf(' ');
      if (spaceIndex != -1) {
        final prefix = buffer.substring(1, spaceIndex);
        buffer = buffer.substring(spaceIndex + 1);
        final bang = prefix.indexOf('!');
        if (bang != -1) {
          user = prefix.substring(0, bang);
        } else {
          user = prefix;
        }
      }
    }

    String? trailing;
    final trailingIndex = buffer.indexOf(' :');
    if (trailingIndex != -1) {
      trailing = buffer.substring(trailingIndex + 2);
      buffer = buffer.substring(0, trailingIndex);
    }

    final parts = buffer.split(' ');
    final command = parts.isNotEmpty ? parts[0] : '';

    return _IrcMessage(
      tags: tags,
      command: command,
      trailing: trailing,
      user: user,
    );
  }
}
