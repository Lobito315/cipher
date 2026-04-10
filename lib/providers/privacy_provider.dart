import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class PrivacyProvider with ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();

  bool _ghostMode = false;
  bool _stealthNotifications = false;
  bool _appLock = false;
  bool _autoDelete = false;
  bool _isLoaded = false;

  bool get ghostMode => _ghostMode;
  bool get stealthNotifications => _stealthNotifications;
  bool get appLock => _appLock;
  bool get autoDelete => _autoDelete;
  bool get isLoaded => _isLoaded;

  double get securityScore {
    double score = 60.0; // Base score
    if (_ghostMode) score += 10;
    if (_stealthNotifications) score += 10;
    if (_appLock) score += 15;
    if (_autoDelete) score += 5;
    return score > 100 ? 100 : score;
  }

  PrivacyProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _ghostMode = (await _storage.readRaw('privacy_ghost_mode')) == 'true';
    _stealthNotifications = (await _storage.readRaw('privacy_stealth_notifications')) == 'true';
    _appLock = (await _storage.readRaw('privacy_app_lock')) == 'true';
    _autoDelete = (await _storage.readRaw('privacy_auto_delete')) == 'true';
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setGhostMode(bool value) async {
    _ghostMode = value;
    await _storage.writeRaw('privacy_ghost_mode', value.toString());
    notifyListeners();
  }

  Future<void> setStealthNotifications(bool value) async {
    _stealthNotifications = value;
    await _storage.writeRaw('privacy_stealth_notifications', value.toString());
    notifyListeners();
  }

  Future<void> setAppLock(bool value) async {
    _appLock = value;
    await _storage.writeRaw('privacy_app_lock', value.toString());
    notifyListeners();
  }

  Future<void> setAutoDelete(bool value) async {
    _autoDelete = value;
    await _storage.writeRaw('privacy_auto_delete', value.toString());
    notifyListeners();
  }

  Future<void> panicWipe() async {
    // 1. Sign out from Amplify
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      debugPrint('Error signing out during panic wipe: $e');
    }

    // 2. Clear secure storage
    await _storage.deleteAll();

    // 3. Reset local state
    _ghostMode = false;
    _stealthNotifications = false;
    _appLock = false;
    _autoDelete = false;
    notifyListeners();
  }
}
