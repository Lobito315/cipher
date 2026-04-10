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
    required String email,
    required String password,
  }) async {
    final userAttributes = {
      AuthUserAttributeKey.email: email,
    };
    return await Amplify.Auth.signUp(
      username: email,
      password: password,
      options: SignUpOptions(userAttributes: userAttributes),
    );
  }

  // Sign in
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    final result = await Amplify.Auth.signIn(
      username: email,
      password: password,
    );
    if (result.isSignedIn) {
      await _initializeUserKeys(password, email);
    }
    return result;
  }

  Future<void> _initializeUserKeys(String password, String email) async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      await _encryptionService.initIdentityKeys(password, email);
      final pubKey = await _encryptionService.getPublicKey();
      if (pubKey != null) {
        await _profileService.updatePublicKey(user.userId, pubKey, user.username);
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
