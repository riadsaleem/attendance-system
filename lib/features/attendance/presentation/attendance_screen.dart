import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/state_views.dart';
import '../../students/providers/students_providers.dart';
import '../domain/attendance_models.dart';
import '../providers/attendance_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _date = DateTime.now();
  int? _classId;
  final Map<int, AttendanceStatus?> _edits = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final classes = ref.watch(classesProvider);
    final students = ref.watch(studentsProvider);
    final logs = ref.watch(logsForDateProvider(_date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('الحضور اليومي'),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(DateFormat('d MMM', 'ar').format(_date)),
          ),
        ],
      ),
      body: classes.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(classesProvider),
        ),
        data: (classList) {
          if (classList.isEmpty) {
            return const EmptyView(
              icon: Icons.school_outlined,
              title: 'لا توجد صفوف',
              subtitle: 'أضف الصفوف أولاً من شاشة الطلاب',
            );
          }
          _classId ??= classList.first.id;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: DropdownButtonFormField<int>(
                  value: _classId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.class_rounded),
                  ),
                  items: classList
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.displayName),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _classId = v;
                    _edits.clear();
                  }),
                ),
              ),
              students.when(
                loading: () => const Expanded(child: LoadingView()),
                error: (e, _) => Expanded(
                  child: ErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(studentsProvider),
                  ),
                ),
                data: (allStudents) {
                  final classStudents = allStudents
                      .where((s) => s.classId == _classId)
                      .toList();
                  final savedLogs = logs.valueOrNull ?? const {};

                  if (classStudents.isEmpty) {
                    return const Expanded(
                      child: EmptyView(
                        icon: Icons.people_outline_rounded,
                        title: 'لا يوجد طلاب في هذا الصف',
                      ),
                    );
                  }

                  final entries = classStudents
                      .map((s) => AttendanceEntry(
                            student: s,
                            status: _edits.containsKey(s.id)
                                ? _edits[s.id]
                                : _statusFromName(savedLogs[s.id]),
                          ))
                      .toList();
                  final summary = AttendanceSummary.fromEntries(entries);

                  return Expanded(
                    child: Column(
                      children: [
                        _SummaryRow(theme: theme, summary: summary),
                        _ActionBar(
                          theme: theme,
                          onAllPresent: () => setState(() {
                            for (final e in entries) {
                              _edits[e.student.id] = AttendanceStatus.present;
                            }
                          }),
                          onMarkAbsent: () => setState(() {
                            for (final e in entries) {
                              if (!e.isMarked ||
                                  _edits[e.student.id] == null) {
                                _edits[e.student.id] =
                                    AttendanceStatus.absent;
                              }
                            }
                          }),
                          onClear: _edits.isEmpty
                              ? null
                              : () => setState(() => _edits.clear()),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return _StudentAttendanceRow(
                                theme: theme,
                                entry: entry,
                                onChanged: (status) => setState(
                                    () => _edits[entry.student.id] = status),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: FilledButton.icon(
                            onPressed:
                                _saving || summary.marked == 0 ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                                'حفظ الحضور (${summary.marked} طالب)'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  AttendanceStatus? _statusFromName(String? name) {
    if (name == null) return null;
    return AttendanceStatus.fromDb(name);
  }

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
      final userId =
          ref.read(supabaseClientProvider).auth.currentUser!.id;
      final classStudents = (ref.read(studentsProvider).valueOrNull ?? const [])
          .where((s) => s.classId == _classId)
          .toList();
      final savedLogs =
          ref.read(logsForDateProvider(_date)).valueOrNull ?? const {};

      final entries = classStudents
          .map((s) => AttendanceEntry(
                student: s,
                status: _edits.containsKey(s.id)
                    ? _edits[s.id]
                    : _statusFromName(savedLogs[s.id]),
              ))
          .where((e) => e.isMarked)
          .toList();

      await ref.read(attendanceRepositoryProvider).upsertEntries(
            entries: entries,
            date: _date,
            recordedBy: userId,
          );

      ref.invalidate(logsForDateProvider(_date));
      ref.invalidate(dashboardProvider);
      if (mounted) {
        setState(() {
          _saving = false;
          _edits.clear();
        });
        showAppSnackBar(context, 'تم حفظ الحضور بنجاح ✅');

        final int absentCount =
            entries.where((e) => e.status == AttendanceStatus.absent).length;
        if (absentCount > 0 && mounted) {
          final bool? notify = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('إبلاغ أولياء الأمور 📨'),
              content: Text(
                  'يوجد $absentCount غائباً اليوم.\nهل تريد فتح قائمة الغائبين لإرسال إشعار لولي أمر كل طالب؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('لاحقاً'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('إبلاغ الآن'),
                ),
              ],
            ),
          );
          if (notify == true && mounted) {
            context.push('/absentees');
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnackBar(context, 'تعذر الحفظ، حاول مجدداً', isError: true);
      }
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.theme, required this.summary});

  final ThemeData theme;
  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, int count, Color color) => Container(
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
              Text(label,
                  style: TextStyle(color: color, fontSize: 13)),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          chip('حاضر', summary.present,
              Color(AttendanceStatus.present.colorValue)),
          chip('متأخر', summary.late, Color(AttendanceStatus.late.colorValue)),
          chip('غائب', summary.absent,
              Color(AttendanceStatus.absent.colorValue)),
          if (summary.unmarked > 0)
            chip('غير محدد', summary.unmarked, theme.hintColor),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.theme,
    required this.onAllPresent,
    required this.onMarkAbsent,
    required this.onClear,
  });

  final ThemeData theme;
  final VoidCallback onAllPresent;
  final VoidCallback onMarkAbsent;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                foregroundColor: theme.colorScheme.primary,
              ),
              onPressed: onAllPresent,
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
              onPressed: onMarkAbsent,
              icon: const Icon(Icons.person_off_outlined, size: 18),
              label: const Text('الغائبين تلقائياً'),
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onClear,
              tooltip: 'مسح التعديلات',
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentAttendanceRow extends StatelessWidget {
  const _StudentAttendanceRow({
    required this.theme,
    required this.entry,
    required this.onChanged,
  });

  final ThemeData theme;
  final AttendanceEntry entry;
  final ValueChanged<AttendanceStatus?> onChanged;

  Color get _statusColor => switch (entry.status) {
        AttendanceStatus.present =>
          Color(AttendanceStatus.present.colorValue),
        AttendanceStatus.late => Color(AttendanceStatus.late.colorValue),
        AttendanceStatus.absent => Color(AttendanceStatus.absent.colorValue),
        null => theme.hintColor,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: entry.status == null
          ? null
          : _statusColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.student.fullName,
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
            SegmentedButton<AttendanceStatus>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                selectedForegroundColor: Colors.white,
              ),
              segments: const [
                ButtonSegment(
                  value: AttendanceStatus.present,
                  icon: Icon(Icons.check_rounded, size: 18),
                  tooltip: 'حاضر',
                ),
                ButtonSegment(
                  value: AttendanceStatus.late,
                  icon: Icon(Icons.schedule_rounded, size: 18),
                  tooltip: 'متأخر',
                ),
                ButtonSegment(
                  value: AttendanceStatus.absent,
                  icon: Icon(Icons.close_rounded, size: 18),
                  tooltip: 'غائب',
                ),
              ],
              selected: entry.status == null
                  ? {}
                  : {entry.status!},
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
