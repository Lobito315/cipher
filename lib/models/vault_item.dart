class VaultItem {
  final String id;
  final String ownerId;
  final String title;
  final String category;
  final String? username;
  final String encryptedPassword;
  final String? encryptedNote;
  final DateTime createdAt;

  VaultItem({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.category,
    this.username,
    required this.encryptedPassword,
    this.encryptedNote,
    required this.createdAt,
  });

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      username: json['username'] as String?,
      encryptedPassword: json['encryptedPassword'] as String,
      encryptedNote: json['encryptedNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'category': category,
      if (username != null) 'username': username,
      'encryptedPassword': encryptedPassword,
      if (encryptedNote != null) 'encryptedNote': encryptedNote,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
}
