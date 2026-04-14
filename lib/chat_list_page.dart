import 'dart:ui';
import 'package:flutter/material.dart';
import 'chat_detail_page.dart';
import 'vault_page.dart';
import 'calls_page.dart';
import 'settings_page.dart';
import 'contacts_page.dart';
import 'services/profile_service.dart';
import 'services/chat_service.dart';
import 'services/auth_service.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'services/encryption_service.dart';
import 'services/contact_service.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'contacts_page.dart';
import 'models/contact.dart';
import 'package:provider/provider.dart';
import 'providers/call_provider.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _profileService = ProfileService();
  final _contactService = ContactService();
  final _chatService = ChatService();
  final _authService = AuthService();
  final _encryptionService = EncryptionService();
  final Map<String, Map<String, dynamic>?> _profileCache = {};
  String? _myAvatarBase64;
  Map<String, String?> _contactAvatars = {};

  String _searchQuery = '';
  String _selectedFilter = 'All Chats';

  @override
  void initState() {
    super.initState();
    _loadMyAvatar();
    _loadContactAvatars();
    // Initialize call subscription now that user is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<CallProvider>(context, listen: false).init();
      }
    });
  }

  Future<void> _loadMyAvatar() async {
    final user = await _authService.currentUser;
    if (user != null) {
      final b64 = await _profileService.getAvatarBase64(user.userId);
      if (mounted) setState(() => _myAvatarBase64 = b64);
    }
  }

  Future<void> _loadContactAvatars() async {
    final contacts = await _contactService.getContacts();
    final Map<String, String?> avatars = {};
    for (var c in contacts) {
      if (c.avatarBase64 != null) {
        avatars[c.userId] = c.avatarBase64;
      }
    }
    if (mounted) setState(() => _contactAvatars = avatars);
  }

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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search by email address or technical UUID.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'user@example.com or ID...',
                hintStyle: TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFBEF263)),
                ),
              ),
            ),
          ],
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
                
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1B2210),
                    title: Text(profile['username'] ?? profile['email'] ?? 'User Found'),
                    content: const Text('Would you like to start a chat or save this user to your contacts?'),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          await ContactService().addContact(profile);
                          if (context.mounted) Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to contacts')),
                          );
                        },
                        child: const Text('Save Contact', style: TextStyle(color: Color(0xFFBEF263))),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBEF263)),
                        onPressed: () {
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
                        },
                        child: const Text('Start Chat', style: TextStyle(color: Color(0xFF1B2210))),
                      ),
                    ],
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
              'Search',
              style: TextStyle(color: Color(0xFF1B2210)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSecurityStatus() async {
    final user = await _authService.currentUser;
    if (user == null) return;
    
    final pubKey = await _encryptionService.getPublicKey(user.userId);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2210),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.verified_user, color: Color(0xFFBEF263)),
            SizedBox(width: 12),
            Text(
              'Security Protocol',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Identity Key (Public)',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x33BEF263)),
              ),
              child: SelectableText(
                pubKey ?? 'Initializing...',
                style: const TextStyle(
                  color: Color(0xFFBEF263),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Icon(Icons.lock_clock, color: Color(0xFF38BDF8), size: 16),
                SizedBox(width: 8),
                Text(
                  'Quantum-Safe Active',
                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'All threads use X25519 DH for key exchange and ChaCha20-Poly1305 for E2EE.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFBEF263))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2210),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2210).withValues(alpha: 0.8),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0x1ABEF263), width: 1),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0x33BEF263),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security, color: Color(0xFFBEF263)),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cipher',
              style: TextStyle(
                color: Color(0xFFF1F5F9),
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
              color: Color(0xFFBEF263),
            ),
            onPressed: _showSecurityStatus,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBEF263), width: 2),
                  image: _myAvatarBase64 != null
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(_myAvatarBase64!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _myAvatarBase64 == null
                    ? const Icon(Icons.person, color: Color(0xFFBEF263), size: 20)
                    : null,
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
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0x0DBEF263),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 8.0),
                        child: Icon(
                          Icons.search,
                          color: Color(0x99BEF263),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          style: const TextStyle(color: Color(0xFFF1F5F9)),
                          decoration: InputDecoration(
                            hintText: 'Search secure threads',
                            hintStyle: TextStyle(
                              color: const Color(0xFFBEF263).withValues(alpha: 0.4),
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
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedFilter = 'All Chats'),
                        child: _buildFilterChip(
                          'All Chats',
                          _selectedFilter == 'All Chats',
                          icon: Icons.keyboard_arrow_down,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _selectedFilter = 'Unread'),
                        child: _buildFilterChip('Unread', _selectedFilter == 'Unread'),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _selectedFilter = 'Hide Hidden'),
                        child: _buildFilterChip(
                          'Hide Hidden',
                          _selectedFilter == 'Hide Hidden',
                          icon: Icons.visibility_off,
                          isIconFirst: true,
                        ),
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
            stream: _chatService.getDecryptedChatListStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final allChats = snapshot.data ?? [];
              
              final chats = allChats.where((chat) {
                final otherId = chat['sender_id'] == myId ? chat['receiver_id'] : chat['sender_id'];
                final profile = _profileCache[otherId];
                final name = (profile?['username'] ?? profile?['email'] ?? 'Secure Contact').toString().toLowerCase();
                
                if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) {
                  return false;
                }

                if (_selectedFilter == 'Unread') {
                  return false; 
                }
                
                return true;
              }).toList();

              if (chats.isEmpty) {
                return Center(
                  child: Text(
                    _searchQuery.isEmpty 
                      ? 'No secure conversations yet.\nTap + to start one.'
                      : 'No matches found.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white24),
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
                    future: _profileCache.containsKey(otherId) 
                        ? Future.value(_profileCache[otherId]) 
                        : _profileService.searchUser(otherId).then((p) {
                            _profileCache[otherId] = p;
                            return p;
                          }),
                    builder: (context, profSnapshot) {
                      final profile = profSnapshot.data;
                      final name = profile?['username'] ?? profile?['email'] ?? 'Secure Contact';
                      final time =
                          DateTime.tryParse(chat['created_at'])?.toLocal() ??
                          DateTime.now();
                      final displayTime = _formatTime(time);
                      final lastMessage = chat['content'] as String;
                      final isDecrypted = chat['is_decrypted'] == true;
                      final avatarB64 = _contactAvatars[otherId];

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
                          isEncrypted: isDecrypted,
                          message: lastMessage,
                          unreadCount: 0,
                          avatarBase64: avatarB64,
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
          onPressed: _showSearchDialog,
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
            _buildNavItem('Contacts', Icons.people_alt_outlined, false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ContactsPage()),
              );
            }),
            _buildNavItem('Calls', Icons.call_outlined, false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CallsPage()),
              );
            }),
            _buildNavItem('Vault', Icons.key_outlined, false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const VaultPage()),
              );
            }),
            _buildNavItem('Settings', Icons.settings_outlined, false, () {
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
    String? avatarBase64,
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
        color: isGhost ? null : Colors.transparent,
      ),
      child: Opacity(
        opacity: isGhost ? 0.6 : 1.0,
        child: Row(
          children: [
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
                    image: avatarBase64 != null && !isGroup
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(avatarBase64)),
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
                      : (avatarBase64 == null && !isGroup ? const Icon(Icons.person, color: Color(0xFFBEF263)) : null),
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
                              color: const Color(0xFFF1F5F9),
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
