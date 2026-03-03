import 'package:flutter/material.dart';

class VaultPage extends StatelessWidget {
  const VaultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2210), // dark:bg-background-dark
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2210),
        elevation: 0,
        toolbarHeight: 80,
        automaticallyImplyLeading: false, // Custom header
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFBEF263,
                        ).withOpacity(0.2), // primary/20
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: Color(0xFFBEF263),
                        size: 24,
                      ), // shield_lock approx
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vault',
                          style: TextStyle(
                            color: Color(0xFFF1F5F9), // text-slate-100
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFBEF263),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'AES-256 ENCRYPTED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xCCBEF263), // primary/80
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B), // dark:bg-slate-800
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Color(0xFF94A3B8), // dark:text-slate-400
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              120,
            ), // Padding for FAB and Nav
            children: [
              // Storage Overview Card
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF1E293B,
                  ).withOpacity(0.5), // dark:bg-slate-800/50
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                  ), // dark:border-slate-800
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Storage Overview',
                              style: TextStyle(
                                color: Color(0xFF94A3B8), // dark:text-slate-400
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: '12.4 GB ',
                                    style: TextStyle(
                                      color: Color(
                                        0xFFF1F5F9,
                                      ), // dark:text-slate-100
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '/ 20 GB',
                                    style: TextStyle(
                                      color: Color(
                                        0xFF64748B,
                                      ), // text-slate-500
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          '62% Used',
                          style: TextStyle(
                            color: Color(0xFFBEF263),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155), // dark:bg-slate-700
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 62,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFBEF263),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFBEF263,
                                    ).withOpacity(0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Expanded(flex: 38, child: SizedBox()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(
                      color: Color(0xFF1E293B),
                    ), // dark:border-slate-800
                    const SizedBox(height: 8),
                    // Legends
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFBEF263),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '7.2 GB Media',
                                style: TextStyle(
                                  color: Color(
                                    0xFF94A3B8,
                                  ), // dark:text-slate-400
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF94A3B8), // bg-slate-400
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '5.2 GB Docs',
                                style: TextStyle(
                                  color: Color(
                                    0xFF94A3B8,
                                  ), // dark:text-slate-400
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Categories
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 12),
                child: Text(
                  'CATEGORIES',
                  style: TextStyle(
                    color: Color(0xFF94A3B8), // dark:text-slate-400
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildCategoryCard('image', 'Photos', '1,204 files'),
                  _buildCategoryCard('description', 'Documents', '85 files'),
                  _buildCategoryCard('mic', 'Voice Memos', '32 files'),
                  _buildCategoryCard('vpn_key', 'Private Keys', '4 items'),
                ],
              ),
              const SizedBox(height: 32),

              // Recent Activity
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RECENT ACTIVITY',
                      style: TextStyle(
                        color: Color(0xFF94A3B8), // dark:text-slate-400
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFFBEF263),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildRecentActivityItem(
                icon: Icons.image,
                title: 'Passport_Scan_Main.jpg',
                subtitle: '2.4 MB • Encrypted',
                statusText: '2h',
                statusIcon: Icons.timer,
                statusColor: Colors.amber,
              ),
              _buildRecentActivityItem(
                icon: Icons.audio_file,
                title: 'Meeting_Recording_Confidential.mp3',
                subtitle: '18.1 MB • Encrypted',
                statusText: 'Safe',
                statusIcon: Icons.verified_user,
                statusColor: const Color(0xFF94A3B8), // slate-400
              ),
              _buildRecentActivityItem(
                icon: Icons.key,
                title: 'Cold_Wallet_Recovery.txt',
                subtitle: '12 KB • Encrypted',
                statusText: '45m',
                statusIcon: Icons.timer,
                statusColor: Colors.amber,
              ),
            ],
          ),

          // Secure Upload Button
          Positioned(
            bottom: 96,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_moderator, color: Color(0xFF1B2210)),
              label: const Text(
                'Secure Upload',
                style: TextStyle(
                  color: Color(0xFF1B2210),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBEF263),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                elevation: 8,
                shadowColor: const Color(0xFFBEF263).withOpacity(0.5),
              ),
            ),
          ),

          // Bottom Navigation Frame
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xCC1B2210), // dark:bg-background-dark/80
                border: Border(
                  top: BorderSide(color: Color(0xFF1E293B), width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                24,
                12,
                24,
                24,
              ), // padding for standard phone bottom
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavIcon(Icons.chat_bubble, 'Chats', false, () {
                    Navigator.pop(context);
                  }),
                  _buildNavIcon(Icons.call, 'Calls', false, () {}),
                  _buildNavIcon(Icons.shield, 'Vault', true, () {}),
                  _buildNavIcon(Icons.settings, 'Settings', false, () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String iconName, String title, String subtitle) {
    IconData iconData;
    switch (iconName) {
      case 'image':
      case 'photo_library':
        iconData = Icons.photo_library;
        break;
      case 'description':
        iconData = Icons.description;
        break;
      case 'mic':
        iconData = Icons.mic;
        break;
      case 'vpn_key':
        iconData = Icons.vpn_key;
        break;
      default:
        iconData = Icons.folder;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5), // dark:bg-slate-800/50
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E293B),
        ), // dark:border-slate-800
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(iconData, color: const Color(0xFFBEF263), size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9), // dark:text-slate-100
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B), // text-slate-500
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String statusText,
    required IconData statusIcon,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.3), // dark:bg-slate-800/30
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E293B),
        ), // dark:border-slate-800
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFBEF263).withOpacity(0.1), // primary/10
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFBEF263)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9), // dark:text-slate-100
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.lock,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ), // text-slate-400
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B), // text-slate-500
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(
    IconData icon,
    String label,
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
                : const Color(0xFF64748B), // slate-500
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFBEF263)
                  : const Color(0xFF64748B),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
