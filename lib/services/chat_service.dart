import 'dart:convert';
import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'encryption_service.dart';
import 'profile_service.dart';
import 'call_service.dart';

class ChatService {
  final _encryptionService = EncryptionService();
  final _profileService = ProfileService();

  // Cache for shared secrets to optimize performance
  final Map<String, SecretKey> _sharedSecretCache = {};

  // Local optimistic update stream
  static final StreamController<Map<String, dynamic>> _localMessageController = StreamController.broadcast();

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

      sharedSecret = await _encryptionService.deriveSharedSecret(remotePubKey, senderId);
      _sharedSecretCache[receiverId] = sharedSecret;
    }

    // 2. Encrypt message
    final encryptedContent = await _encryptionService.encryptMessage(
      text,
      sharedSecret,
    );

    // 3. Push to AWS Amplify (GraphQL Mutation)
    const operation = 'mutation CreateMessage(\$input: CreateMessageInput!) { '
        'createMessage(input: \$input) { id senderId receiverId content status createdAt } }';
    
    final request = GraphQLRequest<String>(
      document: operation,
      variables: {
        'input': {
          'senderId': senderId,
          'receiverId': receiverId,
          'content': encryptedContent,
          'status': 1, // Sent
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        }
      },
      authorizationMode: APIAuthorizationType.apiKey,
    );

    final response = await Amplify.API.mutate(request: request).response;
    if (response.hasErrors) {
      throw Exception('Failed to send message: \${response.errors}');
    } else if (response.data != null) {
      try {
        final decoded = jsonDecode(response.data!);
        final message = decoded['createMessage'];
        if (message != null) {
          _localMessageController.add(message);
        }
      } catch (e) {
        print('Error broadcasting local message: $e');
      }
    }
  }

  /// Fetches messages and decrypts them on the fly
  Future<List<Map<String, dynamic>>> getMessages(String otherUserId) async {
    final user = await Amplify.Auth.getCurrentUser();
    final myId = user.userId;

    const operation = 'query ListMessages(\$filter: ModelMessageFilterInput, \$nextToken: String) { '
        'listMessages(filter: \$filter, limit: 1000, nextToken: \$nextToken) { items { id senderId receiverId content status createdAt } nextToken } }';
    
    final List<Map<String, dynamic>> allItems = [];
    String? nextToken;
    
    try {
      do {
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
            },
            if (nextToken != null) 'nextToken': nextToken,
          },
          authorizationMode: APIAuthorizationType.apiKey,
        );

        final response = await Amplify.API.query(request: request).response;
        if (response.hasErrors || response.data == null) {
          break; // Stop fetching on chunk error
        }

        final decoded = jsonDecode(response.data!);
        final listMessages = decoded['listMessages'];
        if (listMessages != null) {
          final items = (listMessages['items'] as List).cast<Map<String, dynamic>>();
          allItems.addAll(items);
          nextToken = listMessages['nextToken'] as String?;
        } else {
          nextToken = null;
        }
      } while (nextToken != null);

      // Sort oldest first
      allItems.sort((a, b) => (a['createdAt'] as String).compareTo(b['createdAt'] as String));

      SecretKey? secret = _sharedSecretCache[otherUserId];
      if (secret == null) {
        final remotePubKey = await _profileService.getPublicKey(otherUserId);
        if (remotePubKey != null) {
          secret = await _encryptionService.deriveSharedSecret(remotePubKey, myId);
          _sharedSecretCache[otherUserId] = secret;
        }
      }

      for (var msg in allItems) {
        if (secret != null) {
          try {
            msg['content'] = await _encryptionService.decryptMessage(msg['content'] as String, secret);
            msg['content_decrypted'] = true;
          } catch (e) {
            msg['content'] = "[Decryption Error]";
          }
        } else {
          msg['content'] = "[Missing Key]";
        }
      }
      return allItems;
    } catch (e) {
      print('Error parsing messages: \$e');
      return [];
    }
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
              final user = await Amplify.Auth.getCurrentUser();
              secret = await _encryptionService.deriveSharedSecret(remotePubKey, user.userId);
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
      // Filter out messages that failed to decrypt
      return messages.where((m) => m['content'] != "[Decryption Error]" && m['content'] != "[Missing Key]").toList();
    });
  }

  /// Gets a stream of unique chat partners for the current user
  Stream<List<Map<String, dynamic>>> getChatListStream() {
    final controller = StreamController<List<Map<String, dynamic>>>();
    
    // Internal state to track latest messages for each contact
    final Map<String, Map<String, dynamic>> latestMessagesMap = {};

    Future<void> initialFetchAndSubscribe() async {
      final user = await Amplify.Auth.getCurrentUser();
      final myId = user.userId;

      // 1. Initial Query
      const queryDoc = 'query ListAllMyMessages(\$filter: ModelMessageFilterInput, \$nextToken: String) { '
          'listMessages(filter: \$filter, limit: 1000, nextToken: \$nextToken) { items { id senderId receiverId content status createdAt } nextToken } }';
      
      String? nextToken;
      try {
        do {
          final queryRequest = GraphQLRequest<String>(
            document: queryDoc,
            variables: {
              'filter': {
                'or': [
                  {'senderId': {'eq': myId}},
                  {'receiverId': {'eq': myId}}
                ]
              },
              if (nextToken != null) 'nextToken': nextToken,
            },
            authorizationMode: APIAuthorizationType.apiKey,
          );

          final response = await Amplify.API.query(request: queryRequest).response;
          if (!response.hasErrors && response.data != null) {
            final decoded = jsonDecode(response.data!);
            final listMessages = decoded['listMessages'];
            if (listMessages != null) {
              final items = (listMessages['items'] as List).cast<Map<String, dynamic>>();
              
              for (var msg in items) {
                final content = msg['content'] as String;
                // Skip internal contacts storage messages and call signals
                if (!content.startsWith(CallService.signalPrefix) &&
                    !content.startsWith('__cipher_contacts_v1__')) {
                  _updateLatestMessage(msg, myId, latestMessagesMap);
                }
              }
              
              nextToken = listMessages['nextToken'] as String?;
            } else {
              nextToken = null;
            }
          } else {
            break;
          }
        } while (nextToken != null);
        controller.add(_sortChats(latestMessagesMap));
      } catch (e) {
        print('Error in initial chat list fetch: $e');
      }

      // 2. Subscribe to new messages
      const subDoc = 'subscription OnCreateMessage { '
          'onCreateMessage { id senderId receiverId content status createdAt } }';
      
      final subRequest = GraphQLRequest<String>(document: subDoc, authorizationMode: APIAuthorizationType.apiKey);
      final operation = Amplify.API.subscribe(
        subRequest,
        onEstablished: () => print('Chat List Subscription established'),
      );

      operation.listen((event) {
        if (event.data != null) {
          try {
            final decoded = jsonDecode(event.data!);
            final message = decoded['onCreateMessage'];
            if (message != null) {
              if (message['senderId'] == myId || message['receiverId'] == myId) {
                final content = message['content'] as String;
                if (!content.startsWith(CallService.signalPrefix) &&
                    !content.startsWith('__cipher_contacts_v1__')) {
                  _updateLatestMessage(message, myId, latestMessagesMap);
                  controller.add(_sortChats(latestMessagesMap));
                }
              }
            }
          } catch (e) {
            print('Error parsing message subscription: $e');
          }
        }
      });

      // 3. Listen to optimistic local messages
      _localMessageController.stream.listen((message) {
        if (message['senderId'] == myId || message['receiverId'] == myId) {
          final content = message['content'] as String;
          if (!content.startsWith(CallService.signalPrefix) &&
              !content.startsWith('__cipher_contacts_v1__')) {
            _updateLatestMessage(message, myId, latestMessagesMap);
            controller.add(_sortChats(latestMessagesMap));
          }
        }
      });
    }

    initialFetchAndSubscribe();
    return controller.stream;
  }

  void _updateLatestMessage(
    Map<String, dynamic> msg,
    String myId,
    Map<String, Map<String, dynamic>> map,
  ) {
    final otherId = msg['senderId'] == myId ? msg['receiverId'] : msg['senderId'];
    if (!map.containsKey(otherId)) {
      map[otherId as String] = msg;
    } else {
      final currentAt = DateTime.parse(map[otherId]!['createdAt'] as String);
      final newAt = DateTime.parse(msg['createdAt'] as String);
      if (newAt.isAfter(currentAt)) {
        map[otherId as String] = msg;
      }
    }
  }

  List<Map<String, dynamic>> _sortChats(Map<String, Map<String, dynamic>> map) {
    final list = map.values.map((msg) => {
      'id': msg['id'],
      'sender_id': msg['senderId'],
      'receiver_id': msg['receiverId'],
      'created_at': msg['createdAt'],
      'content': msg['content'],
    }).toList();
    
    list.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return list;
  }

  /// Real-time decrypted chat list
  Stream<List<Map<String, dynamic>>> getDecryptedChatListStream() {
    return getChatListStream().asyncMap((chats) async {
      for (var chat in chats) {
        final otherId = chat['sender_id'] == chat['receiver_id'] 
            ? chat['sender_id'] // Should not happen in a real app but for robustness
            : (chat['sender_id'] == (await Amplify.Auth.getCurrentUser()).userId 
                ? chat['receiver_id'] 
                : chat['sender_id']);

        try {
          SecretKey? secret = _sharedSecretCache[otherId];
          if (secret == null) {
            final remotePubKey = await _profileService.getPublicKey(otherId);
            if (remotePubKey != null) {
              final user = await Amplify.Auth.getCurrentUser();
              secret = await _encryptionService.deriveSharedSecret(remotePubKey, user.userId);
              _sharedSecretCache[otherId] = secret;
            }
          }

          if (secret != null) {
            chat['content'] = await _encryptionService.decryptMessage(
              chat['content'],
              secret,
            );
            chat['is_decrypted'] = true;
          }
        } catch (e) {
          chat['content'] = "[Encrypted]";
          chat['is_decrypted'] = false;
        }
      }
      return chats;
    });
  }

  /// Real-time stream of messages for a specific conversation
  Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    final controller = StreamController<List<Map<String, dynamic>>>();
    final List<Map<String, dynamic>> accumulatedMessages = [];

    Future<void> run() async {
      final user = await Amplify.Auth.getCurrentUser();
      final myId = user.userId;

      // 1. Fetch historical messages
      final historical = await getMessages(otherUserId);
      
      // Auto-ACK for historical messages from other user
      for (var msg in historical) {
        if (msg['senderId'] == otherUserId && (msg['status'] == null || msg['status'] == 1)) {
          markAsDelivered(msg['id']);
        }
      }

      accumulatedMessages.addAll(historical);
      controller.add(List.from(accumulatedMessages));

      // 2. Subscribe to new messages
      const subscriptionDocument = 'subscription OnCreateMessage { '
          'onCreateMessage { id senderId receiverId content status createdAt } }';
      
      final subscriptionRequest = GraphQLRequest<String>(
        document: subscriptionDocument,
        authorizationMode: APIAuthorizationType.apiKey,
      );

      final operation = Amplify.API.subscribe(
        subscriptionRequest,
        onEstablished: () => print('Message Subscription established for $otherUserId'),
      );

      operation.listen((event) {
        if (event.data != null) {
          try {
            final decoded = jsonDecode(event.data!);
            final message = decoded['onCreateMessage'];
            if (message != null) {
              // Only add if it belongs to THIS conversation
              final isFromOther = message['senderId'] == otherUserId && message['receiverId'] == myId;
              final isFromMe = message['senderId'] == myId && message['receiverId'] == otherUserId;
              
              if (isFromOther || isFromMe) {
                final content = message['content'] as String;
                if (!content.startsWith(CallService.signalPrefix) &&
                    !content.startsWith('__cipher_contacts_v1__')) {
                  
                  // Auto-ACK for incoming messages
                  if (isFromOther && (message['status'] == null || message['status'] == 1)) {
                    markAsDelivered(message['id']);
                  }

                  if (!accumulatedMessages.any((m) => m['id'] == message['id'])) {
                    accumulatedMessages.add(message);
                    accumulatedMessages.sort((a, b) => (a['createdAt'] as String).compareTo(b['createdAt'] as String));
                    controller.add(List.from(accumulatedMessages));
                  }
                }
              }
            }
          } catch (e) {
            print('Error parsing subscription event: $e');
          }
        }
      });

      // 4. Listen to optimistic local messages
      _localMessageController.stream.listen((message) {
        final isFromOther = message['senderId'] == otherUserId && message['receiverId'] == myId;
        final isFromMe = message['senderId'] == myId && message['receiverId'] == otherUserId;
        
        if (isFromOther || isFromMe) {
          final content = message['content'] as String;
          if (!content.startsWith(CallService.signalPrefix) &&
              !content.startsWith('__cipher_contacts_v1__')) {
            if (!accumulatedMessages.any((m) => m['id'] == message['id'])) {
              accumulatedMessages.add(message);
              accumulatedMessages.sort((a, b) => (a['createdAt'] as String).compareTo(b['createdAt'] as String));
              controller.add(List.from(accumulatedMessages));
            }
          }
        }
      });

      // 5. Subscribe to message UPDATES (for Status changes)
      const updateSubDoc = 'subscription OnUpdateMessage { '
          'onUpdateMessage { id senderId receiverId content status createdAt } }';
      
      final updateSubRequest = GraphQLRequest<String>(
        document: updateSubDoc,
        authorizationMode: APIAuthorizationType.apiKey,
      );

      final updateOperation = Amplify.API.subscribe(updateSubRequest);
      updateOperation.listen((event) {
        if (event.data != null) {
          try {
            final decoded = jsonDecode(event.data!);
            final updatedMsg = decoded['onUpdateMessage'];
            if (updatedMsg != null) {
              final index = accumulatedMessages.indexWhere((m) => m['id'] == updatedMsg['id']);
              if (index != -1) {
                // If we already have a decrypted version, keep it to avoid flicker
                final existing = accumulatedMessages[index];
                if (existing['content_decrypted'] == true) {
                  updatedMsg['content'] = existing['content'];
                  updatedMsg['content_decrypted'] = true;
                }
                
                accumulatedMessages[index] = updatedMsg;
                controller.add(List.from(accumulatedMessages));
              }
            }
          } catch (e) {
            print('Error parsing update subscription: $e');
          }
        }
      });
    }

    run();
    return controller.stream;
  }

  /// Marks a message as delivered
  Future<void> markAsDelivered(String messageId) async {
    const operation = 'mutation UpdateMessage(\$input: UpdateMessageInput!) { '
        'updateMessage(input: \$input) { id status } }';
    
    final request = GraphQLRequest<String>(
      document: operation,
      variables: {
        'input': { 'id': messageId, 'status': 2 }
      },
      authorizationMode: APIAuthorizationType.apiKey,
    );

    try {
      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) {
        debugPrint('Failed to mark as delivered: ${response.errors}');
      }
    } catch (e) {
      debugPrint('Error marking as delivered: $e');
    }
  }

  /// Deletes a message for both users
  Future<void> deleteMessage(String messageId) async {
    const operation = 'mutation DeleteMessage(\$input: DeleteMessageInput!) { '
        'deleteMessage(input: \$input) { id } }';
    
    final request = GraphQLRequest<String>(
      document: operation,
      variables: {
        'input': { 'id': messageId }
      },
      authorizationMode: APIAuthorizationType.apiKey,
    );

    final response = await Amplify.API.mutate(request: request).response;
    if (response.hasErrors) {
      throw Exception('Failed to delete message: ${response.errors}');
    }
  }
}
