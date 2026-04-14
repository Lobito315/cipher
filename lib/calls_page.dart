import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'chat_list_page.dart';
import 'vault_page.dart';
import 'settings_page.dart';
import 'call_page.dart';
import 'contacts_page.dart';
import 'models/contact.dart';
import 'services/call_service.dart';
import 'services/contact_service.dart';
import 'services/profile_service.dart';

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  final _callService = CallService();
  final _profileService = ProfileService();
  final _contactService = ContactService();
  String _myDisplayName = 'Me';

  @override
  void initState() {
    super.initState();
    _loadMyName();
  }

  Future<void> _loadMyName() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final profile = await _profileService.getFullProfile(user.userId);
      if (mounted && profile != null) {
        setState(() => _myDisplayName = profile['username'] ?? user.username);
      }
    } catch (_) {}
  }

  /// Shows a contact picker dialog. Returns the selected [Contact] or null.
  Future<Contact?> _showContactPickerDialog() async {
    final contacts = await _contactService.getContacts();
    if (!mounted) return null;

    return showDialog<Contact>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(ctx).size.height * 0.6,
          child: _ContactPickerSheet(contacts: contacts),
        ),
      ),
    );
  }

  Future<void> _startCall({required bool isAudioOnly}) async {
    final contact = await _showContactPickerDialog();
    if (contact == null) return; // User cancelled

    final channelId = "call_${DateTime.now().millisecondsSinceEpoch}";
    await _callService.startCall(
      receiverId: contact.userId,
      receiverName: contact.displayName,
      channelId: channelId,
      callerName: _myDisplayName,
      isAudioOnly: isAudioOnly,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallPage(
            channelName: channelId,
            remoteUserName: contact.displayName,
            remoteUserId: contact.userId,
            isAudioOnly: isAudioOnly,
          ),
        ),
      );
    }
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
        title: const Text(
          'Encrypted Calls',
          style: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Color(0xFFBEF263)),
            onPressed: () => _startCall(isAudioOnly: true),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Color(0xFFBEF263)),
            onPressed: () => _startCall(isAudioOnly: false),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFBEF263).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_outlined,
                color: Color(0xFFBEF263),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Recent Calls',
              style: TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your calls are always end-to-end encrypted.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _startCall(isAudioOnly: true),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Start Audio Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBEF263).withOpacity(0.1),
                    foregroundColor: const Color(0xFFBEF263),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: const BorderSide(color: Color(0xFFBEF263), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _startCall(isAudioOnly: false),
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text('Start Video Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBEF263),
                    foregroundColor: const Color(0xFF1B2210),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
            _buildNavItem(
              context,
              'Chats',
              Icons.chat_bubble_outline,
              false,
              () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatListPage()),
                );
              },
            ),
            _buildNavItem(
              context,
              'Contacts',
              Icons.people_alt_outlined,
              false,
              () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactsPage()),
                );
              },
            ),
            _buildNavItem(context, 'Calls', Icons.videocam_outlined, true, () {}),
            _buildNavItem(context, 'Vault', Icons.key_outlined, false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const VaultPage()),
              );
            }),
            _buildNavItem(
              context,
              'Settings',
              Icons.settings_outlined,
              false,
              () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
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

// ─── Contact Picker Sheet ─────────────────────────────────────────────────────

class _ContactPickerSheet extends StatelessWidget {
  final List<Contact> contacts;

  const _ContactPickerSheet({required this.contacts});

  @override
  Widget build(BuildContext context) {
    // Material gives the widget its own rendering surface (required in dialogs on web)
    return Material(
      color: const Color(0xFF1E2A12),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Column(
        // Column inside SizedBox (bounded height from Dialog) — safe to use Expanded here
        children: [
          // ── Handle bar ──
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFBEF263).withOpacity(0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // ── Title ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.contacts_outlined, color: Color(0xFFBEF263), size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Select a Contact',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0x1ABEF263), height: 1),
          // ── Contact list / empty state ──
          Expanded(
            child: contacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: const Color(0xFFBEF263).withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No contacts yet.\nAdd contacts first to start a call.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: contacts.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Color(0x0FBEF263), height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return _ContactTile(
                        contact: contact,
                        onTap: () => Navigator.pop(context, contact),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;

  const _ContactTile({required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0x1ABEF263),
      highlightColor: const Color(0x0DBEF263),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0x33BEF263),
              backgroundImage: contact.avatarBase64 != null
                  ? MemoryImage(base64Decode(contact.avatarBase64!))
                  : null,
              child: contact.avatarBase64 == null
                  ? Text(
                      contact.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFBEF263),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Name & username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '@${contact.username}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
            // Arrow hint
            const Icon(Icons.chevron_right_rounded, color: Color(0x66BEF263), size: 20),
          ],
        ),
      ),
    );
  }
}
