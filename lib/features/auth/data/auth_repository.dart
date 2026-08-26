import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> applyPendingSetup() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('pending_setup');
    if (raw != null) {
      final Map<String, dynamic> setup =
          jsonDecode(raw) as Map<String, dynamic>;
      final String type = setup['type'] as String;
      final String name = setup['name'] as String;
      final String uid = _auth.currentUser!.id;

      await _client.from('profiles').update({
        'org_name': name,
        'org_type': type,
        if (setup['system_type'] != null)
          'system_type': setup['system_type'] as String,
      }).eq('id', uid);

      if (setup['majors'] != null) {
        final String collegeName = type == 'university' ? name : name;
        await _client.from('colleges').insert({'name': collegeName});
        final collegeRows = await _client
            .from('colleges')
            .select('id')
            .eq('name', collegeName)
            .limit(1);
        final int collegeId = collegeRows.first['id'] as int;
        for (final String major
            in (setup['majors'] as List).cast<String>()) {
          await _client
              .from('majors')
              .insert({'name': major, 'college_id': collegeId});
        }
      }

      if (setup['branches'] != null) {
        for (final String branch
            in (setup['branches'] as List).cast<String>()) {
          await _client.from('branches').insert({'name': branch});
        }
      }

      await prefs.remove('pending_setup');
      return;
    }

    final String? type = prefs.getString('pending_org_type');
    final String? name = prefs.getString('pending_org_name');
    if (type != null && name != null) {
      await saveOnboarding(orgName: name, orgType: type);
      await prefs.remove('pending_org_type');
      await prefs.remove('pending_org_name');
    }
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
    required int durationDays,
  }) {
    return _client.from('licenses').insert({
      'code': code,
      'owner_name': ownerName,
      'duration_days': durationDays,
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
