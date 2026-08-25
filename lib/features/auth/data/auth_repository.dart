import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/supabase_retry.dart';
import '../domain/user_profile.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  Session? get currentSession => _auth.currentSession;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserProfile> fetchProfile(String userId) {
    return supabaseRetry(() async {
      final Map<String, dynamic> row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserProfile.fromJson(row);
    });
  }

  Future<void> updateProfileName(String userId, String fullName) {
    return _client.from('profiles').update({
      'full_name': fullName,
    }).eq('id', userId);
  }

  Future<void> updatePassword(String newPassword) {
    return _auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> saveOnboarding({
    required String orgName,
    required String orgType,
  }) async {
    final String uid = _auth.currentUser!.id;
    await _client.from('profiles').update({
      'org_name': orgName,
      'org_type': orgType,
    }).eq('id', uid);
  }

  Future<DateTime> activateLicense(String code) async {
    final dynamic expires = await _client.rpc(
      'activate_license',
      params: {'p_code': code},
    );
    final String uid = _auth.currentUser!.id;
    await _client.from('profiles').update({
      'licensed_until': expires.toString(),
    }).eq('id', uid);
    return DateTime.parse(expires.toString());
  }

  String generateCode() {
    const String chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final Random rng = Random.secure();
    final StringBuffer code = StringBuffer('MTB');
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 4; j++) {
        code.write(chars[rng.nextInt(chars.length)]);
      }
      if (i < 2) code.write('-');
    }
    return code.toString();
  }

  Future<void> createLicense({
    required String code,
    required String ownerName,
  }) {
    return _client.from('licenses').insert({
      'code': code,
      'owner_name': ownerName,
    });
  }

  Future<List<Map<String, dynamic>>> fetchLicenses() async {
    return await _client
        .from('licenses')
        .select()
        .order('created_at', ascending: false);
  }

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
}
