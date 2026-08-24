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

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
}
