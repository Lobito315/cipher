import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'chat_list_page.dart';
import 'calls_page.dart';
import 'vault_page.dart';
import 'settings_page.dart';
import 'chat_detail_page.dart';
import 'services/contact_service.dart';
import 'services/profile_service.dart';
import 'models/contact.dart';
import 'services/call_service.dart';
import 'call_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _contactService = ContactService();
  final _profileService = ProfileService();
  final _picker = ImagePicker();
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final contacts = await _contactService.getContacts();
    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  void _showAddContactDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2210),
        title: const Text('Add Contact', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter Email or ID...',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFBEF263)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBEF263)),
            onPressed: () async {
              final identifier = controller.text.trim();
              if (identifier.isEmpty) return;
              final profile = await _profileService.searchUser(identifier);
              if (profile != null) {
                await _contactService.addContact(profile);
                if (mounted) {
                  Navigator.pop(context);
                  _loadContacts();
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User not found')),
                );
              }
            },
            child: const Text('Add', style: TextStyle(color: Color(0xFF1B2210))),
          ),
        ],
      ),
    );
  }

  Future<void> _pickContactImage(String userId) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        await _contactService.updateAvatar(userId, bytes);
        _loadContacts();
      }
    } catch (e) {
      debugPrint('Error picking contact image: $e');
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
          'Secure Contacts',
          style: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFFBEF263)),
            onPressed: _showAddContactDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBEF263)))
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: const Color(0xFFBEF263).withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      const Text(
                        'Your contact list is empty.',
                        style: TextStyle(color: Colors.white38),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _showAddContactDialog,
                        child: const Text('Add your first contact', style: TextStyle(color: Color(0xFFBEF263))),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return _buildContactCard(contact);
                  },
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
            _buildNavItem('Chats', Icons.chat_bubble_outline, false, () {
               Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatListPage()));
            }),
            _buildNavItem('Contacts', Icons.people_alt, true, () {}),
            _buildNavItem('Calls', Icons.call_outlined, false, () {
               Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CallsPage()));
            }),
            _buildNavItem('Vault', Icons.key_outlined, false, () {
               Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const VaultPage()));
            }),
            _buildNavItem('Settings', Icons.settings_outlined, false, () {
               Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0DBEF263),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1ABEF263)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _pickContactImage(contact.userId),
            child: CircleAvatar(
              backgroundColor: const Color(0x33BEF263),
              backgroundImage: contact.avatarBase64 != null
                  ? MemoryImage(base64Decode(contact.avatarBase64!))
                  : null,
              child: contact.avatarBase64 == null
                  ? Text(
                      contact.displayName[0].toUpperCase(),
                      style: const TextStyle(color: Color(0xFFBEF263), fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  contact.username,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Color(0xFFBEF263), size: 20),
            onPressed: () async {
              final callService = CallService();
              final channelId = "call_${DateTime.now().millisecondsSinceEpoch}";
              await callService.startCall(
                receiverId: contact.userId,
                receiverName: contact.displayName,
                channelId: channelId,
                isAudioOnly: true,
              );
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallPage(
                      channelName: channelId,
                      remoteUserName: contact.displayName,
                      isAudioOnly: true,
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Color(0xFFBEF263), size: 20),
            onPressed: () async {
              final callService = CallService();
              final channelId = "call_${DateTime.now().millisecondsSinceEpoch}";
              await callService.startCall(
                receiverId: contact.userId,
                receiverName: contact.displayName,
                channelId: channelId,
                isAudioOnly: false,
              );
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallPage(
                      channelName: channelId,
                      remoteUserName: contact.displayName,
                      isAudioOnly: false,
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFBEF263), size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailPage(
                    receiverId: contact.userId,
                    receiverName: contact.displayName,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: () async {
              await _contactService.removeContact(contact.userId);
              _loadContacts();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFBEF263) : const Color(0xFFBEF263).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isSelected ? const Color(0xFFBEF263) : const Color(0xFFBEF263).withValues(alpha: 0.4),
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
