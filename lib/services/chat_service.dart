import 'dart:convert';
import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:cryptography/cryptography.dart';
import 'encryption_service.dart';
import 'profile_service.dart';

class ChatService {
  final _encryptionService = EncryptionService();
  final _profileService = ProfileService();

  // Cache for shared secrets to optimize performance
  final Map<String, SecretKey> _sharedSecretCache = {};

  /// Sends an E2EE message to a specific user
  Future<void> sendMessage({
    required String receiverId,
    required String text,
  }) async {
    final user = await Amplify.Auth.getCurrentUser();
    final senderId = user.userId;

    // 1. Get or derive shared secret
    SecretKey? sharedSecret = _sharedSecretCache[receiverId];
    if (sharedSecret == null) {
      final remotePubKey = await _profileService.getPublicKey(receiverId);
      if (remotePubKey == null) throw Exception("Receiver has no public key");

      sharedSecret = await _encryptionService.deriveSharedSecret(remotePubKey);
      _sharedSecretCache[receiverId] = sharedSecret;
    }

    // 2. Encrypt message
    final encryptedContent = await _encryptionService.encryptMessage(
      text,
      sharedSecret,
    );

    // 3. Push to AWS Amplify (GraphQL Mutation)
    const operation = 'mutation CreateMessage(\$input: CreateMessageInput!) { '
        'createMessage(input: \$input) { id } }';
    
    final request = GraphQLRequest<String>(
      document: operation,
      variables: {
        'input': {
          'senderId': senderId,
          'receiverId': receiverId,
          'content': encryptedContent,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        }
      },
    );

    final response = await Amplify.API.mutate(request: request).response;
    if (response.hasErrors) {
      throw Exception('Failed to send message: \${response.errors}');
    }
  }

  /// Fetches messages and decrypts them on the fly
  Future<List<Map<String, dynamic>>> getMessages(String otherUserId) async {
    final user = await Amplify.Auth.getCurrentUser();
    final myId = user.userId;

    const operation = 'query ListMessages(\$filter: ModelMessageFilterInput) { '
        'listMessages(filter: \$filter) { items { id senderId receiverId content createdAt } } }';
    
    final request = GraphQLRequest<String>(
      document: operation,
      variables: {
        'filter': {
          'or': [
            {
              'and': [
                {'senderId': {'eq': myId}},
                {'receiverId': {'eq': otherUserId}}
              ]
            },
            {
              'and': [
                {'senderId': {'eq': otherUserId}},
                {'receiverId': {'eq': myId}}
              ]
            }
          ]
        }
      },
    );

    final response = await Amplify.API.query(request: request).response;
    if (response.hasErrors || response.data == null) {
      return [];
    }

    // Decrypt all messages logic would go here
    return [];
  }

  /// Real-time stream of messages with on-the-fly decryption
  Stream<List<Map<String, dynamic>>> getDecryptedMessagesStream(
    String otherUserId,
  ) {
    return getMessagesStream(otherUserId).asyncMap((messages) async {
      for (var msg in messages) {
        if (msg['content_decrypted'] != null) continue;

        try {
          SecretKey? secret = _sharedSecretCache[otherUserId];
          if (secret == null) {
            final remotePubKey = await _profileService.getPublicKey(otherUserId);
            if (remotePubKey != null) {
              secret = await _encryptionService.deriveSharedSecret(remotePubKey);
              _sharedSecretCache[otherUserId] = secret;
            }
          }

          if (secret != null) {
            msg['content'] = await _encryptionService.decryptMessage(
              msg['content'],
              secret,
            );
            msg['content_decrypted'] = true;
          }
        } catch (e) {
          msg['content'] = "[Decryption Error]";
        }
      }
      return messages;
    });
  }

  /// Gets a stream of unique chat partners for the current user
  Stream<List<Map<String, dynamic>>> getChatListStream() {
    return const Stream.empty();
  }

  /// Real-time stream of messages for a specific conversation
  Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    const subscriptionDocument = 'subscription OnCreateMessage { '
        'onCreateMessage { id senderId receiverId content createdAt } }';
    
    final subscriptionRequest = GraphQLRequest<String>(
      document: subscriptionDocument,
    );

    final operation = Amplify.API.subscribe(
      subscriptionRequest,
      onEstablished: () => print('Subscription established'),
    );

    final controller = StreamController<List<Map<String, dynamic>>>();
    final List<Map<String, dynamic>> accumulatedMessages = [];

    operation.listen((event) {
      if (event.data != null) {
        try {
          final decoded = jsonDecode(event.data!);
          final message = decoded['onCreateMessage'];
          if (message != null) {
            if (message['senderId'] == otherUserId || message['receiverId'] == otherUserId) {
              accumulatedMessages.add(message);
              controller.add(List.from(accumulatedMessages));
            }
          }
        } catch (e) {
          print('Error parsing subscription event: \$e');
        }
      }
    });

    return controller.stream;
  }
}
