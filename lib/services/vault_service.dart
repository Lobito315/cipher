import 'dart:async';
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/vault_item.dart';
import 'secure_storage_service.dart';
import 'encryption_service.dart';

class VaultService {
  static final VaultService _instance = VaultService._internal();
  factory VaultService() => _instance;
  VaultService._internal();

  final _secureStorage = SecureStorageService();
  final _encryptionService = EncryptionService();
  
  final _itemsController = StreamController<List<VaultItem>>.broadcast();
  List<VaultItem> _cachedItems = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    // We do NOT generate a random key anymore. 
    // The key must be derived from a Master Password.
    final bool hasKey = await hasVaultKey();
    if (hasKey) {
      _refreshItems(); // preload
    }
    _initialized = true;
  }

  Future<String> _getVaultKeyStorageKey() async {
    final user = await Amplify.Auth.getCurrentUser();
    return 'vault_db_key_${user.userId}';
  }

  Future<String> _getVaultVerifyStorageKey() async {
    final user = await Amplify.Auth.getCurrentUser();
    return 'vault_verify_${user.userId}';
  }

  Future<bool> hasVaultKey() async {
    final key = await _getVaultKeyStorageKey();
    final stored = await _secureStorage.readRaw(key);
    return stored != null;
  }

  Future<void> setupVaultKey(String masterPassword) async {
    final user = await Amplify.Auth.getCurrentUser();
    // Derive key using PBKDF2 with the user's ID as the salt
    final keyBytes = await _encryptionService.deriveVaultKey(masterPassword, user.userId);
    final vaultKeyBase64 = base64Encode(keyBytes);

    // Store a verification token: encrypt a known string with the derived key
    // This lets us verify the password is correct on next unlock
    final verifyToken = await _encryptionService.encryptLocal(
      '__cipher_vault_verify__${user.userId}',
      keyBytes,
    );

    final keyStorageKey = await _getVaultKeyStorageKey();
    final verifyStorageKey = await _getVaultVerifyStorageKey();
    await _secureStorage.writeRaw(keyStorageKey, vaultKeyBase64);
    await _secureStorage.writeRaw(verifyStorageKey, verifyToken);

    // Refresh items now that we have the key
    await _refreshItems();
  }

  /// Returns true if password is correct, false otherwise
  Future<bool> verifyMasterPassword(String masterPassword) async {
    final user = await Amplify.Auth.getCurrentUser();
    final verifyStorageKey = await _getVaultVerifyStorageKey();
    final storedToken = await _secureStorage.readRaw(verifyStorageKey);
    if (storedToken == null) return false;

    try {
      final keyBytes = await _encryptionService.deriveVaultKey(masterPassword, user.userId);
      final decrypted = await _encryptionService.decryptLocal(storedToken, keyBytes);
      return decrypted == '__cipher_vault_verify__${user.userId}';
    } catch (_) {
      return false;
    }
  }

  Future<void> lock() async {
    final keyStorageKey = await _getVaultKeyStorageKey();
    await _secureStorage.deleteRaw(keyStorageKey);
    _cachedItems = [];
    _itemsController.add([]);
  }

  Future<List<int>> _getVaultKey() async {
    final keyStorageKey = await _getVaultKeyStorageKey();
    final b64 = await _secureStorage.readRaw(keyStorageKey);
    if (b64 == null) throw Exception("Vault key not initialized");
    return base64Decode(b64);
  }

  Stream<List<VaultItem>> watchItems() {
    _refreshItems(); // Trigger fetch right away
    return _itemsController.stream;
  }

  Future<void> _refreshItems() async {
    try {
      final items = await getAllItems();
      _cachedItems = items;
      _itemsController.add(List.unmodifiable(_cachedItems));
    } catch (e) {
      print('DEBUG: Error refreshing vault items: $e');
    }
  }

  Future<List<VaultItem>> getAllItems() async {
    List<VaultItem> localItems = await _loadItemsLocally();
    
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final myId = user.userId;

      const operation = 'query ListVaultItems(\$filter: ModelVaultItemFilterInput) { '
          'listVaultItems(filter: \$filter) { items { id ownerId title category username encryptedPassword encryptedNote createdAt } } }';
      
      final request = GraphQLRequest<String>(
        document: operation,
        variables: {
          'filter': {
            'ownerId': {'eq': myId}
          },
        },
      );

      final response = await Amplify.API.query(request: request).response;
      if (response.hasErrors || response.data == null) {
        return localItems;
      }

      final data = jsonDecode(response.data!);
      final itemsList = data['listVaultItems']['items'] as List;
      final remoteItems = itemsList.map((json) => VaultItem.fromJson(json)).toList();
      
      // Combine and filter duplicates by ID
      final Map<String, VaultItem> combined = {};
      for (var item in localItems) { combined[item.id] = item; }
      for (var item in remoteItems) { combined[item.id] = item; }
      
      final results = combined.values.toList();
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      print("Error getAllItems (using local only): $e");
      return localItems;
    }
  }

  Future<void> addItem({
    required String title,
    required String category,
    String? username,
    required String password,
    String? note,
  }) async {
    print('DEBUG: Starting addItem for $title');
    final key = await _getVaultKey();
    
    final encryptedPassword = await _encryptionService.encryptLocal(password, key);
    final encryptedNote = (note != null && note.isNotEmpty) ? await _encryptionService.encryptLocal(note, key) : null;

    final user = await Amplify.Auth.getCurrentUser();
    final ownerId = user.userId;
    final now = DateTime.now().toUtc().toIso8601String();

    Map<String, dynamic> itemData = {
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'ownerId': ownerId,
      'title': title,
      'category': category,
      'username': username,
      'encryptedPassword': encryptedPassword,
      'encryptedNote': encryptedNote,
      'createdAt': now,
    };

    try {
      const operation = 'mutation CreateVaultItem(\$input: CreateVaultItemInput!) { '
          'createVaultItem(input: \$input) { id ownerId title category username encryptedPassword encryptedNote createdAt } }';
          
      final request = GraphQLRequest<String>(
        document: operation,
        variables: {
          'input': {
            'ownerId': ownerId,
            'title': title,
            'category': category,
            if (username != null && username.isNotEmpty) 'username': username,
            'encryptedPassword': encryptedPassword,
            if (encryptedNote != null) 'encryptedNote': encryptedNote,
            'createdAt': now,
          }
        },
      );

      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) throw Exception(response.errors);
      // Also save locally so it persists even if AWS is slow
      await _saveItemLocally(itemData);
    } catch (e) {
      // AWS failed: save locally only
      await _saveItemLocally(itemData);
    }
    
    await _refreshItems();
  }

  Future<void> _saveItemLocally(Map<String, dynamic> item) async {
    final localData = await _secureStorage.readRaw('vault_items_local');
    List<dynamic> items = [];
    if (localData != null) {
      items = jsonDecode(localData);
    }
    // Avoid duplicates
    items.removeWhere((e) => e['id'] == item['id']);
    items.add(item);
    await _secureStorage.writeRaw('vault_items_local', jsonEncode(items));
  }

  Future<List<VaultItem>> _loadItemsLocally() async {
    final localData = await _secureStorage.readRaw('vault_items_local');
    if (localData == null) return [];
    final List<dynamic> decoded = jsonDecode(localData);
    return decoded.map((json) => VaultItem.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<String> decryptField(String encryptedData) async {
    final key = await _getVaultKey();
    return await _encryptionService.decryptLocal(encryptedData, key);
  }

  Future<void> deleteItem(String id) async {
    try {
      const operation = 'mutation DeleteVaultItem(\$input: DeleteVaultItemInput!) { '
          'deleteVaultItem(input: \$input) { id } }';
          
      final request = GraphQLRequest<String>(
        document: operation,
        variables: {
          'input': { 'id': id }
        },
      );

      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) throw Exception(response.errors);
    } catch (e) {
      print('DEBUG: AWS delete failed, checking local: $e');
      await _deleteItemLocally(id);
    }

    await _refreshItems();
  }

  Future<void> _deleteItemLocally(String id) async {
    final localData = await _secureStorage.readRaw('vault_items_local');
    if (localData == null) return;
    
    List<dynamic> items = jsonDecode(localData);
    items.removeWhere((item) => item['id'] == id);
    await _secureStorage.writeRaw('vault_items_local', jsonEncode(items));
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteRaw('vault_items_local');
    final items = await getAllItems();
    for (var item in items) {
      try {
        await deleteItem(item.id);
      } catch (e) {
        // ignore errors for mass deletion
      }
    }
  }
}
