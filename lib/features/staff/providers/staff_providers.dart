import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../data/staff_repository.dart';
import '../domain/staff_models.dart';

final staffRepositoryProvider = Provider<StaffRepository>(
  (ref) => StaffRepository(ref.watch(supabaseClientProvider)),
);

final employeesProvider = FutureProvider.autoDispose<List<Staff>>((ref) {
  return ref.watch(staffRepositoryProvider).fetchAll(
        category: StaffCategory.employee,
      );
});

final workersProvider = FutureProvider.autoDispose<List<Staff>>((ref) {
  return ref.watch(staffRepositoryProvider).fetchAll(
        category: StaffCategory.worker,
      );
});

final staffMarksForDateProvider =
    FutureProvider.autoDispose.family<Map<int, Map<String, dynamic>>, DateTime>(
        (ref, date) {
  return ref.watch(staffRepositoryProvider).fetchMarksForDate(date);
});
