import 'dart:ui';
import 'package:flutter/material.dart';
import 'chat_list_page.dart';
import 'vault_page.dart';
import 'settings_page.dart';
import 'call_page.dart';
import 'contacts_page.dart';
import 'services/call_service.dart';

class CallsPage extends StatelessWidget {
  const CallsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2210), // background-dark
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
            onPressed: () async {
              final callService = CallService();
              final channelId = "call_${DateTime.now().millisecondsSinceEpoch}";
              await callService.startCall(
                receiverId: "satoshi_id_placeholder", 
                receiverName: "Satoshi",
                channelId: channelId,
                isAudioOnly: true,
              );
              
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallPage(
                      channelName: channelId,
                      remoteUserName: "Satoshi",
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
              final callService = CallService();
              final channelId = "call_${DateTime.now().millisecondsSinceEpoch}";
              await callService.startCall(
                receiverId: "satoshi_id_placeholder", 
                receiverName: "Satoshi",
                channelId: channelId,
                isAudioOnly: false,
              );
              
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallPage(
                      channelName: channelId,
                      remoteUserName: "Satoshi",
                      isAudioOnly: false,
                    ),
                  ),
                );
              }
            },
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
                  onPressed: () async {
                    final callService = CallService();
                    final channelId = "call_${DateTime.now().millisecondsSinceEpoch}";
                    await callService.startCall(
                      receiverId: "satoshi_id_placeholder",
                      receiverName: "Satoshi",
                      channelId: channelId,
                      isAudioOnly: true,
                    );
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CallPage(
                            channelName: channelId,
                            remoteUserName: "Satoshi",
                            isAudioOnly: true,
                          ),
                        ),
                      );
                    }
                  },
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
                  onPressed: () async {
                    final callService = CallService();
                    final channelId = "call_${DateTime.now().millisecondsSinceEpoch}";
                    await callService.startCall(
                      receiverId: "satoshi_id_placeholder",
                      receiverName: "Satoshi",
                      channelId: channelId,
                      isAudioOnly: false,
                    );
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CallPage(
                            channelName: channelId,
                            remoteUserName: "Satoshi",
                            isAudioOnly: false,
                          ),
                        ),
                      );
                    }
                  },
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
