import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/state_views.dart';
import '../../auth/providers/auth_providers.dart';
import '../../staff/domain/staff_models.dart';
import '../../staff/presentation/staff_attendance_screen.dart';
import '../../students/presentation/students_screen.dart';
import 'attendance_screen.dart';

class AttendanceTabAdapter extends ConsumerWidget {
  const AttendanceTabAdapter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return profile.when(
      loading: () => const Scaffold(body: Center(child: LoadingView())),
      error: (e, _) => Scaffold(
        body: ErrorView(error: e, onRetry: () => ref.invalidate(currentProfileProvider)),
      ),
      data: (p) => (p?.isStaffOnly ?? false)
          ? const StaffAttendanceScreen(category: StaffCategory.employee)
          : const AttendanceScreen(),
    );
  }
}

class StudentsTabAdapter extends ConsumerWidget {
  const StudentsTabAdapter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return profile.when(
      loading: () => const Scaffold(body: Center(child: LoadingView())),
      error: (e, _) => Scaffold(
        body: ErrorView(error: e, onRetry: () => ref.invalidate(currentProfileProvider)),
      ),
      data: (p) => (p?.isStaffOnly ?? false)
          ? const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school_outlined, size: 56, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                        'باقتك الحالية لإدارة الموظفين فقط —\nقسم الطلاب غير مشمول'),
                  ],
                ),
              ),
            )
          : const StudentsScreen(),
    );
  }
}
