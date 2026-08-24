import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/staff_models.dart';
import '../providers/staff_providers.dart';

class StaffAttendanceScreen extends ConsumerStatefulWidget {
  const StaffAttendanceScreen({super.key, required this.category});

  final StaffCategory category;

  @override
  ConsumerState<StaffAttendanceScreen> createState() =>
      _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends ConsumerState<StaffAttendanceScreen> {
  DateTime _date = DateTime.now();
  final Map<int, AttendanceMark?> _edits = {};
  bool _saving = false;

  AutoDisposeFutureProvider<List<Staff>> get _provider =>
      widget.category == StaffCategory.employee
          ? employeesProvider
          : workersProvider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final staff = ref.watch(_provider);
    final marks = ref.watch(staffMarksForDateProvider(_date));

    return Scaffold(
      appBar: AppBar(
        title: Text('حضور ${widget.category.pluralAr}'),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(DateFormat('d MMM', 'ar').format(_date)),
          ),
        ],
      ),
      body: staff.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(_provider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.badge_outlined,
              title: 'لا توجد سجلات',
              subtitle: 'أضف السجلات أولاً من شاشة ${widget.category.pluralAr}',
            );
          }

          final savedMarks = marks.valueOrNull ?? {};
          final entries = list
              .map((s) => StaffAttendanceEntry(
                    staff: s,
                    status: _edits.containsKey(s.id)
                        ? _edits[s.id]
                        : savedMarks[s.id] == null
                            ? null
                            : AttendanceMark.fromDb(savedMarks[s.id]),
                  ))
              .toList();

          int present = 0, late = 0, absent = 0, unmarked = 0;
          for (final e in entries) {
            switch (e.status) {
              case AttendanceMark.present:
                present++;
              case AttendanceMark.late:
                late++;
              case AttendanceMark.absent:
                absent++;
              case null:
                unmarked++;
            }
          }

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _chip('حاضر', present, const Color(0xFF16A34A)),
                    _chip('متأخر', late, const Color(0xFFF59E0B)),
                    _chip('غائب', absent, const Color(0xFFDC2626)),
                    if (unmarked > 0)
                      _chip('غير محدد', unmarked, theme.hintColor),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          foregroundColor: theme.colorScheme.primary,
                        ),
                        onPressed: () => setState(() {
                          for (final e in entries) {
                            _edits[e.staff.id] = AttendanceMark.present;
                          }
                        }),
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: const Text('الكل حاضر'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: () => setState(() {
                          for (final e in entries) {
                            if (_edits[e.staff.id] == null &&
                                !e.isMarked) {
                              _edits[e.staff.id] = AttendanceMark.absent;
                            }
                          }
                        }),
                        icon: const Icon(Icons.person_off_outlined, size: 18),
                        label: const Text('الغائبين تلقائياً'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _StaffRow(
                      theme: theme,
                      entry: entry,
                      onChanged: (status) =>
                          setState(() => _edits[entry.staff.id] = status),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('حفظ الحضور'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, int count, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      );

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _edits.clear();
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final userId = ref.read(supabaseClientProvider).auth.currentUser!.id;
      final list = ref.read(_provider).valueOrNull ?? [];
      final savedMarks =
          ref.read(staffMarksForDateProvider(_date)).valueOrNull ?? {};

      final entries = list
          .map((s) => StaffAttendanceEntry(
                staff: s,
                status: _edits.containsKey(s.id)
                    ? _edits[s.id]
                    : savedMarks[s.id] == null
                        ? null
                        : AttendanceMark.fromDb(savedMarks[s.id]),
              ))
          .where((e) => e.isMarked)
          .toList();

      await ref.read(staffRepositoryProvider).upsertAttendance(
            entries: entries,
            date: _date,
            recordedBy: userId,
          );

      ref.invalidate(staffMarksForDateProvider(_date));
      if (mounted) {
        setState(() {
          _saving = false;
          _edits.clear();
        });
        showAppSnackBar(context, 'تم حفظ الحضور بنجاح ✅');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnackBar(context, 'تعذر الحفظ، حاول مجدداً', isError: true);
      }
    }
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.theme,
    required this.entry,
    required this.onChanged,
  });

  final ThemeData theme;
  final StaffAttendanceEntry entry;
  final ValueChanged<AttendanceMark?> onChanged;

  Color get _statusColor => switch (entry.status) {
        AttendanceMark.present => const Color(0xFF16A34A),
        AttendanceMark.late => const Color(0xFFF59E0B),
        AttendanceMark.absent => const Color(0xFFDC2626),
        null => theme.hintColor,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: entry.status == null ? null : _statusColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.staff.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  if (entry.status != null)
                    Text(
                      entry.status!.labelAr,
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            SegmentedButton<AttendanceMark>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                selectedForegroundColor: Colors.white,
              ),
              segments: const [
                ButtonSegment(
                  value: AttendanceMark.present,
                  icon: Icon(Icons.check_rounded, size: 18),
                  tooltip: 'حاضر',
                ),
                ButtonSegment(
                  value: AttendanceMark.late,
                  icon: Icon(Icons.schedule_rounded, size: 18),
                  tooltip: 'متأخر',
                ),
                ButtonSegment(
                  value: AttendanceMark.absent,
                  icon: Icon(Icons.close_rounded, size: 18),
                  tooltip: 'غائب',
                ),
              ],
              selected: entry.status == null ? {} : {entry.status!},
              onSelectionChanged: (selection) {
                onChanged(selection.isEmpty ? null : selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}
