import 'package:isar/isar.dart';

part 'vault_item.g.dart';

@collection
class VaultItem {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String title;

  late String category;

  String? username;

  /// Encrypted password string (Base64)
  late String encryptedPassword;

  /// Encrypted note string (Base64)
  String? encryptedNote;

  late DateTime createdAt;

  VaultItem() {
    createdAt = DateTime.now();
  }
}
