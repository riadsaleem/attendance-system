import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../staff/domain/staff_models.dart';
import '../../staff/providers/staff_providers.dart';
import '../../students/domain/models.dart';
import '../../students/providers/students_providers.dart';
import '../data/zk_client.dart';

class DeviceScreen extends ConsumerStatefulWidget {
  const DeviceScreen({super.key});

  @override
  ConsumerState<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends ConsumerState<DeviceScreen> {
  final TextEditingController _ip = TextEditingController();
  final TextEditingController _port =
      TextEditingController(text: '4370');
  final ZkClient _client = ZkClient();
  bool _connecting = false;
  bool _pulling = false;
  bool _connected = false;
  List<ZkLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadIp();
  }

  Future<void> _loadIp() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('zk_ip');
    if (saved != null && mounted) _ip.text = saved;
  }

  Future<void> _saveIp(String ip) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('zk_ip', ip);
  }

  Future<void> _connect() async {
    final String host = _ip.text.trim();
    if (host.isEmpty) {
      showAppSnackBar(context, 'أدخل عنوان IP للجهاز', isError: true);
      return;
    }
    setState(() => _connecting = true);
    try {
      await _client.connect(host, port: int.tryParse(_port.text) ?? 4370);
      await _saveIp(host);
      if (mounted) {
        setState(() => _connected = true);
        showAppSnackBar(context, 'تم الاتصال بالجهاز ✅');
      }
    } on ZkException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'تعذر الاتصال', isError: true);
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _pull() async {
    setState(() => _pulling = true);
    try {
      final List<ZkLog> logs = await _client.readAttendance();
      if (mounted) setState(() => _logs = logs);
      if (mounted) {
        showAppSnackBar(context, 'تم سحب ${logs.length} سجل من الجهاز');
      }
    } on ZkException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'تعذر قراءة السجلات', isError: true);
      }
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  Future<void> _import() async {
    if (_logs.isEmpty) return;
    showLoadingDialog(context);
    try {
      final client = ref.read(supabaseClientProvider);
      final String uid = client.auth.currentUser!.id;
      final List<Student> students =
          ref.read(studentsProvider).valueOrNull ?? const [];
      final List<Staff> staff =
          ref.read(employeesProvider).valueOrNull ?? const [];
      final List<Staff> workers =
          ref.read(workersProvider).valueOrNull ?? const [];

      int imported = 0, skipped = 0;
      final Map<String, List<ZkLog>> grouped = <String, List<ZkLog>>{};
      for (final ZkLog log in _logs) {
        grouped.putIfAbsent('${log.userId}', () => []).add(log);
      }

      for (final entry in grouped.entries) {
        final String fingerId = entry.key;
        final int? studentId = students
            .where((s) => s.fingerprintId == fingerId)
            .map((s) => s.id)
            .firstOrNull;
        final int? staffId = [
          ...staff,
          ...workers,
        ].where((s) => s.fingerprintId == fingerId).map((s) => s.id).firstOrNull;

        if (studentId != null) {
          final ZkLog first = entry.value.first;
          await client.from('attendance_logs').upsert({
            'student_id': studentId,
            'attendance_date':
                DateFormat('yyyy-MM-dd').format(first.timestamp),
            'check_in_time': first.timestamp.toIso8601String(),
            'status': 'present',
            'recorded_by': uid,
          }, onConflict: 'student_id,attendance_date');
          imported++;
        } else if (staffId != null) {
          final ZkLog first = entry.value.first;
          await client.from('staff_attendance').upsert({
            'staff_id': staffId,
            'attendance_date':
                DateFormat('yyyy-MM-dd').format(first.timestamp),
            'check_in_time': first.timestamp.toIso8601String(),
            'status': 'present',
            'recorded_by': uid,
          }, onConflict: 'staff_id,attendance_date');
          imported++;
        } else {
          skipped += entry.value.length;
        }
      }

      if (mounted) {
        hideLoadingDialog(context);
        showAppSnackBar(context,
            'تم استيراد $imported سجل — تجاهل $skipped (بصمة غير مطابقة)');
      }
    } catch (_) {
      if (mounted) {
        hideLoadingDialog(context);
        showAppSnackBar(context, 'تعذر الاستيراد', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _client.disconnect();
    _ip.dispose();
    _port.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ربط جهاز البصمة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        _connected
                            ? Icons.lan_rounded
                            : Icons.lan_outlined,
                        color: _connected
                            ? const Color(0xFF16A34A)
                            : theme.hintColor,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _connected
                            ? 'متصل بالجهاز'
                            : 'غير متصل',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _connected
                              ? const Color(0xFF16A34A)
                              : theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _ip,
                    label: 'عنوان IP للجهاز',
                    hint: 'مثال: 192.168.1.201',
                    prefixIcon: Icons.router_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _port,
                    label: 'المنفذ (Port)',
                    hint: '4370',
                    prefixIcon: Icons.settings_ethernet_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _connecting ? null : _connect,
                    icon: _connecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Icon(Icons.link_rounded),
                    label: Text(_connected ? 'إعادة الاتصال' : 'اتصال'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_connected) ...[
            FilledButton.tonalIcon(
              onPressed: _pulling ? null : _pull,
              icon: _pulling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Icon(Icons.download_rounded),
              label: const Text('سحب السجلات من الجهاز'),
            ),
            const SizedBox(height: 12),
          ],
          if (_logs.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'عدد السجلات: ${_logs.length}',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'تُطابق السجلات تلقائياً مع الطلاب والموظفين عبر رقم البصمة',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _import,
              icon: const Icon(Icons.upload_rounded),
              label: const Text('استيراد إلى قاعدة البيانات'),
            ),
            const SizedBox(height: 12),
            ..._logs.take(30).map(
                  (log) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.fingerprint_rounded),
                    title: Text('بصمة رقم ${log.userId}'),
                    subtitle: Text(DateFormat(
                            'yyyy/MM/dd — hh:mm a')
                        .format(log.timestamp)),
                  ),
                ),
            if (_logs.length > 30)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+ ${_logs.length - 30} سجل آخر',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ),
          ],
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'متطلبات الربط:\n'
                '• الجهاز موصول بنفس شبكة الواي فاي\n'
                '• أعطِ الجهاز عنوان IP ثابت من الراوتر\n'
                '• أرقام البصمة في التطبيق مطابقة لأرقام الجهاز\n'
                '• الطلاب: من 201 فأعلى — الموظفون: من 0 إلى 200',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
