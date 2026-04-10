import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileService {
  Future<void> updatePublicKey(String userId, String publicKeyBase64, [String? username]) async {
    final existing = await getPublicKey(userId);
    
    if (existing == null) {
      const operation = 'mutation CreateProfile(\$id: ID!, \$publicKey: String!, \$username: String!, \$updatedAt: AWSDateTime!) { '
          'createProfile(input: {id: \$id, publicKey: \$publicKey, username: \$username, updatedAt: \$updatedAt}) { id } }';
      final request = GraphQLRequest<String>(
        document: operation,
        variables: {
          'id': userId,
          'publicKey': publicKeyBase64,
          'username': username ?? userId,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) {
        throw Exception('Failed to create public key: ${response.errors}');
      }
    } else {
      const operation = 'mutation UpdateProfile(\$id: ID!, \$publicKey: String!, \$updatedAt: AWSDateTime!) { '
          'updateProfile(input: {id: \$id, publicKey: \$publicKey, updatedAt: \$updatedAt}) { id } }';
      
      final request = GraphQLRequest<String>(
        document: operation,
        variables: {
          'id': userId,
          'publicKey': publicKeyBase64,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );

      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) {
        throw Exception('Failed to update public key: ${response.errors}');
      }
    }
  }

  Future<void> updateUsername(String userId, String newUsername) async {
    final profile = await getFullProfile(userId);
    
    if (profile == null) {
      const operation = 'mutation CreateProfile(\$id: ID!, \$username: String!, \$updatedAt: AWSDateTime!) { '
          'createProfile(input: {id: \$id, username: \$username, updatedAt: \$updatedAt}) { id } }';
      final request = GraphQLRequest<String>(
        document: operation,
        variables: {
          'id': userId,
          'username': newUsername,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) {
        throw Exception('Failed to create profile: ${response.errors}');
      }
    } else {
      const operation = 'mutation UpdateProfile(\$id: ID!, \$username: String!, \$updatedAt: AWSDateTime!) { '
          'updateProfile(input: {id: \$id, username: \$username, updatedAt: \$updatedAt}) { id username } }';
      
      final request = GraphQLRequest<String>(
        document: operation,
        variables: {
          'id': userId,
          'username': newUsername,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );

      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) {
        throw Exception('Failed to update username: ${response.errors}');
      }
    }
  }

  Future<void> updateAvatarUrl(String userId, String? avatarUrl) async {
    final profile = await getFullProfile(userId);

    if (profile == null) {
      const operation = 'mutation CreateProfile(\$id: ID!, \$updatedAt: AWSDateTime!) { '
          'createProfile(input: {id: \$id, updatedAt: \$updatedAt}) { id } }';
      final request = GraphQLRequest<String>(
        document: operation,
        variables: {
          'id': userId,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) {
        throw Exception('Failed to create profile with avatar: ${response.errors}');
      }
    } else {
      const operation = 'mutation UpdateProfile(\$id: ID!, \$updatedAt: AWSDateTime!) { '
          'updateProfile(input: {id: \$id, updatedAt: \$updatedAt}) { id } }';
      
      final request = GraphQLRequest<String>(
        document: operation,
        variables: {
          'id': userId,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );

      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) {
        throw Exception('Failed to update avatar: ${response.errors}');
      }
    }
  }

  Future<String?> getPublicKey(String userId) async {
    const operation = 'query GetProfile(\$id: ID!) { '
        'getProfile(id: \$id) { publicKey } }';
    
    final request = GraphQLRequest<String>(
      document: operation,
      variables: {'id': userId},
    );

    final response = await Amplify.API.query(request: request).response;
    if (response.hasErrors || response.data == null) {
      return null;
    }
    
    try {
      final Map<String, dynamic> data = jsonDecode(response.data!);
      if (data['getProfile'] == null) return null;
      return data['getProfile']['publicKey'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFullProfile(String userId) async {
    const operation = 'query GetProfile(\$id: ID!) { '
        'getProfile(id: \$id) { id publicKey username updatedAt } }';
    
    final request = GraphQLRequest<String>(
      document: operation,
      variables: {'id': userId},
    );

    final response = await Amplify.API.query(request: request).response;
    if (response.hasErrors || response.data == null) {
      return null;
    }
    
    try {
      final Map<String, dynamic> data = jsonDecode(response.data!);
      if (data['getProfile'] == null) return null;
      return data['getProfile'] as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Search for a user by email/ID and return their profile with public key
  Future<Map<String, dynamic>?> searchUser(String identifier) async {
    final cleanId = identifier.trim();
    if (cleanId.isEmpty) return null;

    const operation = 'query ListProfiles(\$filter: ModelProfileFilterInput) { '
        'listProfiles(filter: \$filter) { items { id publicKey username } } }';
    
    final request = GraphQLRequest<String>(
      document: operation,
      variables: {
        'filter': {
          'or': [
            {'id': {'eq': cleanId}},
            {'username': {'eq': cleanId}},
          ]
        }
      },
    );

    try {
      final response = await Amplify.API.query(request: request).response;
      if (response.hasErrors) {
        debugPrint('searchUser GraphQL error: ${response.errors}');
        return null;
      }
      
      if (response.data == null) return null;

      final Map<String, dynamic> data = jsonDecode(response.data!);
      final items = data['listProfiles']?['items'] as List?;
      
      if (items == null || items.isEmpty) {
        debugPrint('searchUser: No user found for identifier: $cleanId');
        return null;
      }

      debugPrint('searchUser: Found user ${items.first['username']}');
      return items.first as Map<String, dynamic>;
    } catch (e) {
      debugPrint('searchUser exception: $e');
      return null;
    }
  }

  Future<String?> getLocalAvatarPath(String userId) async {
    if (kIsWeb) return null; // No local file system on web
    try {
      final directory = await getApplicationDocumentsDirectory();
      final avatarFile = File(p.join(directory.path, 'avatars', 'avatar_$userId.png'));
      if (await avatarFile.exists()) {
        return avatarFile.path;
      }
    } catch (e) {
      debugPrint('Error getting local avatar: $e');
    }
    return null;
  }

  Future<void> saveLocalAvatar(String userId, File imageFile) async {
    if (kIsWeb) return; 
    try {
      final directory = await getApplicationDocumentsDirectory();
      final avatarsDir = Directory(p.join(directory.path, 'avatars'));
      if (!await avatarsDir.exists()) {
        await avatarsDir.create(recursive: true);
      }
      
      final destination = File(p.join(avatarsDir.path, 'avatar_$userId.png'));
      await imageFile.copy(destination.path);
    } catch (e) {
      debugPrint('Error saving local avatar: $e');
      rethrow;
    }
  }

  // --- Base64 Avatar Support (Web & Secure Storage) ---
  
  static const String _avatarPrefix = 'cipher_avatar_base64_';
  final _secureStorage = const FlutterSecureStorage();

  Future<void> saveAvatarBase64(String userId, List<int> bytes) async {
    try {
      final base64String = base64Encode(bytes);
      await _secureStorage.write(key: '$_avatarPrefix$userId', value: base64String);
    } catch (e) {
      debugPrint('Error saving base64 avatar: $e');
    }
  }

  Future<String?> getAvatarBase64(String userId) async {
    try {
      return await _secureStorage.read(key: '$_avatarPrefix$userId');
    } catch (e) {
      debugPrint('Error reading base64 avatar: $e');
      return null;
    }
  }
}
