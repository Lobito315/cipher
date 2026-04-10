import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/vault_service.dart';
import 'models/vault_item.dart';
import 'chat_list_page.dart';
import 'calls_page.dart';
import 'settings_page.dart';
import 'contacts_page.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  final _vaultService = VaultService();
  bool _isInitialized = false;
  bool _needsMasterPassword = false;
  final _masterPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initVault();
  }

  Future<void> _initVault() async {
    await _vaultService.init();
    final hasKey = await _vaultService.hasVaultKey();
    if (mounted) {
      setState(() {
        _needsMasterPassword = !hasKey;
        _isInitialized = true;
      });
    }
  }

  Future<void> _lockVault() async {
    await _vaultService.lock();
    if (mounted) {
      setState(() {
        _needsMasterPassword = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vault Locked'),
          backgroundColor: Color(0xFF1E293B),
        ),
      );
    }
  }

  void _showAddItemDialog() {
    final titleController = TextEditingController();
    final userController = TextEditingController();
    final passController = TextEditingController();
    final noteController = TextEditingController();
    String category = 'Credentials';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B2210),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Secure Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildField('Title', titleController, Icons.title),
                const SizedBox(height: 16),
                _buildField(
                  'Username / Email',
                  userController,
                  Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildField(
                  'Password',
                  passController,
                  Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 16),
                _buildField(
                  'Note (Optional)',
                  noteController,
                  Icons.note_alt_outlined,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (titleController.text.isEmpty ||
                        passController.text.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Title and Password are required')),
                      );
                      return;
                    }

                    setSheetState(() => isSaving = true);

                    try {
                      await _vaultService.addItem(
                        title: titleController.text.trim(),
                        category: category,
                        username: userController.text.isEmpty
                            ? null
                            : userController.text.trim(),
                        password: passController.text,
                        note: noteController.text.isEmpty
                            ? null
                            : noteController.text.trim(),
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Item sealed in vault'),
                              backgroundColor: Color(0xFF1E4620),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        setSheetState(() => isSaving = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Error sealing item: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBEF263),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1B2210),
                          ),
                        )
                      : const Text(
                          'Seal in Vault',
                          style: TextStyle(
                            color: Color(0xFF1B2210),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: const Color(0xFFBEF263)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white12),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFBEF263)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showItemDetail(VaultItem item) async {
    final password = await _vaultService.decryptField(item.encryptedPassword);
    final note = item.encryptedNote != null
        ? await _vaultService.decryptField(item.encryptedNote!)
        : null;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B2210),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () async {
                    await _vaultService.deleteItem(item.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (item.username != null) ...[
              const Text(
                'USERNAME',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              Text(
                item.username!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'PASSWORD',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    password,
                    style: const TextStyle(
                      color: Color(0xFFBEF263),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white60, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: password));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: 16),
              const Text(
                'SECURE NOTE',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white60, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: note));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Note copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2210),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2210),
        elevation: 0,
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBEF263).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: Color(0xFFBEF263),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vault',
                          style: TextStyle(
                            color: Color(0xFFF1F5F9),
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
                              'E2E LOCAL ENCRYPTION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xCCBEF263),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                if (!_needsMasterPassword)
                  IconButton(
                    icon: const Icon(Icons.lock_outline, color: Color(0xFFBEF263)),
                    onPressed: _lockVault,
                  ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _isInitialized
              ? (_needsMasterPassword ? _buildMasterPasswordPrompt() : _buildVaultContent())
              : const Center(
                  child: CircularProgressIndicator(color: Color(0xFFBEF263)),
                ),

          // Secure Upload Button (only if unlocked)
          if (!_needsMasterPassword && _isInitialized)
            Positioned(
              bottom: 96,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: _showAddItemDialog,
              icon: const Icon(Icons.add_moderator, color: Color(0xFF1B2210)),
              label: const Text(
                'Add Secret',
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
                color: Color(0xCC1B2210),
                border: Border(
                  top: BorderSide(color: Color(0xFF1E293B), width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavIcon(
                    Icons.chat_bubble_outline,
                    'Chats',
                    false,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatListPage(),
                      ),
                    ),
                  ),
                  _buildNavIcon(
                    Icons.people_alt_outlined,
                    'Contacts',
                    false,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactsPage(),
                      ),
                    ),
                  ),
                  _buildNavIcon(Icons.call_outlined, 'Calls', false, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CallsPage(),
                      ),
                    );
                  }),
                  _buildNavIcon(Icons.shield, 'Vault', true, () {}),
                  _buildNavIcon(Icons.settings_outlined, 'Settings', false, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultContent() {
    return StreamBuilder<List<VaultItem>>(
      stream: _vaultService.watchItems(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _buildSummaryCard(items.length),
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 12,
              ),
              child: Text(
                'SECURE ITEMS',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            if (items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text(
                    'Vault is empty.\nAdd your first secret.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24),
                  ),
                ),
              )
            else
              ...items.map((item) => _buildVaultListItem(item)),
          ],
        );
      },
    );
  }

  Widget _buildMasterPasswordPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Color(0xFFBEF263)),
            const SizedBox(height: 24),
            const Text(
              'Master Password',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your master password to unlock your vault.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            _buildField('Password', _masterPasswordController, Icons.key, isPassword: true),
            const SizedBox(height: 24),
            StatefulBuilder(
              builder: (context, setButtonState) {
                bool isUnlocking = false;

                return ElevatedButton(
                  onPressed: isUnlocking ? null : () async {
                    final pwd = _masterPasswordController.text;
                    if (pwd.isEmpty) return;

                    setButtonState(() => isUnlocking = true);

                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(
                        child: CircularProgressIndicator(color: Color(0xFFBEF263))
                      ),
                    );

                    final hasKey = await _vaultService.hasVaultKey();

                    if (hasKey) {
                      // Verify password is correct before unlocking
                      final isValid = await _vaultService.verifyMasterPassword(pwd);
                      if (mounted) Navigator.pop(context); // close loading

                      if (isValid) {
                        // Password is correct — derive & load the key
                        await _vaultService.setupVaultKey(pwd);
                        if (mounted) {
                          setState(() => _needsMasterPassword = false);
                          _masterPasswordController.clear();
                        }
                      } else {
                        // Wrong password
                        if (mounted) {
                          setButtonState(() => isUnlocking = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('❌ Incorrect master password'),
                              backgroundColor: Colors.redAccent,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    } else {
                      // First time: initialize vault with this password
                      await _vaultService.setupVaultKey(pwd);
                      if (mounted) {
                        Navigator.pop(context); // close loading
                        setState(() => _needsMasterPassword = false);
                        _masterPasswordController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Vault initialized successfully'),
                            backgroundColor: Color(0xFF1E4620),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBEF263),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Unlock Vault',
                    style: TextStyle(
                      color: Color(0xFF1B2210),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int itemCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Protected Assets',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '$itemCount Items Sealed',
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Icon(Icons.verified_user, color: Color(0xFFBEF263), size: 32),
        ],
      ),
    );
  }

  Widget _buildVaultListItem(VaultItem item) {
    return GestureDetector(
      onTap: () => _showItemDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFBEF263).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.vpn_key, color: Color(0xFFBEF263)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.lock,
                        size: 12,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.username ?? 'No user',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
          ],
        ),
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
                : const Color(0xFF64748B),
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
