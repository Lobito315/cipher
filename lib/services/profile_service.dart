import 'package:amplify_flutter/amplify_flutter.dart';

class ProfileService {
  Future<void> updatePublicKey(String userId, String publicKeyBase64) async {
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
      throw Exception('Failed to update public key: \${response.errors}');
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
    
    // Parse response data manually since we use String request
    // In a full implementation, you'd use generated models
    return response.data; // This is a simplified placeholder
  }

  /// Search for a user by email/ID and return their profile with public key
  Future<Map<String, dynamic>?> searchUser(String identifier) async {
    const operation = 'query ListProfiles(\$filter: ModelProfileFilterInput) { '
        'listProfiles(filter: \$filter) { items { id publicKey username } } }';
    
    final request = GraphQLRequest<String>(
      document: operation,
      variables: {
        'filter': {
          'or': [
            {'id': {'eq': identifier}},
            {'username': {'eq': identifier}},
          ]
        }
      },
    );

    final response = await Amplify.API.query(request: request).response;
    if (response.hasErrors || response.data == null) {
      return null;
    }
    
    // This part requires actual JSON parsing of the response.data string
    return null; // Placeholder for now
  }
}
