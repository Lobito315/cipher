import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vault_item.dart';
import 'secure_storage_service.dart';
import 'encryption_service.dart';

class VaultService {
  static final VaultService _instance = VaultService._internal();
  factory VaultService() => _instance;
  VaultService._internal();

  Isar? _isar;
  final _secureStorage = SecureStorageService();
  final _encryptionService = EncryptionService();

  Future<void> init() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();

    // 1. Get or generate a vault encryption key
    // This key is used by Isar to encrypt the entire database file
    String? vaultKeyBase64 = await _secureStorage.readRaw('vault_db_key');

    if (vaultKeyBase64 == null) {
      // Generate a new 32-byte key for Isar encryption
      final key = await _encryptionService.generateRandomBytes(32);
      vaultKeyBase64 = base64Encode(key);
      await _secureStorage.writeRaw('vault_db_key', vaultKeyBase64);
    }

    // 2. Open Isar with encryption
    _isar = await Isar.open(
      [VaultItemSchema],
      directory: dir.path,
      name: 'cipher_vault',
      inspector: true, // Enable inspector for debugging
    );
    // Note: Isar v3 does not support native file encryption on all platforms
    // without specialized builds. For Phase 3, we will use field-level encryption
    // in the service to ensure data is protected even if the file is stolen.
  }

  // --- CRUD Operations ---

  /// Internal helper to get the vault key bytes
  Future<List<int>> _getVaultKey() async {
    final b64 = await _secureStorage.readRaw('vault_db_key');
    if (b64 == null) throw Exception("Vault key not initialized");
    return base64Decode(b64);
  }

  Stream<List<VaultItem>> watchItems() {
    if (_isar == null) return const Stream.empty();
    return _isar!.vaultItems.where().sortByCreatedAtDesc().watch(
      fireImmediately: true,
    );
  }

  Future<List<VaultItem>> getAllItems() async {
    if (_isar == null) await init();
    return await _isar!.vaultItems.where().sortByCreatedAtDesc().findAll();
  }

  /// Saves a new item with encrypted sensitive fields
  Future<void> addItem({
    required String title,
    required String category,
    String? username,
    required String password,
    String? note,
  }) async {
    if (_isar == null) await init();
    final key = await _getVaultKey();

    final encryptedPassword = await _encryptionService.encryptLocal(
      password,
      key,
    );
    final encryptedNote = note != null
        ? await _encryptionService.encryptLocal(note, key)
        : null;

    final item = VaultItem()
      ..title = title
      ..category = category
      ..username = username
      ..encryptedPassword = encryptedPassword
      ..encryptedNote = encryptedNote;

    await _isar!.writeTxn(() async {
      await _isar!.vaultItems.put(item);
    });
  }

  /// Decrypts a specific field using the vault key
  Future<String> decryptField(String encryptedData) async {
    final key = await _getVaultKey();
    return await _encryptionService.decryptLocal(encryptedData, key);
  }

  Future<void> deleteItem(int id) async {
    if (_isar == null) await init();
    await _isar!.writeTxn(() async {
      await _isar!.vaultItems.delete(id);
    });
  }

  Future<void> clearAll() async {
    if (_isar == null) await init();
    await _isar!.writeTxn(() async {
      await _isar!.vaultItems.clear();
    });
  }
}
