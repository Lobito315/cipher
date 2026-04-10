class Contact {
  final String userId;
  final String username;
  final String? alias;
  final String? avatarUrl;
  final String? avatarBase64;
  final DateTime addedAt;

  Contact({
    required this.userId,
    required this.username,
    this.alias,
    this.avatarUrl,
    this.avatarBase64,
    required this.addedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      userId: json['userId'] as String,
      username: json['username'] as String,
      alias: json['alias'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      avatarBase64: json['avatarBase64'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      if (alias != null) 'alias': alias,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (avatarBase64 != null) 'avatarBase64': avatarBase64,
      'addedAt': addedAt.toUtc().toIso8601String(),
    };
  }

  String get displayName => (alias != null && alias!.isNotEmpty) ? alias! : username;
}
