import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/staff_models.dart';
import '../providers/staff_providers.dart';

class StaffHoursReportScreen extends ConsumerStatefulWidget {
  const StaffHoursReportScreen({super.key, required this.category});

  final StaffCategory category;

  @override
  ConsumerState<StaffHoursReportScreen> createState() =>
      _StaffHoursReportScreenState();
}

class _DayHours {
  DateTime? date;
  DateTime? checkIn;
  DateTime? checkOut;
  AttendanceMark? status;

  double get hours {
    if (checkIn == null || checkOut == null) return 0;
    final int minutes =
        checkOut!.difference(checkIn!).inMinutes;
    return minutes <= 0 ? 0 : minutes / 60;
  }

  double get lateHours {
    if (checkIn == null) return 0;
    final DateTime shiftStart = DateTime(
      checkIn!.year,
      checkIn!.month,
      checkIn!.day,
      AppConfig.staffShiftStartHour,
    );
    final int minutes = checkIn!.difference(shiftStart).inMinutes;
    return minutes <= 0 ? 0 : minutes / 60;
  }

  double get overtimeHours {
    final double extra = hours - AppConfig.staffShiftHours;
    return extra <= 0 ? 0 : extra;
  }
}

class _StaffHoursReportScreenState
    extends ConsumerState<StaffHoursReportScreen> {
  Staff? _selected;
  DateTime _from = DateTime.now().subtract(const Duration(days: 29));
  DateTime _to = DateTime.now();
  bool _loading = false;
  List<_DayHours>? _days;

  AutoDisposeFutureProvider<List<Staff>> get _provider =>
      widget.category == StaffCategory.employee
          ? employeesProvider
          : workersProvider;

  Future<void> _generate() async {
    if (_selected == null) {
      showAppSnackBar(context, 'اختر الاسم أولاً', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final logs = await ref
          .read(staffRepositoryProvider)
          .fetchStaffLogsInRange(_selected!.id, _from, _to);
      final List<_DayHours> days = logs.map<_DayHours>((row) {
        final _DayHours d = _DayHours()
          ..date = DateTime.parse(row['attendance_date'] as String)
          ..status = AttendanceMark.fromDb(row['status'] as String?);
        if (row['check_in_time'] != null) {
          d.checkIn = DateTime.parse(row['check_in_time'] as String);
        }
        if (row['check_out_time'] != null) {
          d.checkOut = DateTime.parse(row['check_out_time'] as String);
        }
        return d;
      }).toList();
      setState(() => _days = days);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'تعذر جلب التقرير', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final staff = ref.watch(_provider);

    double totalHours = 0, totalLate = 0, totalOvertime = 0;
    int presentDays = 0;
    if (_days != null) {
      for (final _DayHours d in _days!) {
        totalHours += d.hours;
        totalLate += d.lateHours;
        totalOvertime += d.overtimeHours;
        if (d.status == AttendanceMark.present ||
            d.status == AttendanceMark.late) {
          presentDays++;
        }
      }
    }
    final double extraDays =
        (totalOvertime / AppConfig.staffShiftHours);

    return Scaffold(
      appBar: AppBar(title: Text('تقرير ساعات ${widget.category.pluralAr}')),
      body: staff.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e),
        data: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<Staff>(
              value: _selected,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'اختر الاسم (${widget.category.labelAr})',
                prefixIcon: const Icon(Icons.person_rounded),
              ),
              items: list
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.fullName),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selected = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _from,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _from = picked);
                    },
                    icon: const Icon(Icons.date_range_rounded, size: 18),
                    label: Text(DateFormat('d MMM', 'ar').format(_from)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('إلى'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _to,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _to = picked);
                    },
                    icon: const Icon(Icons.date_range_rounded, size: 18),
                    label: Text(DateFormat('d MMM', 'ar').format(_to)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.calculate_rounded),
              label: const Text('احسب الساعات'),
            ),
            const SizedBox(height: 20),
            if (_days != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _totalRow(theme, 'أيام الدوام', presentDays),
                      _totalRow(theme,
                          'إجمالي الساعات', totalHours.toStringAsFixed(1)),
                      _totalRow(theme,
                          'ساعات التأخير', totalLate.toStringAsFixed(1)),
                      _totalRow(theme, 'ساعات إضافية',
                          totalOvertime.toStringAsFixed(1)),
                      _totalRow(theme,
                          'تعادل أيام عمل إضافية (كل ${AppConfig.staffShiftHours} ساعة)',
                          extraDays.toStringAsFixed(2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ..._days!.map((d) => Card(
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        switch (d.status) {
                          AttendanceMark.present => Icons.check_circle_rounded,
                          AttendanceMark.late => Icons.schedule_rounded,
                          AttendanceMark.absent => Icons.cancel_rounded,
                          null => Icons.help_outline_rounded,
                        },
                        color: switch (d.status) {
                          AttendanceMark.present => const Color(0xFF16A34A),
                          AttendanceMark.late => const Color(0xFFF59E0B),
                          AttendanceMark.absent => const Color(0xFFDC2626),
                          null => theme.hintColor,
                        },
                      ),
                      title: Text(
                        d.date == null
                            ? ''
                            : DateFormat('EEEE d MMMM', 'ar').format(d.date!),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        d.checkIn == null || d.checkOut == null
                            ? 'بدون تسجيل وقت'
                            : 'دخول ${DateFormat('hh:mm a', 'ar').format(d.checkIn!)} — '
                                'انصراف ${DateFormat('hh:mm a', 'ar').format(d.checkOut!)}',
                        style: TextStyle(
                            fontSize: 12, color: theme.hintColor),
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${d.hours.toStringAsFixed(1)} ساعة',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                          if (d.lateHours > 0)
                            Text('تأخير ${d.lateHours.toStringAsFixed(1)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFDC2626))),
                          if (d.overtimeHours > 0)
                            Text(
                                'إضافي ${d.overtimeHours.toStringAsFixed(1)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF16A34A))),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _totalRow(ThemeData theme, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(value,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
