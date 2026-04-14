import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter/foundation.dart';

class CallService {
  static const String signalPrefix = "_SIGNAL_";
  
  Future<void> startCall({
    required String receiverId,
    required String receiverName,
    required String channelId,
    required String callerName,
    bool isAudioOnly = false,
  }) async {
    final user = await Amplify.Auth.getCurrentUser();
    final senderId = user.userId;

    final type = isAudioOnly ? 'audio' : 'video';
    final signalContent = "$signalPrefix:CALL_REQUEST|$channelId|$callerName|$type";

    const operation = 'mutation CreateMessage(\$input: CreateMessageInput!) { '
        'createMessage(input: \$input) { id senderId receiverId content createdAt } }';
    
    final request = GraphQLRequest<String>(
      document: operation,
      variables: {
        'input': {
          'senderId': senderId,
          'receiverId': receiverId,
          'content': signalContent,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        }
      },
      authorizationMode: APIAuthorizationType.apiKey,
    );

    try {
      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) {
        debugPrint('Failed to send call signal: ${response.errors}');
      } else {
        debugPrint('Call signal sent to $receiverId');
      }
    } catch (e) {
      debugPrint('Error sending call signal: $e');
    }
  }

  Future<void> sendResponse({
    required String receiverId,
    required String responseType, // CALL_ACCEPTED or CALL_REJECTED
    required String channelId,
  }) async {
    final user = await Amplify.Auth.getCurrentUser();
    final senderId = user.userId;
    final signalContent = "$signalPrefix:\$responseType|\$channelId";

    const operation = 'mutation CreateMessage(\$input: CreateMessageInput!) { '
        'createMessage(input: \$input) { id senderId receiverId content createdAt } }';
    
    final request = GraphQLRequest<String>(
      document: operation,
      variables: {
        'input': {
          'senderId': senderId,
          'receiverId': receiverId,
          'content': signalContent,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        }
      },
      authorizationMode: APIAuthorizationType.apiKey,
    );

    await Amplify.API.mutate(request: request).response;
  }
}
