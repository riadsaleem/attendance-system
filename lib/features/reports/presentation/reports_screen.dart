import 'dart:io';

import 'package:flutter/material.dart';
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
  bool _loading = false;
  ReportData? _report;

  ReportsRepository get _repo =>
      ReportsRepository(ref.read(supabaseClientProvider));

  String _periodLabel() => switch (_type) {
        ReportType.daily =>
          DateFormat('d MMMM yyyy', 'ar').format(_anchor),
        ReportType.monthly => DateFormat('MMMM yyyy', 'ar').format(_anchor),
        ReportType.weekly => 'الأسبوع الحالي (${DateFormat('d MMM', 'ar').format(_anchor)})',
      };

  Future<void> _pickPeriod() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _anchor,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _anchor = picked;
        _report = null;
      });
    }
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final classes = ref.read(classesProvider).valueOrNull ?? const [];
      final String className = _classId == null
          ? 'كل الصفوف'
          : classes.firstWhere((c) => c.id == _classId).displayName;

      final ReportData report = await _repo.buildReport(
        type: _type,
        anchor: _anchor,
        classId: _classId,
        className: className,
      );
      setState(() => _report = report);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'تعذر إنشاء التقرير', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportPdf(ReportData report) async {
    showLoadingDialog(context);
    try {
      final Uint8List bytes = await PdfService.generate(report);
      final Directory dir = await getTemporaryDirectory();
      final String stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final File file = File('${dir.path}/تقرير_$stamp.pdf');
      await file.writeAsBytes(bytes);
      if (mounted) hideLoadingDialog(context);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: report.titleAr,
        subject: report.titleAr,
      );
    } catch (_) {
      if (mounted) {
        hideLoadingDialog(context);
        showAppSnackBar(context, 'تعذر إنشاء ملف PDF', isError: true);
      }
    }
  }

  Future<void> _shareText(ReportData report) async {
    await Share.share(report.textSummary, subject: report.titleAr);
  }

  Future<void> _copyText(ReportData report) async {
    await Clipboard.setData(ClipboardData(text: report.textSummary));
    if (mounted) {
      showAppSnackBar(context, 'تم نسخ ملخص التقرير');
    }
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
                  .map((t) => ButtonSegment(
                        value: t,
                        label: Text(t.labelAr),
                      ))
                  .toList(),
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _report = null;
              }),
            ),
            const SizedBox(height: 16),
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
                _report = null;
              }),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickPeriod,
              icon: const Icon(Icons.date_range_rounded),
              label: Text(_periodLabel()),
            ),
            const SizedBox(height: 16),
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
            if (_report != null) ...[
              _ReportPreview(theme: theme, report: _report!),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _exportPdf(_report!),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('PDF'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareText(_report!),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('مشاركة'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyText(_report!),
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
    Widget stat(String label, String value, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment_rounded,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.titleAr,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${report.className} — ${report.periodLabel}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                stat('حاضر', '${report.summary.present}',
                    const Color(0xFF16A34A)),
                stat('متأخر', '${report.summary.late}',
                    const Color(0xFFF59E0B)),
                stat('غائب', '${report.summary.absent}',
                    const Color(0xFFDC2626)),
                stat(
                  'النسبة',
                  '${report.summary.rate.toStringAsFixed(1)}%',
                  theme.colorScheme.primary,
                ),
              ],
            ),
            if (report.rows.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...report.rows.take(10).map(
                    (row) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.studentName,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '${row.present} حاضر',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF16A34A)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${row.absent} غائب',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (report.rows.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '+ ${report.rows.length - 10} طالب آخرين (التفاصيل في PDF)',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
