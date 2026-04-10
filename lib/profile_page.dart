import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'services/profile_service.dart';
import 'services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileService = ProfileService();
  final _authService = AuthService();

  bool _isLoading = true;
  String? _userId;
  String? _username;
  String? _avatarUrl;
  String? _avatarBase64;
  File? _imageFile;
  Uint8List? _imageBytes;
  final TextEditingController _usernameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _authService.currentUser;
      if (user != null) {
        _userId = user.username;
        final profile = await _profileService.getFullProfile(_userId!);
        if (profile != null) {
          _username = profile['username'] ?? _userId;
          _avatarUrl = profile['avatarUrl'];
        } else {
          _username = _userId;
        }
        _usernameController.text = _username!;

        // Load base64 avatar (works on Web)
        final b64 = await _profileService.getAvatarBase64(_userId!);
        if (b64 != null) {
          setState(() {
            _avatarBase64 = b64;
          });
        }

        // Load local avatar path (Mobile only fallback)
        if (!kIsWeb) {
          final localPath = await _profileService.getLocalAvatarPath(_userId!);
          if (localPath != null) {
            setState(() {
              _imageFile = File(localPath);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          if (!kIsWeb) {
            _imageFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: \$e');
    }
  }

  Future<void> _saveProfile() async {
    final newUsername = _usernameController.text.trim();
    final hasImageChange = _imageFile != null;

    if (newUsername.isEmpty || (newUsername == _username && !hasImageChange) || _userId == null) {
      if (newUsername == _username && !hasImageChange) {
        Navigator.pop(context);
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (newUsername != _username) {
        await _profileService.updateUsername(_userId!, newUsername);
        _username = newUsername;
      }
      
      if (_imageBytes != null) {
        await _profileService.saveAvatarBase64(_userId!, _imageBytes!);
        // Also save to file if on mobile
        if (!kIsWeb && _imageFile != null) {
          await _profileService.saveLocalAvatar(_userId!, _imageFile!);
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFFBEF263),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate change
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2210), // background-dark
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2210).withAlpha(204), // 0.8 * 255
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFF1F5F9)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile Information',
          style: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFFBEF263)),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFBEF263)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0x33BEF263),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFBEF263), width: 2),
                              image: _imageBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_imageBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_avatarBase64 != null
                                      ? DecorationImage(
                                          image: MemoryImage(base64Decode(_avatarBase64!)),
                                          fit: BoxFit.cover,
                                        )
                                      : (_avatarUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(_avatarUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null)),
                            ),
                            child: (_imageBytes == null && _avatarBase64 == null && _avatarUrl == null)
                                ? const Icon(Icons.person,
                                    color: Color(0xFFBEF263), size: 50)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2A3319),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Color(0xFFBEF263), size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Display Name',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Color(0xFFF1F5F9)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2A3319),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF3A4823)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFBEF263)),
                      ),
                      prefixIcon: const Icon(Icons.badge_outlined,
                          color: Color(0xFF64748B)),
                      hintText: 'Enter your display name',
                      hintStyle:
                          const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This is how other users will see you in chats and calls.',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'User ID',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3319),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3A4823)),
                    ),
                    child: SelectableText(
                      _userId ?? '',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
