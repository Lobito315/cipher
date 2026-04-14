import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'services/chat_service.dart';
import 'services/auth_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'call_page.dart';
import 'services/call_service.dart';
import 'services/profile_service.dart';
import 'services/contact_service.dart';
import 'models/contact.dart';
import 'package:amplify_flutter/amplify_flutter.dart' as amplify;

class ChatDetailPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatDetailPage({
    super.key,
    required this.receiverId,
    this.receiverName = 'Secure Contact',
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _chatService = ChatService();
  final _messageController = TextEditingController();
  final _authService = AuthService();
  final _callService = CallService();
  final _profileService = ProfileService();
  final _contactService = ContactService();

  String? _myAvatarBase64;
  String? _receiverAvatarBase64;

  @override
  void initState() {
    super.initState();
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    final user = await _authService.currentUser;
    if (user != null) {
      final myAvatar = await _profileService.getAvatarBase64(user.userId);
      setState(() {
        _myAvatarBase64 = myAvatar;
      });
    }

    final contacts = await _contactService.getContacts();
    final receiverContact = contacts.firstWhere(
      (c) => c.userId == widget.receiverId,
      orElse: () => Contact(
        userId: widget.receiverId,
        username: widget.receiverName,
        addedAt: DateTime.now(),
      ),
    );
    if (receiverContact.avatarBase64 != null) {
      setState(() {
        _receiverAvatarBase64 = receiverContact.avatarBase64;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    try {
      await _chatService.sendMessage(receiverId: widget.receiverId, text: text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRedactDialog(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B2210),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              title: const Text(
                'Redact Message',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Permanently remove this message for all participants.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await _chatService.deleteMessage(messageId);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to redact: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthUser?>(
      future: _authService.currentUser,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1B2210),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFBEF263))),
          );
        }
        final myId = userSnapshot.data?.userId;

        return Scaffold(
          backgroundColor: const Color(0xFF1B2210), // dark:bg-background-dark
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B2210).withOpacity(0.8),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFF1F5F9)),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBEF263).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFBEF263).withOpacity(0.3),
                    ),
                    image: _receiverAvatarBase64 != null
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(_receiverAvatarBase64!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _receiverAvatarBase64 == null
                      ? const Icon(Icons.person, color: Color(0xFFBEF263))
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.receiverName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF1F5F9),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Row(
                      children: [
                        Text(
                          'ACTIVE PROTOCOL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBEF263),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
             actions: [
              IconButton(
                icon: const Icon(Icons.call_outlined, color: Color(0xFFBEF263)),
                onPressed: () async {
                  final channelId = "call_${DateTime.now().millisecondsSinceEpoch}";
                  // Get caller's display name from their profile
                  final user = await amplify.Amplify.Auth.getCurrentUser();
                  final myProfile = await _profileService.getFullProfile(user.userId);
                  final callerName = myProfile?['username'] ?? user.username;
                  await _callService.startCall(
                    receiverId: widget.receiverId,
                    receiverName: widget.receiverName,
                    channelId: channelId,
                    callerName: callerName,
                    isAudioOnly: true,
                  );
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CallPage(
                          channelName: channelId,
                          remoteUserName: widget.receiverName,
                          isAudioOnly: true,
                        ),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.videocam_outlined, color: Color(0xFFBEF263)),
                onPressed: () async {
                  final channelId = "call_${DateTime.now().millisecondsSinceEpoch}";
                  final user = await amplify.Amplify.Auth.getCurrentUser();
                  final myProfile = await _profileService.getFullProfile(user.userId);
                  final callerName = myProfile?['username'] ?? user.username;
                  await _callService.startCall(
                    receiverId: widget.receiverId,
                    receiverName: widget.receiverName,
                    channelId: channelId,
                    callerName: callerName,
                    isAudioOnly: false,
                  );
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CallPage(
                          channelName: channelId,
                          remoteUserName: widget.receiverName,
                          isAudioOnly: false,
                        ),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.shield_outlined, color: Color(0xFF38BDF8)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFFF1F5F9)),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Quantum-Safe notification
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBEF263).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFBEF263).withOpacity(0.1),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock, size: 14, color: Color(0xFFBEF263)),
                          SizedBox(width: 8),
                          Text(
                            'E2EE ENCRYPTION ACTIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFBEF263),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Messages area
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _chatService.getDecryptedMessagesStream(
                    widget.receiverId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final messages = (snapshot.data ?? []).where((m) => 
                      !(m['content'] as String).startsWith(CallService.signalPrefix)
                    ).toList();
                    
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No secure messages yet.',
                          style: TextStyle(color: Colors.white24),
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true, // Show latest at bottom
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[messages.length - 1 - index];
                        final isMe = (msg['senderId'] ?? msg['sender_id']) == myId;
                        final time =
                            DateTime.tryParse(msg['createdAt'] ?? msg['created_at'] ?? '')?.toLocal() ??
                            DateTime.now();

                        return _MessageBubble(
                          text: msg['content'],
                          isMe: isMe,
                          time: DateFormat('HH:mm').format(time),
                          avatarBase64: isMe ? _myAvatarBase64 : _receiverAvatarBase64,
                          onLongPress: () {
                            _showRedactDialog(msg['id']);
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // Bottom Input Area
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2210),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFBEF263).withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFBEF263).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.enhanced_encryption,
                              color: Color(0xFFBEF263),
                              size: 18,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(
                                  color: Color(0xFFF1F5F9),
                                  fontSize: 14,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Secure message...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                maxLines: 4,
                                minLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBEF263),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF1B2210),
                          size: 20,
                        ),
                        onPressed: _handleSendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;
  final String? avatarBase64;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.time,
    this.avatarBase64,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                image: avatarBase64 != null
                    ? DecorationImage(
                        image: MemoryImage(base64Decode(avatarBase64!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarBase64 == null
                  ? const Icon(
                      Icons.person,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ] else ...[
            const SizedBox(width: 40), // Placeholder to keep alignment (32px icon + 8px space)
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFFBEF263)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe
                            ? const Radius.circular(16)
                            : const Radius.circular(4),
                        bottomRight: isMe
                            ? const Radius.circular(4)
                            : const Radius.circular(16),
                      ),
                      border: !isMe && text.contains("[Decryption Error]")
                        ? Border.all(color: Colors.redAccent.withOpacity(0.3))
                        : null,
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isMe
                            ? const Color(0xFF1B2210) // Dark on Neon Green
                            : (text.contains("[Decryption Error]") 
                                ? Colors.redAccent 
                                : const Color(0xFF38BDF8)), // Sky Blue on Dark Slate
                        fontSize: 14,
                        fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8), // Spacer to avoid edge
        ],
      ),
    );
  }
}
