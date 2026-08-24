import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../data/auth_repository.dart';
import '../domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

final authChangesProvider = StreamProvider.autoDispose<dynamic>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final AuthRepository repo = ref.watch(authRepositoryProvider);
  final session = repo.currentSession;
  final user = session?.user;
  if (user == null) return null;
  return repo.fetchProfile(user.id);
});
