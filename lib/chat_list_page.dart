import 'dart:ui';
import 'package:flutter/material.dart';
import 'chat_detail_page.dart';
import 'vault_page.dart';
import 'calls_page.dart';
import 'settings_page.dart';
import 'services/profile_service.dart';
import 'services/chat_service.dart';
import 'services/auth_service.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:intl/intl.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _profileService = ProfileService();
  final _chatService = ChatService();
  final _authService = AuthService();

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day &&
        time.month == now.month &&
        time.year == now.year) {
      return DateFormat('hh:mm a').format(time);
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('EEEE').format(time);
    } else {
      return DateFormat('MMM dd').format(time);
    }
  }

  void _showSearchDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2210),
        title: const Text(
          'New Secure Chat',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter User ID or Email',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFBEF263)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBEF263),
            ),
            onPressed: () async {
              final identifier = controller.text.trim();
              if (identifier.isEmpty) return;

              final profile = await _profileService.searchUser(identifier);
              if (profile != null && mounted) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailPage(
                      receiverId: profile['id'],
                      receiverName: profile['username'] ?? profile['email'] ?? 'Secure Contact',
                    ),
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User not found or no public key'),
                  ),
                );
              }
            },
            child: const Text(
              'Start Chat',
              style: TextStyle(color: Color(0xFF1B2210)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2210), // background-dark
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF1B2210,
        ).withValues(alpha: 0.8), // background-dark/80
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0x1ABEF263), width: 1),
        ), // border-primary/10
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0x33BEF263), // primary/20
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security, color: Color(0xFFBEF263)),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cipher',
              style: TextStyle(
                color: Color(0xFFF1F5F9), // text-slate-100
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_comment_outlined,
              color: Color(0xFFBEF263),
            ),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF94A3B8),
            ), // text-slate-400
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBEF263), width: 2),
                image: const DecorationImage(
                  image: NetworkImage(
                    "https://lh3.googleusercontent.com/aida-public/AB6AXuBltbzKsqtx_dh5NrnY-ExLykKAkKpQC3RhnsKZ48m4XUnmWOt2R-MUKIB3ZeTr8GDfOfdOP9sMHnDZg1qeWSAManOJ8m4cL4a5_qR8Y8cJhBksKjhzaC8F00J-Z8oryoApgg5bkTkyz1jI7adhzQ3-xAsz1OelBSqylDFlWgXm60Q9_JpK7d9T_GvU4C8p1Dm6M6nkBLCw7GqPlmFKwd_jWNXRNJHdK2HkrEaXJN7QLrWRVPBQM1xuyMsEDPweMw4bvjQ63ZCkUnY",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Search Bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0x0DBEF263), // primary/5
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 8.0),
                        child: Icon(
                          Icons.search,
                          color: Color(0x99BEF263),
                        ), // primary/60
                      ),
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: Color(0xFFF1F5F9)),
                          decoration: InputDecoration(
                            hintText: 'Search secure threads',
                            hintStyle: TextStyle(
                              color: const Color(
                                0xFFBEF263,
                              ).withValues(alpha: 0.4),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Filters
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip(
                        'All Chats',
                        true,
                        icon: Icons.keyboard_arrow_down,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('Unread', false),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Hide Hidden',
                        false,
                        icon: Icons.visibility_off,
                        isIconFirst: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<AuthUser?>(
        future: _authService.currentUser,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final myId = userSnapshot.data?.userId;

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _chatService.getChatListStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final chats = snapshot.data ?? [];
              if (chats.isEmpty) {
                return const Center(
                  child: Text(
                    'No secure conversations yet.\nTap + to start one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final otherId = chat['sender_id'] == myId
                      ? chat['receiver_id']
                      : chat['sender_id'];

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _profileService.searchUser(otherId),
                    builder: (context, profSnapshot) {
                      final profile = profSnapshot.data;
                      final name = profile?['email'] ?? 'Secure Contact';
                      final time =
                          DateTime.tryParse(chat['created_at'])?.toLocal() ??
                          DateTime.now();
                      final displayTime = _formatTime(time);

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailPage(
                                receiverId: otherId,
                                receiverName: name,
                              ),
                            ),
                          );
                        },
                        child: _buildChatListItem(
                          name: name,
                          time: displayTime,
                          isEncrypted: true,
                          message: 'Encrypted transmission',
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFFBEF263),
          elevation: 8,
          child: const Icon(
            Icons.add_moderator,
            color: Color(0xFF1B2210),
            size: 28,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1B2210),
          border: Border(top: BorderSide(color: Color(0x1ABEF263), width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem('Chats', Icons.chat_bubble, true, () {}),
            _buildNavItem('Calls', Icons.call, false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CallsPage()),
              );
            }),
            _buildNavItem('Vault', Icons.key, false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const VaultPage()),
              );
            }),
            _buildNavItem('Settings', Icons.settings, false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected, {
    IconData? icon,
    bool isIconFirst = false,
  }) {
    List<Widget> children = [
      Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF1B2210) : const Color(0xFFBEF263),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ];

    if (icon != null) {
      Widget iconWidget = Icon(
        icon,
        size: 18,
        color: isSelected ? const Color(0xFF1B2210) : const Color(0xFFBEF263),
      );
      if (isIconFirst) {
        children.insert(0, iconWidget);
        children.insert(1, const SizedBox(width: 4));
      } else {
        children.add(const SizedBox(width: 4));
        children.add(iconWidget);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFBEF263) : const Color(0x1ABEF263),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildChatListItem({
    required String name,
    required String time,
    String? message,
    bool isEncrypted = false,
    int unreadCount = 0,
    String? imageUrl,
    bool isSelfDestructed = false,
    bool isGhost = false,
    bool isGroup = false,
    bool isBorderTransparent = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isGhost ? null : Colors.transparent, // add hover effect later
      ),
      child: Opacity(
        opacity: isGhost ? 0.6 : 1.0,
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isBorderTransparent
                          ? Colors.transparent
                          : const Color(0x33BEF263),
                      width: 2,
                    ),
                    color: isGroup
                        ? const Color(0x1ABEF263)
                        : Colors.transparent,
                    image: imageUrl != null && !isGroup
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: isGroup
                      ? const Icon(
                          Icons.group,
                          color: Color(0xFFBEF263),
                          size: 32,
                        )
                      : null,
                ),
                if (!isGhost)
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBEF263),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1B2210),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Color(0xFF1B2210),
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: const Color(0xFFF1F5F9), // text-slate-100
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontStyle: isGhost
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                          if (isGhost) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.visibility_off,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Color(0x66BEF263), // primary/40
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (isEncrypted)
                    Row(
                      children: const [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Color(0xFFBEF263),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Encrypted message',
                          style: TextStyle(
                            color: Color(0xFFBEF263),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else if (isSelfDestructed)
                    Row(
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 14,
                          color: const Color(0xFFBEF263).withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          message ?? '',
                          style: TextStyle(
                            color: const Color(
                              0xFFBEF263,
                            ).withValues(alpha: 0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      message ?? '',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8), // text-slate-400
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFBEF263),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Color(0xFF1B2210), // background-dark
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? const Color(0xFFBEF263)
                : const Color(0xFFBEF263).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFBEF263)
                  : const Color(0xFFBEF263).withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
