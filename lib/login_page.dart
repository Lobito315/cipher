import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'signup_page.dart';
import 'verification_page.dart';
import 'chat_list_page.dart';
import 'services/auth_service.dart';
import 'services/local_auth_service.dart';
import 'services/secure_storage_service.dart';
import 'services/encryption_service.dart';
import 'services/profile_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _localAuthService = LocalAuthService();
  final _secureStorage = SecureStorageService();
  final _encryptionService = EncryptionService();
  final _profileService = ProfileService();
  final _phoneController = TextEditingController(text: '+1');
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      try {
        await _authService.signOut();
      } catch (_) {} // Ignore errors if not currently signed in

      final result = await _authService.signIn(
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save credentials for future biometric login
      await _secureStorage.saveCredentials(
        _phoneController.text.trim(),
        _passwordController.text.trim(),
      );

      // Initialize E2EE Identity Keys (Deterministic from password)
      final user = await _authService.currentUser;
      if (user != null) {
        await _encryptionService.initIdentityKeys(_passwordController.text.trim(), _phoneController.text.trim(), user.userId);
        
        // Sync Public Key to AWS
        final pubKey = await _encryptionService.getPublicKey(user.userId);
        await _profileService.updatePublicKey(user.userId, pubKey!, _phoneController.text.trim());
      }

      if (mounted) {
        if (result.isSignedIn) {
          // Sign-in successful, go to home page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChatListPage()),
          );
        } else if (result.nextStep.signInStep == AuthSignInStep.confirmSignUp) {
          // User exists but is not confirmed yet
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationPage(phoneNumber: _phoneController.text.trim()),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login Status: ${result.nextStep.signInStep}')),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _loginWithBiometrics() async {
    final hasStored = await _secureStorage.hasCredentials();
    if (!hasStored) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No stored credentials. Please login with password first.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final isAuthenticated = await _localAuthService.authenticate();
    if (isAuthenticated) {
      setState(() => _isLoading = true);
      try {
        final creds = await _secureStorage.getCredentials();
        final phone = creds['email']; // We reuse the 'email' key in secure storage for simplicity or could refactor
        final password = creds['password'];

        if (phone != null && password != null) {
          final res = await _authService.signIn(phoneNumber: phone, password: password);
          final user = await _authService.currentUser;
          
          if (user != null) {
            // Re-initialize Identity Keys from stored password
            await _encryptionService.initIdentityKeys(password, phone, user.userId);
          }
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ChatListPage()),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Biometric Login Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication failed or was cancelled'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12140D), // Slightly lighter than 0x0A0C07 for better visibility
      body: Stack(
        children: [
          // Background mesh approximation
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    Color(0x0DBEF263), // rgba(190, 242, 99, 0.05)
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.5],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    Color(0x05BEF263), // rgba(190, 242, 99, 0.02)
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.5],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top App Bar / Logo Section
                Padding(
                  padding: const EdgeInsets.only(top: 48.0, bottom: 24.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBEF263).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(
                              0xFFBEF263,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_open,
                          color: Color(0xFFBEF263),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cipher',
                        style: TextStyle(
                          color: Color(0xFFF1F5F9), // text-slate-100
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content Region
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Hero Visualization
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Abstract circles
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Blur effect
                                  Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(
                                        0xFFBEF263,
                                      ).withValues(alpha: 0.05),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFBEF263,
                                          ).withValues(alpha: 0.05),
                                          blurRadius: 40,
                                          spreadRadius: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                   Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(
                                          0xFFBEF263,
                                        ).withValues(alpha: 0.1),
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(
                                              0xFFBEF263,
                                            ).withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Center(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Opacity(
                                              opacity: 0.6,
                                              child: Image.network(
                                                "https://lh3.googleusercontent.com/aida-public/AB6AXuCMdiQzUsC1_xPQIxFd0JrHU24I99kHUPiaXQjxBYp6jGi33u2QEnWtJ6dUIYPA9b-pXnoKLpZ4UarEwJxuwIBs3ahFfpPOfHOVy5r6UxMXdIXvzq3AN0GbCUd-fj7cD2Gap-64wOKvRpsdLdUtyQ3M0sh7uSstCvU1_Yrgh1aH2RTE_EiBzjVtCxhDXIxNT4AMlv3Qmbuv-G0DxlYztTbJ8aEZTFVYifmhzk1C7YSJ1eBBsMWOFkkVFm_czWw1WRvEis8kRz39KkQ",
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                              loadingProgress.expectedTotalBytes!
                                                          : null,
                                                      color: const Color(0xFFBEF263),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.image_not_supported,
                                                    color: Color(0xFF3A4823),
                                                    size: 48,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                               const SizedBox(height: 24),
                              const Text(
                                'Welcome to Cipher',
                                style: TextStyle(
                                  color: Color(0xFFF1F5F9), // text-slate-100
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const SizedBox(
                                width: 280,
                                child: Text(
                                  'The Gateway to Secure Communication. Your privacy, encrypted.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8), // text-slate-400
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Input fields
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Phone Number (e.g., +1)',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF3A4823),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1B2210),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFBEF263),
                                        width: 0.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3A4823),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFBEF263),
                                      ),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      color: Color(0xFFBEF263),
                                    ),
                                  ),
                                  validator: (val) =>
                                      val!.isEmpty ? 'Enter phone number' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Master Password',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF3A4823),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1B2210),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFBEF263),
                                        width: 0.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3A4823),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFBEF263),
                                      ),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFFBEF263),
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.visibility_off,
                                      color: Color(0xFF3A4823),
                                    ),
                                  ),
                                  validator: (val) =>
                                      val!.isEmpty ? 'Enter password' : null,
                                ),
                                const SizedBox(height: 24),
                                // Primary Action
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFBEF263),
                                    foregroundColor: const Color(0xFF0A0C07),
                                    minimumSize: const Size(
                                      double.infinity,
                                      56,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 10,
                                    shadowColor: const Color(
                                      0xFFBEF263,
                                    ).withValues(alpha: 0.2),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Color(0xFF0A0C07),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.vpn_key, size: 24),
                                            SizedBox(width: 12),
                                            Text(
                                              'Login Securely',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                const SizedBox(height: 16),
                                // Secondary Action (Biometrics)
                                OutlinedButton(
                                  onPressed: _loginWithBiometrics,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: const Color(
                                        0xFFBEF263,
                                      ).withOpacity(0.1),
                                    ),
                                    backgroundColor: const Color(
                                      0xFF1C2211,
                                    ).withOpacity(0.4),
                                    foregroundColor: const Color(
                                      0xFFF1F5F9,
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      56,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        16,
                                      ),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.fingerprint,
                                        color: Color(0xFFBEF263),
                                        size: 24,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Use Biometrics',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Footer Links
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Don't have an account?",
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SignupPage(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFFBEF263,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                      ),
                                      child: const Text(
                                        'Sign Up Now',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(
                                        0xFF64748B,
                                      ).withValues(alpha: 0.5),
                                    ),
                                    child: const Text(
                                      'Emergency Wipe',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Bottom Safe Area Indicator (Visual only)
                                Container(
                                  height: 4,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B), // slate-800
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
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
        ],
      ),
    );
  }
}
