import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/times_provider.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../features/staff/domain/staff_hours.dart';
import '../../reports/services/excel_service.dart';
import '../../reports/services/pdf_service.dart';
import '../domain/staff_models.dart';
import '../providers/staff_providers.dart';

class StaffHoursReportScreen extends ConsumerStatefulWidget {
  const StaffHoursReportScreen({super.key, required this.category});

  final StaffCategory category;

  @override
  ConsumerState<StaffHoursReportScreen> createState() =>
      _StaffHoursReportScreenState();
}

class _StaffHoursReportScreenState
    extends ConsumerState<StaffHoursReportScreen> {
  bool _allMode = false;
  Staff? _selected;
  DateTime _from = DateTime.now().subtract(const Duration(days: 29));
  DateTime _to = DateTime.now();
  bool _loading = false;
  List<StaffHoursRow>? _summary;
  List<StaffHoursDetail>? _details;
  List<String> _summaryLines = [];

  static String _fmtDuration(double hours) {
    final int totalMinutes = (hours * 60).round();
    final int h = totalMinutes ~/ 60;
    final int m = totalMinutes % 60;
    if (h == 0) return '$m دقيقة';
    if (m == 0) return '$h ساعة';
    return '$h ساعة و $m دقيقة';
  }

  static String _fmtMinutes(double hours) {
    final int minutes = (hours * 60).round();
    if (minutes < 60) return '$minutes دقيقة';
    return _fmtDuration(hours);
  }

  AutoDisposeFutureProvider<List<Staff>> get _provider =>
      widget.category == StaffCategory.employee
          ? employeesProvider
          : workersProvider;

  Future<List<Map<String, dynamic>>> _fetchLogs(int? staffId) {
    final repo = ref.read(staffRepositoryProvider);
    if (staffId == null) return repo.fetchAllLogsInRange(_from, _to);
    return repo.fetchStaffLogsInRange(staffId, _from, _to);
  }

  Future<void> _generate() async {
    if (!_allMode && _selected == null) {
      showAppSnackBar(context, 'اختر الاسم أولاً', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final AppTimes times = ref.read(appTimesProvider);
      final List<Map<String, dynamic>> logs = await _fetchLogs(
        _allMode ? null : _selected!.id,
      );

      final Map<int, List<Map<String, dynamic>>> byStaff = {};
      for (final Map<String, dynamic> row in logs) {
        byStaff
            .putIfAbsent(row['staff_id'] as int, () => [])
            .add(row);
      }

      final List<Staff> allStaff = ref.read(_provider).valueOrNull ?? [];
      final Map<int, String> names = {
        for (final Staff s in allStaff) s.id: s.fullName,
      };

      final List<StaffHoursRow> summary = [];
      List<StaffHoursDetail>? details;

      final Iterable<int> ids =
          _allMode ? byStaff.keys : [_selected!.id];

      for (final int id in ids) {
        final List<Map<String, dynamic>> staffLogs =
            byStaff[id] ?? const [];
        int presentDays = 0;
        double totalHours = 0, totalLate = 0, totalOvertime = 0;
        final List<StaffHoursDetail> staffDetails = [];

        for (final Map<String, dynamic> row in staffLogs) {
          final AttendanceMark status =
              AttendanceMark.fromDb(row['status'] as String?);
          final DateTime? checkIn = row['check_in_time'] == null
              ? null
              : DateTime.parse(row['check_in_time'] as String);
          final DateTime? checkOut = row['check_out_time'] == null
              ? null
              : DateTime.parse(row['check_out_time'] as String);
          final DateTime date =
              DateTime.parse(row['attendance_date'] as String);

          double hours = 0, late = 0, overtime = 0;
          if (checkIn != null && checkOut != null) {
            final int minutes = checkOut.difference(checkIn).inMinutes;
            hours = minutes <= 0 ? 0 : minutes / 60;
          }
          if (checkIn != null) {
            final DateTime shiftStart = DateTime(checkIn.year,
                checkIn.month, checkIn.day, times.staffStart.hour,
                times.staffStart.minute);
            final int lateMin = checkIn.difference(shiftStart).inMinutes;
            late = lateMin <= 0 ? 0 : lateMin / 60;
          }
          final double extra = hours - AppConfig.staffShiftHours;
          overtime = extra <= 0 ? 0 : extra;

          if (status == AttendanceMark.present ||
              status == AttendanceMark.late) {
            presentDays++;
          }
          totalHours += hours;
          totalLate += late;
          totalOvertime += overtime;

          staffDetails.add(StaffHoursDetail(
            dateLabel: DateFormat('EEEE d MMMM', 'ar').format(date),
            statusLabel: status.labelAr,
            inLabel: checkIn == null
                ? '-'
                : DateFormat('hh:mm a').format(checkIn),
            outLabel: checkOut == null
                ? '-'
                : DateFormat('hh:mm a').format(checkOut),
            hoursLabel: _fmtDuration(hours),
            lateLabel: _fmtMinutes(late),
            extraLabel: _fmtMinutes(overtime),
          ));
        }

        final double extraDays =
            totalOvertime / AppConfig.staffShiftHours;
        summary.add(StaffHoursRow(
          name: names[id] ?? '؟',
          presentDays: presentDays,
          totalHours: totalHours,
          lateHours: totalLate,
          overtimeHours: totalOvertime,
          extraDays: extraDays,
        ));
        if (!_allMode) {
          details = staffDetails;
          summaryLines = [
            'إجمالي الساعات والدقائق الإضافية التي داومها: ${_fmtDuration(totalOvertime)}',
            'إجمالي الساعات والدقائق الإضافية التي تأخرها: ${_fmtDuration(totalLate)}',
          ];
        }
      }

      summary.sort((a, b) => b.totalHours.compareTo(a.totalHours));
      setState(() {
        _summary = summary;
        _details = details;
      });
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'تعذر جلب التقرير', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_summary == null || _summary!.isEmpty) return;
    showLoadingDialog(context);
    try {
      final bytes = await PdfService.generateStaffHours(
        title: 'تقرير ساعات ${widget.category.pluralAr} — '
            '${DateFormat('d MMM', 'ar').format(_from)} إلى ${DateFormat('d MMM', 'ar').format(_to)}',
        rows: _summary!,
        details: _details ?? const [],
      );
      final Directory dir = await getTemporaryDirectory();
      final File file =
          File('${dir.path}/ساعات_${ExcelService.fileNameStamp()}.pdf');
      await file.writeAsBytes(bytes);
      if (mounted) hideLoadingDialog(context);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
      if (mounted) {
        hideLoadingDialog(context);
        showAppSnackBar(context, 'تعذر إنشاء PDF', isError: true);
      }
    }
  }

  Future<void> _exportExcel() async {
    if (_summary == null || _summary!.isEmpty) return;
    showLoadingDialog(context);
    try {
      final bytes = await ExcelService.generateStaffHours(
        title: 'تقرير ساعات ${widget.category.pluralAr}',
        rows: _summary!,
        details: _details ?? const [],
        summaryLines: _summaryLines,
      );
      final Directory dir = await getTemporaryDirectory();
      final File file =
          File('${dir.path}/ساعات_${ExcelService.fileNameStamp()}.xlsx');
      await file.writeAsBytes(bytes);
      if (mounted) hideLoadingDialog(context);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
      if (mounted) {
        hideLoadingDialog(context);
        showAppSnackBar(context, 'تعذر إنشاء Excel', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final staff = ref.watch(_provider);

    return Scaffold(
      appBar: AppBar(title: Text('تقرير ساعات ${widget.category.pluralAr}')),
      body: staff.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e),
        data: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('موظف محدد')),
                ButtonSegment(value: true, label: Text('جميع الموظفين')),
              ],
              selected: {_allMode},
              onSelectionChanged: (s) =>
                  setState(() => _allMode = s.first),
            ),
            const SizedBox(height: 14),
            if (!_allMode)
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
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 365)),
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
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 365)),
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
            if (_summary != null && _summary!.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('PDF'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _exportExcel,
                      icon: const Icon(Icons.table_view_rounded),
                      label: const Text('Excel'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._summary!.map(
                (r) => Card(
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primaryContainer,
                      child: Text(
                        r.name.isNotEmpty ? r.name.substring(0, 1) : '?',
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(r.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      'أيام: ${r.presentDays} • ساعات: ${r.totalHours.toStringAsFixed(1)} • '
                      'تأخير: ${r.lateHours.toStringAsFixed(1)} • '
                      'إضافي: ${r.overtimeHours.toStringAsFixed(1)} • '
                      'تعادل: ${r.extraDays.toStringAsFixed(2)} يوم',
                      style: TextStyle(
                          fontSize: 11.5, color: theme.hintColor),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
