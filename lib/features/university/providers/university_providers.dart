import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../data/university_repository.dart';
import '../domain/models.dart';

final universityRepositoryProvider = Provider<UniversityRepository>(
  (ref) => UniversityRepository(ref.watch(supabaseClientProvider)),
);

final collegesProvider = FutureProvider.autoDispose<List<College>>((ref) {
  return ref.watch(universityRepositoryProvider).fetchColleges();
});

final majorsProvider = FutureProvider.autoDispose<List<Major>>((ref) {
  return ref.watch(universityRepositoryProvider).fetchMajors();
});
