import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'services/chat_service.dart';
import 'services/auth_service.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthUser?>(
      future: _authService.currentUser,
      builder: (context, userSnapshot) {
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
                  ),
                  child: const Icon(Icons.person, color: Color(0xFFBEF263)),
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

                    final messages = snapshot.data ?? [];
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
                        final isMe = msg['sender_id'] == myId;
                        final time =
                            DateTime.tryParse(msg['createdAt'] ?? msg['created_at'])?.toLocal() ??
                            DateTime.now();

                        return _MessageBubble(
                          text: msg['content'],
                          isMe: isMe,
                          time: DateFormat('HH:mm').format(time),
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

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
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
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe
                          ? const Color(0xFF1B2210)
                          : const Color(0xFFF1F5F9),
                      fontSize: 14,
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
          if (isMe) const SizedBox(width: 8), // Spacer to avoid edge
        ],
      ),
    );
  }
}
