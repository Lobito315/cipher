import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import 'secure_storage_service.dart';

/// ContactService with a self-message persistence strategy:
/// Contacts are stored as a special encrypted message to oneself on AWS,
/// ensuring persistence across browsers, sessions, and incognito mode.
class ContactService {
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  final _secureStorage = SecureStorageService();
  static const String _contactsMarker = '__cipher_contacts_v1__';

  // In-memory cache for fast access within a session
  List<Contact>? _cache;

  Future<String> _getStoreKey() async {
    final user = await Amplify.Auth.getCurrentUser();
    return 'contacts_${user.userId}';
  }

  /// Get contacts — in-memory first, then cloud, then local
  Future<List<Contact>> getContacts() async {
    // 1. Return in-memory cache if available
    if (_cache != null) return List.from(_cache!);

    // 2. Try loading from AWS (stored as a self-sent message)
    try {
      final cloudContacts = await _loadFromCloud();
      if (cloudContacts != null) {
        _cache = cloudContacts;
        await _writeLocalCache(cloudContacts);
        return List.from(_cache!);
      }
    } catch (e) {
      debugPrint('ContactService: cloud load failed, using local: $e');
    }

    // 3. Fallback: local SecureStorage
    final local = await _readLocalCache();
    _cache = local;
    return List.from(_cache!);
  }

  Future<void> addContact(Map<String, dynamic> profile, {String? alias}) async {
    final contacts = await getContacts();
    final userId = profile['id'] as String;

    if (contacts.any((c) => c.userId == userId)) return;

    final newContact = Contact(
      userId: userId,
      username: profile['username'] ?? profile['email'] ?? 'Unknown',
      alias: alias,
      avatarUrl: profile['avatarUrl'],
      addedAt: DateTime.now(),
    );

    contacts.add(newContact);
    await _persistContacts(contacts);
  }

  Future<void> removeContact(String userId) async {
    final contacts = await getContacts();
    contacts.removeWhere((c) => c.userId == userId);
    await _persistContacts(contacts);
  }

  Future<void> updateAlias(String userId, String? alias) async {
    final contacts = await getContacts();
    final index = contacts.indexWhere((c) => c.userId == userId);
    if (index != -1) {
      final old = contacts[index];
      contacts[index] = Contact(
        userId: old.userId,
        username: old.username,
        alias: alias,
        avatarUrl: old.avatarUrl,
        avatarBase64: old.avatarBase64,
        addedAt: old.addedAt,
      );
      await _persistContacts(contacts);
    }
  }

