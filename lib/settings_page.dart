import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'chat_list_page.dart';
import 'vault_page.dart';
import 'calls_page.dart';
import 'contacts_page.dart';
import 'login_page.dart';
import 'privacy_page.dart';
import 'profile_page.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'package:provider/provider.dart';
import 'providers/call_provider.dart';
import 'providers/chat_notification_provider.dart';
import 'services/contact_service.dart';
import 'providers/settings_provider.dart';
import 'l10n/translations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();
  final _profileService = ProfileService();

  Future<Map<String, dynamic>> _loadUserData() async {
    final user = await _authService.currentUser;
    if (user == null) return {};
    
    final profile = await _profileService.getFullProfile(user.userId);
    return {
      'uuid': user.userId,
      'email': user.username,
      'displayName': profile?['username'],
    };
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().fetchMfaStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
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
        title: Text(
          context.tr('settings'),
          style: const TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadUserData(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final uuid = data['uuid'] as String? ?? '';
          final email = data['email'] as String? ?? 'Secure User';
          final displayName = data['displayName'] as String?;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Section
              _buildProfileCard(context, email, uuid, displayName),
              const SizedBox(height: 24),

              _buildSectionHeader(context.tr('account')),
              _buildSettingItem(
                context.tr('profile_info'),
                Icons.person_outline,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                  if (result == true) setState(() {});
                },
              ),
              _buildSettingItem(
                context.tr('privacy_security'),
                Icons.shield_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacyPage()),
                  );
                },
              ),
              _buildSettingItem(
                context.tr('two_factor'),
                Icons.enhanced_encryption_outlined,
                onTap: () async {
                  final success = await settings.toggleMfa(!settings.mfaEnabled);
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('mfa_required'))),
                    );
                  }
                },
                trailing: settings.mfaLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      settings.mfaEnabled ? context.tr('on') : context.tr('off'),
                      style: TextStyle(
                        color: settings.mfaEnabled ? const Color(0xFFBEF263) : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader(context.tr('preferences')),
              _buildSettingItem(
                context.tr('chat_notifications'),
                Icons.chat_bubble_outline,
                onTap: () {
                  settings.setChatNotifications(!settings.chatNotificationsEnabled);
                },
                trailing: Switch(
                  value: settings.chatNotificationsEnabled,
                  onChanged: (val) => settings.setChatNotifications(val),
                  activeColor: const Color(0xFFBEF263),
                ),
              ),
              _buildSettingItem(
                context.tr('call_notifications'),
                Icons.call_outlined,
                onTap: () {
                  settings.setCallNotifications(!settings.callNotificationsEnabled);
                },
                trailing: Switch(
                  value: settings.callNotificationsEnabled,
                  onChanged: (val) => settings.setCallNotifications(val),
                  activeColor: const Color(0xFFBEF263),
                ),
              ),
              _buildSettingItem(
                context.tr('appearance'),
                Icons.palette_outlined,
                onTap: () {
                  settings.setThemeMode(settings.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
                },
                trailing: Text(
                  settings.themeMode == ThemeMode.dark ? context.tr('dark') : context.tr('light'),
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ),
              _buildSettingItem(
                context.tr('language'),
                Icons.language_outlined,
                onTap: () {
                  final newLocale = settings.locale.languageCode == 'en' ? const Locale('es') : const Locale('en');
                  settings.setLocale(newLocale);
                },
                trailing: Text(
                  settings.locale.languageCode == 'en' ? context.tr('english') : context.tr('spanish'),
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader(context.tr('danger_zone')),
              _buildSettingItem(
                context.tr('logout'),
                Icons.logout,
                iconColor: Colors.redAccent,
                onTap: () async {
                  // Reset subscriptions before signing out
                  await Provider.of<CallProvider>(context, listen: false).reset();
                  await Provider.of<ChatNotificationProvider>(context, listen: false).reset();
                  ContactService().clearCache();
                  await _authService.signOut();
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
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: const Border(top: BorderSide(color: Color(0x1ABEF263), width: 1)),
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

  Widget _buildProfileCard(BuildContext context, String email, String uuid, String? displayName) {
    String name = displayName ?? email;
    if (name.contains('@') && displayName == null) {
      name = name.split('@')[0];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3319),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A4823)),
      ),
      child: Column(
        children: [
          Row(
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
                      name,
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'ACTIVE IDENTITY verified',
                      style: TextStyle(
                        color: Color(0xFFBEF263),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFFBEF263)),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                  if (result == true) setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          _buildCopyableId("Cipher ID (Email)", email),
          const SizedBox(height: 12),
          _buildCopyableId("Technical ID (UUID)", uuid),
        ],
      ),
    );
  }

  Widget _buildCopyableId(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(color: Color(0xFFBEF263), fontSize: 13, fontFamily: 'monospace'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.content_copy, size: 16, color: Color(0xFFBEF263)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied $label to clipboard'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: const Color(0xFFBEF263),
                  ),
                );
              },
            ),
          ],
        ),
      ],
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
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
