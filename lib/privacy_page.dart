import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_list_page.dart';
import 'vault_page.dart';
import 'calls_page.dart';
import 'settings_page.dart';
import 'providers/privacy_provider.dart';
import 'services/local_auth_service.dart';
import 'active_sessions_page.dart';
import 'audit_logs_page.dart';
import 'login_page.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final LocalAuthService _authService = LocalAuthService();

  Future<void> _toggleAppLock(bool value, PrivacyProvider provider) async {
    if (value) {
      final authenticated = await _authService.authenticate();
      if (authenticated) {
        provider.setAppLock(true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication failed. Cannot enable App Lock.')),
          );
        }
      }
    } else {
      provider.setAppLock(false);
    }
  }

  void _showPanicDialog(PrivacyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A3319),
        title: const Text('Confirm Identity Wipe?', style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          'This will permanently delete all local data, vault keys, and log you out. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await provider.panicWipe();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('WIPE EVERYTHING', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrivacyProvider>(
      builder: (context, provider, child) {
        final score = provider.securityScore;
        final scoreColor = score >= 90 ? const Color(0xFFBEF263) : (score >= 70 ? Colors.orangeAccent : Colors.redAccent);

        return Scaffold(
          backgroundColor: const Color(0xFF1B2210), // background-dark
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B2210).withValues(alpha: 0.8),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFF1F5F9)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            centerTitle: true,
            title: const Text(
              'Privacy Command',
              style: TextStyle(
                color: Color(0xFFF1F5F9), // text-slate-100
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Icon(
                  Icons.verified_user,
                  color: Color(0xFFBEF263), // primary
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: const Color(0xFF3A4823), // border-subtle
                height: 1.0,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Security Dashboard Card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3319), // surface
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF3A4823),
                      ), // border-subtle
                    ),
                    child: Column(
                      children: [
                        // Progress Ring
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 128,
                              height: 128,
                              child: CircularProgressIndicator(
                                value: score / 100,
                                strokeWidth: 8,
                                backgroundColor: const Color(0xFF3A4823),
                                color: scoreColor,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${score.toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF1F5F9), // text-slate-100
                                  ),
                                ),
                                Text(
                                  score >= 90 ? 'SECURE' : (score >= 70 ? 'GOOD' : 'VULNERABLE'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: scoreColor, // primary/orange/red
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Security Score',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF1F5F9), // text-slate-100
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          score >= 100
                              ? 'Excellent! Your privacy is fully protected.'
                              : 'Your privacy is protected. ${((100 - score) / 5).toInt()} actions recommended.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8), // text-slate-400
                          ),
                        ),
                        if (score < 100) ...[
                          const SizedBox(height: 24),
                          // Action Required alert
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF1B2210,
                              ).withValues(alpha: 0.5), // bg-background-dark/50
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF3A4823),
                              ), // border-border-subtle
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF38BDF8), // text-info (accent-blue)
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Action Required',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFF1F5F9),
                                        ),
                                      ),
                                      Text(
                                        !provider.appLock
                                            ? 'Enable App Lock for +15% score'
                                            : (!provider.ghostMode ? 'Ghost Mode recommended' : 'Enhance protection'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (!provider.appLock) _toggleAppLock(true, provider);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFFBEF263,
                                    ).withValues(alpha: 0.2), // primary/20
                                    foregroundColor: const Color(
                                      0xFFBEF263,
                                    ), // text-primary
                                    elevation: 0,
                                    minimumSize: const Size(0, 24),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Fix',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Advanced Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 12.0,
                        ),
                        child: Text(
                          'ADVANCED CONTROLS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B), // text-slate-500
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A3319), // surface
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF3A4823),
                          ), // border-subtle
                        ),
                        child: Column(
                          children: [
                            _buildToggleItem(
                              title: 'Ghost Mode',
                              subtitle: 'Hide online status and typing indicators',
                              icon: Icons.visibility_off,
                              iconColor: const Color(0xFFBEF263),
                              iconBgColor: const Color(
                                0xFFBEF263,
                              ).withValues(alpha: 0.1),
                              value: provider.ghostMode,
                              onChanged: (val) => provider.setGhostMode(val),
                              showBorder: true,
                            ),
                            _buildToggleItem(
                              title: 'Stealth Notifications',
                              subtitle: 'Mask message content on lock screen',
                              icon: Icons.notifications_paused,
                              iconColor: const Color(0xFF38BDF8),
                              iconBgColor: const Color(
                                0xFF38BDF8,
                              ).withValues(alpha: 0.1),
                              value: provider.stealthNotifications,
                              onChanged: (val) => provider.setStealthNotifications(val),
                              showBorder: true,
                            ),
                            _buildToggleItem(
                              title: 'App Lock',
                              subtitle: 'Require Biometric to open Cipher',
                              icon: Icons.lock,
                              iconColor: const Color(0xFFCBD5E1), // text-slate-300
                              iconBgColor: const Color(
                                0xFF334155,
                              ).withValues(alpha: 0.5), // bg-slate-700/50
                              value: provider.appLock,
                              onChanged: (val) => _toggleAppLock(val, provider),
                              showBorder: true,
                            ),
                            _buildToggleItem(
                              title: 'Auto-Delete',
                              subtitle: 'Erase all messages after 24 hours',
                              icon: Icons.auto_delete,
                              iconColor: const Color(0xFFBEF263),
                              iconBgColor: const Color(
                                0xFFBEF263,
                              ).withValues(alpha: 0.1),
                              value: provider.autoDelete,
                              onChanged: (val) => provider.setAutoDelete(val),
                              showBorder: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Settings Categories
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          'SETTINGS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B), // text-slate-500
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      _buildSettingsButton(
                        title: 'End-to-End Encryption',
                        icon: Icons.vpn_key,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Encryption keys verified. Security active.')),
                          );
                        },
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSettingsButton(
                        title: 'Active Sessions',
                        icon: Icons.devices,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ActiveSessionsPage()),
                          );
                        },
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBEF263),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '2',
                            style: TextStyle(
                              color: Color(0xFF1B2210),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSettingsButton(
                        title: 'Audit Logs',
                        icon: Icons.description,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AuditLogsPage()),
                          );
                        },
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // Panic Button
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 100.0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1), // red-500/10
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Panic Button',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Instantly wipe all local data and log out from all devices.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[400]?.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.bolt, color: Colors.white),
                            label: const Text(
                              'WIPE ALL DATA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            onPressed: () => _showPanicDialog(provider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2A3319), // surface
              border: Border(top: BorderSide(color: Color(0xFF3A4823), width: 1)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem('Chats', Icons.chat_bubble_outline, false, () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatListPage()),
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
      },
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool showBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBorder
            ? const Border(bottom: BorderSide(color: Color(0xFF3A4823)))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF1F5F9),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(
              0xFF1B2210,
            ), // background-dark for icon
            activeTrackColor: const Color(0xFFBEF263), // primary
            inactiveThumbColor: const Color(0xFF94A3B8),
            inactiveTrackColor: const Color(0xFF334155),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton({
    required String title,
    required IconData icon,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A3319), // surface
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A4823)), // border-subtle
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF94A3B8), size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF1F5F9),
                    ),
                  ),
                ),
                trailing,
              ],
            ),
          ),
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
                : const Color(0xFF94A3B8), // slate-400
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFBEF263)
                  : const Color(0xFF94A3B8), // slate-400
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2, // tracking-[0.015em]
            ),
          ),
        ],
      ),
    );
  }
}
