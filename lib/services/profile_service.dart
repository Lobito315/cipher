import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> updatePublicKey(String userId, String publicKeyBase64) async {
    await _supabase.from('profiles').upsert({
      'id': userId,
      'public_key': publicKeyBase64,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String?> getPublicKey(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select('public_key')
        .eq('id', userId)
        .single();
    return data['public_key'] as String?;
  }

  /// Search for a user by email/ID and return their profile with public key
  Future<Map<String, dynamic>?> searchUser(String identifier) async {
    // This assumes we have an email column or similar in profiles
    // For simplicity, we search by ID for now, or you might need a more complex search
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .or('id.eq.$identifier,email.eq.$identifier')
          .single();
      return data;
    } catch (e) {
      return null;
    }
  }
}
