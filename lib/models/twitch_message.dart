class TwitchChatMessage {
  TwitchChatMessage({
    required this.id,
    required this.channel,
    required this.username,
    required this.displayName,
    required this.message,
    required this.timestamp,
    required this.tags,
    required this.badges,
    required this.isMod,
    required this.isVip,
    required this.isSub,
    required this.isBroadcaster,
    required this.emotes,
  });

  final String id;
  final String channel;
  final String username;
  final String displayName;
  final String message;
  final DateTime timestamp;
  final Map<String, String> tags;
  final String badges;
  final bool isMod;
  final bool isVip;
  final bool isSub;
  final bool isBroadcaster;
  final String emotes;

  bool get isPrivileged => isBroadcaster || isMod || isVip;
}
