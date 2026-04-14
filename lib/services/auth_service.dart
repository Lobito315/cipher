import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'encryption_service.dart';
import 'profile_service.dart';
import 'secure_storage_service.dart';

class AuthService {
  final _encryptionService = EncryptionService();
  final _profileService = ProfileService();
  final _secureStorage = SecureStorageService();

  // Sign up
  Future<SignUpResult> signUp({
    required String phoneNumber,
    required String cipherId,
    required String password,
  }) async {
    final userAttributes = {
      AuthUserAttributeKey.phoneNumber: phoneNumber,
      AuthUserAttributeKey.preferredUsername: cipherId,
    };
    return await Amplify.Auth.signUp(
      username: phoneNumber,
      password: password,
      options: SignUpOptions(userAttributes: userAttributes),
    );
  }

  // Confirm Sign up
  Future<SignUpResult> confirmSignUp({
    required String phoneNumber,
    required String code,
  }) async {
    return await Amplify.Auth.confirmSignUp(
      username: phoneNumber,
      confirmationCode: code,
    );
  }

  // Resend confirmation code
  Future<ResendSignUpCodeResult> resendConfirmationCode(String phoneNumber) async {
    return await Amplify.Auth.resendSignUpCode(username: phoneNumber);
  }

  // Sign in
  Future<SignInResult> signIn({
    required String phoneNumber,
    required String password,
  }) async {
    final result = await Amplify.Auth.signIn(
      username: phoneNumber,
      password: password,
    );
    if (result.isSignedIn) {
      await _initializeUserKeys(password, phoneNumber);
    }
    return result;
  }

  Future<void> _initializeUserKeys(String password, String phoneNumber) async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final attributes = await Amplify.Auth.fetchUserAttributes();
      
      String cipherId = user.username; // Fallback to phone number if not found
      try {
        final attr = attributes.firstWhere(
          (a) => a.userAttributeKey == AuthUserAttributeKey.preferredUsername,
        );
        cipherId = attr.value;
      } catch (_) {}

      await _encryptionService.initIdentityKeys(password, phoneNumber, user.userId);
      final pubKey = await _encryptionService.getPublicKey(user.userId);
      if (pubKey != null) {
        await _profileService.updatePublicKey(user.userId, pubKey, cipherId);
      }
    } catch (e) {
      print('DEBUG: Error initializing user keys: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _secureStorage.deleteAll(); // Wipe all keys for security!
    await Amplify.Auth.signOut();
  }

  // Get current user
  Future<AuthUser?> get currentUser async {
    try {
      return await Amplify.Auth.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  // Listen to auth changes (Simplified using Hub)
  Stream<AuthHubEvent> get authStateChanges {
    final controller = StreamController<AuthHubEvent>.broadcast();
    Amplify.Hub.listen(HubChannel.Auth, (HubEvent event) {
      if (event is AuthHubEvent) {
        controller.add(event);
      }
    });
    return controller.stream;
  }
}
