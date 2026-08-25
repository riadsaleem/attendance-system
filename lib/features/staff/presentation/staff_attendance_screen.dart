import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/providers/times_provider.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/staff_models.dart';
import '../providers/staff_providers.dart';
import 'staff_hours_report_screen.dart';

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
  final Map<int, DateTime?> _checkIns = {};
  final Map<int, DateTime?> _checkOuts = {};
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
          IconButton(
            icon: const Icon(Icons.notification_important_rounded),
            tooltip: 'تنبيهات التأخير',
            onPressed: () => _showLateAlerts(context),
          ),
          IconButton(
            icon: const Icon(Icons.schedule_rounded),
            tooltip: 'تقرير الساعات',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    StaffHoursReportScreen(category: widget.category),
              ),
            ),
          ),
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
          final entries = list.map((s) {
            final saved = savedMarks[s.id];
            return StaffAttendanceEntry(
              staff: s,
              status: _edits.containsKey(s.id)
                  ? _edits[s.id]
                  : saved == null
                      ? null
                      : AttendanceMark.fromDb(saved['status'] as String?),
              checkIn: _checkIns[s.id] ??
                  (saved?['check_in_time'] == null
                      ? null
                      : DateTime.parse(saved!['check_in_time'] as String)),
              checkOut: _checkOuts[s.id] ??
                  (saved?['check_out_time'] == null
                      ? null
                      : DateTime.parse(saved!['check_out_time'] as String)),
            );
          }).toList();

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
                            if (_edits[e.staff.id] == null && !e.isMarked) {
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
                      date: _date,
                      onStatus: (status) =>
                          setState(() => _edits[entry.staff.id] = status),
                      onTime: (isIn, time) => setState(() {
                        if (isIn) {
                          _checkIns[entry.staff.id] = time;
                        } else {
                          _checkOuts[entry.staff.id] = time;
                        }
                      }),
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
                    color: color, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      );

  Future<void> _showLateAlerts(BuildContext context) async {
    showLoadingDialog(context);
    try {
      final client = ref.read(supabaseClientProvider);
      final AppTimes times = ref.read(appTimesProvider);
      final String from = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 30)));
      final rows = await client
          .from('staff_attendance')
          .select('staff_id, status, check_in_time')
          .eq('status', 'late')
          .gte('attendance_date', from);

      final Map<int, int> lateOver30 = {};
      for (final Map<String, dynamic> row in rows) {
        final String? inStr = row['check_in_time'] as String?;
        if (inStr == null) continue;
        final DateTime checkIn = DateTime.parse(inStr);
        final DateTime shiftStart = DateTime(checkIn.year, checkIn.month,
            checkIn.day, times.staffStart.hour, times.staffStart.minute);
        if (checkIn.difference(shiftStart).inMinutes > 30) {
          final int id = row['staff_id'] as int;
          lateOver30[id] = (lateOver30[id] ?? 0) + 1;
        }
      }

      final List<Staff> all =
          ref.read(_provider).valueOrNull ?? [];
      final offenders = lateOver30.entries
          .where((e) => e.value > 3)
          .map((e) => (
                name: all
                        .where((s) => s.id == e.key)
                        .map((s) => s.fullName)
                        .firstOrNull ??
                    '؟',
                count: e.value,
              ))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));

      if (context.mounted) hideLoadingDialog(context);

      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تنبيهات التأخير ⚠️'),
          content: offenders.isEmpty
              ? const Text(
                  'لا يوجد موظفون متأخرون أكثر من 30 دقيقة\nأكثر من 3 مرات خلال آخر 30 يوم 👏')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                        'تأخروا أكثر من 30 دقيقة من بداية الدوام\nأكثر من 3 مرات خلال آخر 30 يوم:'),
                    const SizedBox(height: 12),
                    ...offenders.map((o) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.warning_rounded,
                              color: Color(0xFFDC2626)),
                          title: Text(o.name),
                          trailing: Text(
                              '${o.count} مرات',
                              style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w700)),
                        )),
                  ],
                ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (context.mounted) {
        hideLoadingDialog(context);
        showAppSnackBar(context, 'تعذر جلب التنبيهات', isError: true);
      }
    }
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
        _checkIns.clear();
        _checkOuts.clear();
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

      final entries = list.map((s) {
        final saved = savedMarks[s.id];
        return StaffAttendanceEntry(
          staff: s,
          status: _edits.containsKey(s.id)
              ? _edits[s.id]
              : saved == null
                  ? null
                  : AttendanceMark.fromDb(saved['status'] as String?),
          checkIn: _checkIns[s.id] ??
              (saved?['check_in_time'] == null
                  ? null
                  : DateTime.parse(saved!['check_in_time'] as String)),
          checkOut: _checkOuts[s.id] ??
              (saved?['check_out_time'] == null
                  ? null
                  : DateTime.parse(saved!['check_out_time'] as String)),
        );
      }).where((e) => e.isMarked).toList();

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
    required this.date,
    required this.onStatus,
    required this.onTime,
  });

  final ThemeData theme;
  final StaffAttendanceEntry entry;
  final DateTime date;
  final ValueChanged<AttendanceMark?> onStatus;
  final void Function(bool isIn, DateTime? time) onTime;

  Color get _statusColor => switch (entry.status) {
        AttendanceMark.present => const Color(0xFF16A34A),
        AttendanceMark.late => const Color(0xFFF59E0B),
        AttendanceMark.absent => const Color(0xFFDC2626),
        null => theme.hintColor,
      };

  Future<void> _pickTime(BuildContext context, bool isIn) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        (isIn ? entry.checkIn : entry.checkOut) ?? DateTime.now(),
      ),
    );
    if (picked == null) return;
    onTime(
      isIn,
      DateTime(date.year, date.month, date.day, picked.hour, picked.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showTimes = entry.status != AttendanceMark.absent;

    return Card(
      color: entry.status == null ? null : _statusColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          children: [
            Row(
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
                    onStatus(selection.isEmpty ? null : selection.first);
                  },
                ),
              ],
            ),
            if (showTimes) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(context, true),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login_rounded,
                                size: 16,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              entry.checkIn == null
                                  ? 'وقت الحضور'
                                  : DateFormat('hh:mm a')
                                      .format(entry.checkIn!),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(context, false),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded,
                                size: 16, color: theme.colorScheme.error),
                            const SizedBox(width: 6),
                            Text(
                              entry.checkOut == null
                                  ? 'وقت الانصراف'
                                  : DateFormat('hh:mm a')
                                      .format(entry.checkOut!),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
