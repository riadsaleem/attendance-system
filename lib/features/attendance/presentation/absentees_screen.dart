import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/state_views.dart';

class AbsenteesScreen extends ConsumerStatefulWidget {
  const AbsenteesScreen({super.key});

  static const String routePath = '/absentees';

  @override
  ConsumerState<AbsenteesScreen> createState() => _AbsenteesScreenState();
}

class _Absentee {
  final String name;
  final String className;
  final String guardianName;
  final String guardianPhone;

  const _Absentee({
    required this.name,
    required this.className,
    required this.guardianName,
    required this.guardianPhone,
  });
}

class _AbsenteesScreenState extends ConsumerState<AbsenteesScreen> {
  late final Future<List<_Absentee>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_Absentee>> _load() async {
    final client = ref.read(supabaseClientProvider);
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final rows = await client
        .from('attendance_logs')
        .select(
            'students(full_name, classes(name), guardian_name, guardian_phone)')
        .eq('attendance_date', today)
        .eq('status', 'absent');

    return rows.map<_Absentee>((Map<String, dynamic> row) {
      final Map<String, dynamic> s =
          (row['students'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      return _Absentee(
        name: (s['full_name'] ?? '؟') as String,
        className:
            ((s['classes'] as Map<String, dynamic>?)?['name'] ?? '') as String,
        guardianName: (s['guardian_name'] ?? '') as String,
        guardianPhone: (s['guardian_phone'] ?? '') as String,
      );
    }).toList();
  }

  String _normalizePhone(String raw) {
    String digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+')) digits = digits.substring(1);
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = '967${digits.substring(1)}';
    if (digits.length == 9 && digits.startsWith('7')) digits = '967$digits';
    return digits;
  }

  String _message(_Absentee a) {
    final String date = DateFormat('yyyy/MM/dd').format(DateTime.now());
    return 'السلام عليكم $a.guardianName\n'
        'نود إبلاغكم بأن ابنكم $a.name كان غائباً اليوم $date.\n'
        'نرجو المتابعة، وشكراً تعاونكم.';
  }

  Future<void> _sendWhatsApp(_Absentee a) async {
    final String phone = _normalizePhone(a.guardianPhone);
    final Uri uri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(_message(a))}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        showAppSnackBar(context, 'تعذر فتح واتساب، تأكد من تثبيته',
            isError: true);
      }
    }
  }

  Future<void> _sendSms(_Absentee a) async {
    final Uri uri = Uri(
      scheme: 'sms',
      path: _normalizePhone(a.guardianPhone),
      queryParameters: {'body': _message(a)},
    );
    if (!await launchUrl(uri)) {
      if (mounted) {
        showAppSnackBar(context, 'تعذر فتح تطبيق الرسائل', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('الغائبون اليوم')),
      body: FutureBuilder<List<_Absentee>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              error: snapshot.error!,
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final List<_Absentee> list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const EmptyView(
              icon: Icons.verified_rounded,
              title: 'لا يوجد غائبين اليوم 🎉',
              subtitle: 'جميع الطلاب حاضرون',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final _Absentee a = list[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                const Color(0xFFDC2626).withOpacity(0.12),
                            child: Text(
                              a.name.isNotEmpty ? a.name.substring(0, 1) : '?',
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  [
                                    if (a.className.isNotEmpty) a.className,
                                    if (a.guardianName.isNotEmpty)
                                      'ولي الأمر: ${a.guardianName}',
                                    if (a.guardianPhone.isNotEmpty)
                                      a.guardianPhone,
                                  ].join(' • '),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (a.guardianPhone.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42),
                                  backgroundColor: const Color(0xFF25D366),
                                ),
                                onPressed: () => _sendWhatsApp(a),
                                icon: const Icon(Icons.chat_rounded,
                                    size: 18, color: Colors.white),
                                label: const Text('واتساب',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42),
                                ),
                                onPressed: () => _sendSms(a),
                                icon: const Icon(Icons.sms_rounded, size: 18),
                                label: const Text('رسالة SMS'),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'لا يوجد رقم لولي الأمر — أضفه من ملف الطالب',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