  Future<void> updateAvatar(String userId, List<int> bytes) async {
    final contacts = await getContacts();
    final index = contacts.indexWhere((c) => c.userId == userId);
    if (index != -1) {
      final old = contacts[index];
      contacts[index] = Contact(
        userId: old.userId,
        username: old.username,
        alias: old.alias,
        avatarUrl: old.avatarUrl,
        avatarBase64: base64Encode(bytes),
        addedAt: old.addedAt,
      );
      await _persistContacts(contacts);
    }
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  Future<void> _persistContacts(List<Contact> contacts) async {
    _cache = contacts;
    await _writeLocalCache(contacts);
    await _saveToCloud(contacts);
  }

  // ── Local Cache ──────────────────────────────────────────────────────────

  Future<List<Contact>> _readLocalCache() async {
    try {
      final key = await _getStoreKey();
      final data = await _secureStorage.readRaw(key);
      if (data == null) return [];
      final List<dynamic> decoded = jsonDecode(data);
      return decoded
          .map((json) => Contact.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ContactService: local cache read error: $e');
      return [];
    }
  }

  Future<void> _writeLocalCache(List<Contact> contacts) async {
    try {
      final key = await _getStoreKey();
      final data = jsonEncode(contacts.map((c) => c.toJson()).toList());
      await _secureStorage.writeRaw(key, data);
    } catch (e) {
      debugPrint('ContactService: local cache write error: $e');
    }
  }

  // ── AWS Cloud Persistence (self-message strategy) ────────────────────────

  /// Looks for the special contacts message sent to oneself
  Future<List<Contact>?> _loadFromCloud() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final myId = user.userId;

      const operation = 'query ListMessages(\$filter: ModelMessageFilterInput) { '
          'listMessages(filter: \$filter) { items { id content createdAt } } }';

      final request = GraphQLRequest<String>(
        document: operation,
        variables: {
          'filter': {
            'and': [
              {'senderId': {'eq': myId}},
              {'receiverId': {'eq': myId}},
              {'content': {'beginsWith': _contactsMarker}},
            ]
          }
        },
        authorizationMode: APIAuthorizationType.apiKey,
      );

      final response = await Amplify.API.query(request: request).response;
      if (response.hasErrors || response.data == null) return null;

      final decoded = jsonDecode(response.data!);
      final items = (decoded['listMessages']['items'] as List)
          .cast<Map<String, dynamic>>();

      if (items.isEmpty) return null;

      // Use the most recently updated one
      items.sort((a, b) =>
          (b['createdAt'] as String).compareTo(a['createdAt'] as String));

      final content = items.first['content'] as String;
      final jsonStr = content.substring(_contactsMarker.length);
      final List<dynamic> contactsList = jsonDecode(jsonStr);
      return contactsList
          .map((json) => Contact.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ContactService: cloud read error: $e');
      return null;
    }
  }

  String? _cloudMessageId; // track existing cloud record

  Future<void> _saveToCloud(List<Contact> contacts) async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final myId = user.userId;

      // Strip large base64 avatars before cloud save
      final lightContacts = contacts.map((c) => Contact(
        userId: c.userId,
        username: c.username,
        alias: c.alias,
        avatarUrl: c.avatarUrl,
        addedAt: c.addedAt,
      )).toList();

      final content = '$_contactsMarker${jsonEncode(lightContacts.map((c) => c.toJson()).toList())}';

      // Try to find and delete old record first
      await _deleteOldCloudRecord(myId);

      // Create fresh record
      const mutation = 'mutation CreateMessage(\$input: CreateMessageInput!) { '
          'createMessage(input: \$input) { id } }';

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {
          'input': {
            'senderId': myId,
            'receiverId': myId,
            'content': content,
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          }
        },
        authorizationMode: APIAuthorizationType.apiKey,
      );

      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) {
        debugPrint('ContactService: cloud save error: ${response.errors}');
      } else {
        final data = jsonDecode(response.data!);
        _cloudMessageId = data['createMessage']['id'] as String?;
        debugPrint('ContactService: contacts saved to cloud ✓ (${contacts.length})');
      }
    } catch (e) {
      debugPrint('ContactService: cloud save exception: $e');
    }
  }

  Future<void> _deleteOldCloudRecord(String myId) async {
    try {
      // Find old contacts records
      const query = 'query ListMessages(\$filter: ModelMessageFilterInput) { '
          'listMessages(filter: \$filter) { items { id } } }';

      final queryReq = GraphQLRequest<String>(
        document: query,
        variables: {
          'filter': {
            'and': [
              {'senderId': {'eq': myId}},
              {'receiverId': {'eq': myId}},
              {'content': {'beginsWith': _contactsMarker}},
            ]
          }
        },
        authorizationMode: APIAuthorizationType.apiKey,
      );

      final response = await Amplify.API.query(request: queryReq).response;
      if (response.hasErrors || response.data == null) return;

      final decoded = jsonDecode(response.data!);
      final items = (decoded['listMessages']['items'] as List)
          .cast<Map<String, dynamic>>();

      for (final item in items) {
        const deleteMutation = 'mutation DeleteMessage(\$input: DeleteMessageInput!) { '
            'deleteMessage(input: \$input) { id } }';
        final deleteReq = GraphQLRequest<String>(
          document: deleteMutation,
          variables: {'input': {'id': item['id']}},
          authorizationMode: APIAuthorizationType.apiKey,
        );
        await Amplify.API.mutate(request: deleteReq).response;
      }
    } catch (e) {
      debugPrint('ContactService: cleanup error: $e');
    }
  }

  /// Clear in-memory cache (call on sign out)
  void clearCache() {
    _cache = null;
    _cloudMessageId = null;
  }
}
