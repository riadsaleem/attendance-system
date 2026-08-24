import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../data/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(ref.watch(supabaseClientProvider)),
);

final logsForDateProvider =
    FutureProvider.autoDispose.family<Map<int, String>, DateTime>(
  (ref, date) async {
    final logs =
        await ref.watch(attendanceRepositoryProvider).fetchForDate(date);
    return {for (final log in logs) log.studentId: log.status.name};
  },
);
