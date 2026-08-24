import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../students/domain/models.dart';
import '../../students/providers/students_providers.dart';
import '../data/reports_repository.dart';
import '../domain/report_models.dart';
import '../services/excel_service.dart';
import '../services/pdf_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportType _type = ReportType.daily;
  int? _classId;
  DateTime _anchor = DateTime.now();
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  bool _loading = false;
  bool _splitClasses = true;
  List<ReportData>? _reports;

  ReportsRepository get _repo =>
      ReportsRepository(ref.read(supabaseClientProvider));

  String _periodLabel() {
    if (_type == ReportType.custom) {
      return '${DateFormat('d MMM', 'ar').format(_from)} - ${DateFormat('d MMM', 'ar').format(_to)}';
    }
    if (_type == ReportType.monthly) {
      return DateFormat('MMMM yyyy', 'ar').format(_anchor);
    }
    if (_type == ReportType.weekly) {
      return 'الأسبوع (${DateFormat('d MMM', 'ar').format(_anchor)})';
    }
    return DateFormat('d MMMM yyyy', 'ar').format(_anchor);
  }

  (DateTime, DateTime) _resolveDates() {
    switch (_type) {
      case ReportType.daily:
        return (_anchor, _anchor);
      case ReportType.weekly:
        final int daysFromSaturday = (_anchor.weekday + 1) % 7;
        final DateTime from = _anchor.subtract(Duration(days: daysFromSaturday));
        return (from, from.add(const Duration(days: 6)));
      case ReportType.monthly:
        return (
          DateTime(_anchor.year, _anchor.month, 1),
          DateTime(_anchor.year, _anchor.month + 1, 0)
        );
      case ReportType.custom:
        final DateTime from = DateTime(_from.year, _from.month, _from.day);
        final DateTime to = DateTime(_to.year, _to.month, _to.day, 23, 59);
        return (from, to);
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
          if (_to.isBefore(_from)) _to = _from;
        } else {
          _to = picked;
        }
        _reports = null;
      });
    }
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final classes = ref.read(classesProvider).valueOrNull ?? [];
      final String className = _classId == null
          ? 'كل الصفوف'
          : classes.firstWhere((c) => c.id == _classId).displayName;
      final (DateTime from, DateTime to) = _resolveDates();
      final String periodLabel = _periodLabel();

      if (_classId == null && _splitClasses) {
        _reports = await _repo.buildPerClassReports(
          type: _type,
          from: from,
          to: to,
          periodLabel: periodLabel,
        );
      } else {
        final ReportData report = await _repo.buildReportForRange(
          type: _type,
          from: from,
          to: to,
          periodLabel: periodLabel,
          classId: _classId,
          className: className,
        );
        _reports = [report];
      }
      setState(() {});
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'تعذر إنشاء التقرير', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportPdf() async {
    final List<ReportData> reports = _reports ?? [];
    if (reports.isEmpty) return;
    showLoadingDialog(context);
    try {
      final bytes = await PdfService.generateMulti(reports);
      final Directory dir = await getTemporaryDirectory();
      final File file =
          File('${dir.path}/تقرير_${ExcelService.fileNameStamp()}.pdf');
      await file.writeAsBytes(bytes);
      if (mounted) hideLoadingDialog(context);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: reports.first.titleAr,
      );
    } catch (_) {
      if (mounted) {
        hideLoadingDialog(context);
        showAppSnackBar(context, 'تعذر إنشاء ملف PDF', isError: true);
      }
    }
  }

  Future<void> _exportExcel() async {
    final List<ReportData> reports = _reports ?? [];
    if (reports.isEmpty) return;
    showLoadingDialog(context);
    try {
      final bytes = ExcelService.generate(reports);
      final Directory dir = await getTemporaryDirectory();
      final File file =
          File('${dir.path}/تقرير_${ExcelService.fileNameStamp()}.xlsx');
      await file.writeAsBytes(bytes);
      if (mounted) hideLoadingDialog(context);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'تقرير Excel',
      );
    } catch (_) {
      if (mounted) {
        hideLoadingDialog(context);
        showAppSnackBar(context, 'تعذر إنشاء ملف Excel', isError: true);
      }
    }
  }

  Future<void> _shareText() async {
    final List<ReportData> reports = _reports ?? [];
    if (reports.isEmpty) return;
    final String text =
        reports.map((r) => r.textSummary).join('\n──────────────\n');
    await Share.share(text, subject: reports.first.titleAr);
  }

  Future<void> _copyText() async {
    final List<ReportData> reports = _reports ?? [];
    if (reports.isEmpty) return;
    final String text =
        reports.map((r) => r.textSummary).join('\n──────────────\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showAppSnackBar(context, 'تم نسخ التقرير');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final classes = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: classes.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(classesProvider),
        ),
        data: (classList) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<ReportType>(
              segments: ReportType.values
                  .map((t) => ButtonSegment(value: t, label: Text(t.labelAr)))
                  .toList(),
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _reports = null;
              }),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int?>(
              value: _classId,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.class_rounded),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('كل الصفوف')),
                ...classList.map(
                  (SchoolClass c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.displayName),
                  ),
                ),
              ],
              onChanged: (v) => setState(() {
                _classId = v;
                _reports = null;
              }),
            ),
            const SizedBox(height: 12),
            if (_type == ReportType.custom) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isFrom: true),
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
                      onPressed: () => _pickDate(isFrom: false),
                      icon: const Icon(Icons.date_range_rounded, size: 18),
                      label: Text(DateFormat('d MMM', 'ar').format(_to)),
                    ),
                  ),
                ],
              ),
            ] else
              OutlinedButton.icon(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _anchor,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _anchor = picked;
                      _reports = null;
                    });
                  }
                },
                icon: const Icon(Icons.date_range_rounded),
                label: Text(_periodLabel()),
              ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.assessment_rounded),
              label: const Text('إنشاء التقرير'),
            ),
            const SizedBox(height: 20),
            if (_reports != null) ...[
              ..._reports!.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReportPreview(theme: theme, report: r),
                ),
              ),
              const SizedBox(height: 6),
              if (_classId == null && _reports!.length > 1)
                CheckboxListTile(
                  value: _splitClasses,
                  onChanged: (v) => setState(() => _splitClasses = v ?? true),
                  title: const Text('كل فصل في صفحة مستقلة'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareText,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('مشاركة'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyText,
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('نسخ'),
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

class _ReportPreview extends StatelessWidget {
  const _ReportPreview({required this.theme, required this.report});

  final ThemeData theme;
  final ReportData report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment_rounded,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${report.titleAr} — ${report.className}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              report.periodLabel,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 74,
                  height: 74,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 16,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          value: report.summary.present.toDouble(),
                          color: const Color(0xFF16A34A),
                          radius: 15,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: report.summary.late.toDouble(),
                          color: const Color(0xFFF59E0B),
                          radius: 15,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: report.summary.absent.toDouble(),
                          color: const Color(0xFFDC2626),
                          radius: 15,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _legendDot(const Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          const Text('حاضر'),
                          const Spacer(),
                          Text('${report.summary.present}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Row(
                        children: [
                          _legendDot(const Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          const Text('متأخر'),
                          const Spacer(),
                          Text('${report.summary.late}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Row(
                        children: [
                          _legendDot(const Color(0xFFDC2626)),
                          const SizedBox(width: 4),
                          const Text('غائب'),
                          const Spacer(),
                          Text('${report.summary.absent}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${report.summary.rate.toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                      ),
                      const Text('الحضور',
                          style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
