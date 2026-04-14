import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../services/call_service.dart';
import '../services/contact_service.dart';

/// Represents a single incoming chat notification.
class ChatNotification {
  final String senderId;
  final String senderName;
  final String messagePreview; // never shows decrypted content — privacy first
  final DateTime receivedAt;

  const ChatNotification({
    required this.senderId,
    required this.senderName,
    required this.messagePreview,
    required this.receivedAt,
  });
}

class ChatNotificationProvider extends ChangeNotifier {
  ChatNotification? _pending;
  StreamSubscription? _subscription;

  // The ID of the chat the user currently has OPEN — notifications from this
  // sender are suppressed so the user isn't disturbed mid-conversation.
  String? activeChatWithUserId;

  ChatNotification? get pending => _pending;

  void init() async {
    if (_subscription != null) return;

    final user = await Amplify.Auth.getCurrentUser();
    final myId = user.userId;

    // Pre-load contacts for fast name resolution
    final contacts = await ContactService().getContacts();
    final contactMap = {for (final c in contacts) c.userId: c.displayName};

    const subDoc = 'subscription OnCreateMessage { '
        'onCreateMessage { id senderId receiverId content createdAt } }';

    final subRequest = GraphQLRequest<String>(
      document: subDoc,
      authorizationMode: APIAuthorizationType.apiKey,
    );

    _subscription = Amplify.API.subscribe(subRequest).listen((event) {
      if (event.data == null) return;
      try {
        final decoded = jsonDecode(event.data!);
        final message = decoded['onCreateMessage'];
        if (message == null) return;

        final receiverId = message['receiverId'] as String?;
        final senderId = message['senderId'] as String?;
        final content = message['content'] as String? ?? '';

        // Only handle messages addressed to me
        if (receiverId != myId) return;

        // Ignore system signals (calls, contact storage, etc.)
        if (content.startsWith(CallService.signalPrefix)) return;
        if (content.startsWith('__cipher_')) return;
        // Ignore self-sent messages (contact persistence)
        if (senderId == myId) return;

        // Suppress if user is already in this conversation
        if (senderId == activeChatWithUserId) return;

        // Resolve sender name from contacts, fall back to "Unknown"
        final senderName = contactMap[senderId] ?? 'Unknown';

        _pending = ChatNotification(
          senderId: senderId ?? '',
          senderName: senderName,
          messagePreview: '🔒 Encrypted message',
          receivedAt: DateTime.now(),
        );
        notifyListeners();
      } catch (e) {
        debugPrint('ChatNotificationProvider error: $e');
      }
    });

    debugPrint('ChatNotificationProvider: listening for messages');
  }

  void dismiss() {
    _pending = null;
    notifyListeners();
  }

  Future<void> reset() async {
    await _subscription?.cancel();
    _subscription = null;
    _pending = null;
    activeChatWithUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
