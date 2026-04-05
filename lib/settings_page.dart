import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'chat_list_page.dart';
import 'vault_page.dart';
import 'calls_page.dart';
import 'login_page.dart';
import 'privacy_page.dart';
import 'services/auth_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

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
          'Settings',
          style: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: FutureBuilder<AuthUser?>(
        future: authService.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          final userEmail = user?.username ?? 'Secure User';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Section
              _buildProfileCard(userEmail),
              const SizedBox(height: 24),

              _buildSectionHeader('ACCOUNT'),
              _buildSettingItem(
                'Profile Information',
                Icons.person_outline,
                onTap: () {},
              ),
              _buildSettingItem(
                'Privacy & Security',
                Icons.shield_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacyPage()),
                  );
                },
              ),
              _buildSettingItem(
                'Two-Factor Authentication',
                Icons.enhanced_encryption_outlined,
                onTap: () {},
                trailing: const Text(
                  'ON',
                  style: TextStyle(
                    color: Color(0xFFBEF263),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('PREFERENCES'),
              _buildSettingItem(
                'Notifications',
                Icons.notifications_outlined,
                onTap: () {},
              ),
              _buildSettingItem(
                'Appearance',
                Icons.palette_outlined,
                onTap: () {},
                trailing: const Text(
                  'DARK',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ),
              _buildSettingItem(
                'Language',
                Icons.language_outlined,
                onTap: () {},
                trailing: const Text(
                  'ENGLISH',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('DANGER ZONE'),
              _buildSettingItem(
                'Log Out',
                Icons.logout,
                iconColor: Colors.redAccent,
                onTap: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 80),
            ],
          );
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
            _buildNavItem(context, 'Calls', Icons.call_outlined, false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CallsPage()),
              );
            }),
            _buildNavItem(context, 'Vault', Icons.key_outlined, false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const VaultPage()),
              );
            }),
            _buildNavItem(context, 'Settings', Icons.settings, true, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String email) {
    String displayName = email;
    if (email.contains('@')) {
      displayName = email.split('@')[0];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3319),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A4823)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0x33BEF263),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFFBEF263), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFFBEF263)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    IconData icon, {
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3319),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A4823)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor ?? const Color(0xFFBEF263)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing:
            trailing ??
            const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 20),
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
