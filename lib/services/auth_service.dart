import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class AuthService {
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
    return await Amplify.Auth.signIn(
      username: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
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
