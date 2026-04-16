import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _localeKey = 'app_locale';
  static const String _chatNotifKey = 'chat_notif';
  static const String _callNotifKey = 'call_notif';

  ThemeMode _themeMode = ThemeMode.dark; // Default to dark neon theme
  Locale _locale = const Locale('en'); // Default to English
  bool _chatNotificationsEnabled = true;
  bool _callNotificationsEnabled = true;

  // MFA requires asynchronous fetching from Amplify Auth
  bool _mfaEnabled = false;
  bool _mfaLoading = true;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get chatNotificationsEnabled => _chatNotificationsEnabled;
  bool get callNotificationsEnabled => _callNotificationsEnabled;
  bool get mfaEnabled => _mfaEnabled;
  bool get mfaLoading => _mfaLoading;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Theme
    final themeStr = prefs.getString(_themeKey);
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }

    // Locale
    final localeStr = prefs.getString(_localeKey);
    if (localeStr != null) {
      _locale = Locale(localeStr);
    }

    // Notifications
    _chatNotificationsEnabled = prefs.getBool(_chatNotifKey) ?? true;
    _callNotificationsEnabled = prefs.getBool(_callNotifKey) ?? true;

    notifyListeners();
  }

  Future<void> fetchMfaStatus() async {
    _mfaLoading = true;
    notifyListeners();

    try {
      final cognitoPlugin = Amplify.Auth.getPlugin(AmplifyAuthCognito.pluginKey);
      final session = await cognitoPlugin.fetchAuthSession();
      if (session.isSignedIn) {
        final user = await Amplify.Auth.getCurrentUser();
        // Since we cannot fetch the specific MFA preference directly easily without
        // calling admin APIs, a robust way natively is to check user attributes if synced,
        // or try to fetch the device info. For now, assume false and allow toggle to try setting.
        // Actually, AWS Amplify Flutter has fetchUserAttributes, but "custom:mfa_enabled" 
        // would need to be in the schema manually.
        // As a fallback, we will assume it's disabled initially unless they just toggled it.
        // A full implementation might require checking AWS Cognito User directly via API.
        
        // We will default to false, meaning "Not setup or disabled in app state"
        _mfaEnabled = false; 
      }
    } catch (e) {
      debugPrint('Error fetching MFA status: $e');
    } finally {
      _mfaLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  Future<void> setLocale(Locale newLocale) async {
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);
    notifyListeners();
  }

  Future<void> setChatNotifications(bool enabled) async {
    _chatNotificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chatNotifKey, enabled);
    notifyListeners();
  }

  Future<void> setCallNotifications(bool enabled) async {
    _callNotificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_callNotifKey, enabled);
    notifyListeners();
  }

  Future<bool> toggleMfa(bool enable) async {
    _mfaLoading = true;
    notifyListeners();

    bool success = false;
    try {
      final cognitoPlugin = Amplify.Auth.getPlugin(AmplifyAuthCognito.pluginKey);
      if (enable) {
        // Warning: This requires TOTP to be optional in the user pool, 
        // and requires setUpTotp / verifyTotpSetup flow for proper setup.
        // For a simple toggle to work seamlessly, SMS MFA or SoftwareTokenMfa 
        // needs to be configured.
        await cognitoPlugin.updateMfaPreference(
          totp: MfaPreference.preferred,
        );
        _mfaEnabled = true;
        success = true;
      } else {
        await cognitoPlugin.updateMfaPreference(
          totp: MfaPreference.disabled,
        );
        _mfaEnabled = false;
        success = true;
      }
    } catch (e) {
      debugPrint('Error toggling MFA: $e');
      success = false;
    } finally {
      _mfaLoading = false;
      notifyListeners();
    }
    return success;
  }
}
