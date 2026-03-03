import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'encryption_service.dart';
import 'profile_service.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _encryptionService = EncryptionService();
  final _profileService = ProfileService();

  // Cache for shared secrets to optimize performance
  final Map<String, SecretKey> _sharedSecretCache = {};

  /// Sends an E2EE message to a specific user
  Future<void> sendMessage({
    required String receiverId,
    required String text,
  }) async {
    final senderId = _supabase.auth.currentUser?.id;
    if (senderId == null) throw Exception("User not authenticated");

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

    // 3. Push to Supabase
    await _supabase.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': encryptedContent,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetches messages and decrypts them on the fly
  Future<List<Map<String, dynamic>>> getMessages(String otherUserId) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return [];

    final response = await _supabase
        .from('messages')
        .select()
        .or(
          'and(sender_id.eq.$myId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$myId)',
        )
        .order('created_at', ascending: true);

    final List<Map<String, dynamic>> messages = List<Map<String, dynamic>>.from(
      response,
    );

    // Decrypt all messages
    for (var msg in messages) {
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
        }
      } catch (e) {
        msg['content'] = "[Decryption Error]";
      }
    }

    return messages;
  }

  /// Real-time stream of messages with on-the-fly decryption
  Stream<List<Map<String, dynamic>>> getDecryptedMessagesStream(
    String otherUserId,
  ) {
    return getMessagesStream(otherUserId).asyncMap((messages) async {
      for (var msg in messages) {
        if (msg['content_decrypted'] != null) continue; // Skip if already done

        try {
          SecretKey? secret = _sharedSecretCache[otherUserId];
          if (secret == null) {
            final remotePubKey = await _profileService.getPublicKey(
              otherUserId,
            );
            if (remotePubKey != null) {
              secret = await _encryptionService.deriveSharedSecret(
                remotePubKey,
              );
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
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return Stream.value([]);

    // This is a bit complex in Supabase real-time without a view,
    // but we can listen to all messages involving me and group them in the app for now.
    return _supabase.from('messages').stream(primaryKey: ['id']).map((data) {
      final Map<String, Map<String, dynamic>> chats = {};

      for (var m in data) {
        if (m['sender_id'] != myId && m['receiver_id'] != myId) continue;

        final otherId = m['sender_id'] == myId
            ? m['receiver_id']
            : m['sender_id'];

        // Keep the latest message for each partner
        if (!chats.containsKey(otherId) ||
            DateTime.parse(
              m['created_at'],
            ).isAfter(DateTime.parse(chats[otherId]!['created_at']))) {
          chats[otherId] = m;
        }
      }

      // Convert to list and sort by date descending
      final chatList = chats.values.toList();
      chatList.sort(
        (a, b) => DateTime.parse(
          b['created_at'],
        ).compareTo(DateTime.parse(a['created_at'])),
      );
      return chatList;
    });
  }

  /// Real-time stream of messages for a specific conversation
  Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return Stream.value([]);

    // Note: In a production app, you'd want to decrypt the new incoming messages in the stream.
    // For this implementation, we handle decryption in the UI or via a transformer.
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map(
          (data) => data
              .where(
                (m) =>
                    (m['sender_id'] == myId &&
                        m['receiver_id'] == otherUserId) ||
                    (m['sender_id'] == otherUserId && m['receiver_id'] == myId),
              )
              .toList(),
        );
  }
}
