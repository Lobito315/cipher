import 'dart:ui';
import 'package:flutter/material.dart';
import 'chat_list_page.dart';
import 'vault_page.dart';
import 'settings_page.dart';

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
            icon: const Icon(Icons.add_call, color: Color(0xFFBEF263)),
            onPressed: () {},
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
                Icons.call_end_outlined,
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
            _buildNavItem(context, 'Calls', Icons.call, true, () {}),
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
