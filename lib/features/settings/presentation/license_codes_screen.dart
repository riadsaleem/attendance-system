import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../auth/providers/auth_providers.dart';

class LicenseCodesScreen extends ConsumerStatefulWidget {
  const LicenseCodesScreen({super.key});

  @override
  ConsumerState<LicenseCodesScreen> createState() =>
      _LicenseCodesScreenState();
}

class _LicenseCodesScreenState extends ConsumerState<LicenseCodesScreen> {
  List<Map<String, dynamic>>? _codes;

  Future<void> _load() async {
    final codes = await ref.read(authRepositoryProvider).fetchLicenses();
    if (mounted) setState(() => _codes = codes);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _create() async {
    final TextEditingController name = TextEditingController();
    int durationDays = 365;

    final (String?, int?)? result = await showDialog<
        (String?, int?)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('كود تفعيل جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: name,
                label: 'اسم صاحب الكود',
                hint: 'مثال: اكرم الثوابي',
                prefixIcon: Icons.person_rounded,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: durationDays,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'مدة الصلاحية',
                  prefixIcon: Icon(Icons.date_range_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 30, child: Text('شهر واحد')),
                  DropdownMenuItem(value: 90, child: Text('3 أشهر')),
                  DropdownMenuItem(value: 365, child: Text('سنة كاملة')),
                  DropdownMenuItem(value: 1825, child: Text('5 سنوات')),
                  DropdownMenuItem(value: 3650, child: Text('10 سنوات')),
                ],
                onChanged: (v) => setState(() => durationDays = v ?? 365),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, (name.text.trim(), durationDays)),
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    final (String? ownerName, int? duration) = result;
    if (ownerName == null || ownerName.isEmpty) return;
    final int days = duration ?? 365;

    showLoadingDialog(context);
    try {
      final String code = ref.read(authRepositoryProvider).generateCode();
      await ref
          .read(authRepositoryProvider)
          .createLicense(
            code: code,
            ownerName: ownerName,
            durationDays: days,
          );
      await _load();
      if (mounted) {
        hideLoadingDialog(context);
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تم إنشاء الكود ✅'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('الكود الخاص بـ $ownerName:'),
                const SizedBox(height: 10),
                SelectableText(
                  code,
                  style: bigCodeStyle(context),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('تم'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        hideLoadingDialog(context);
        showAppSnackBar(context, 'تعذر إنشاء الكود', isError: true);
      }
    }
  }

  TextStyle bigCodeStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.primary,
          );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('أكواد التفعيل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            tooltip: 'كود جديد',
            onPressed: _create,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add_rounded),
      ),
      body: _codes == null
          ? const Center(child: CircularProgressIndicator())
          : _codes!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.key_rounded,
                          size: 56, color: theme.hintColor),
                      const SizedBox(height: 12),
                      const Text('لا توجد أكواد بعد'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _codes!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final Map<String, dynamic> lic = _codes![index];
                      final bool used = lic['activated_by'] != null;
                      final DateTime? expires = lic['expires_at'] == null
                          ? null
                          : DateTime.parse(lic['expires_at'] as String);
                      final bool expired =
                          expires != null && expires.isBefore(DateTime.now());

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            used
                                ? (expired
                                    ? Icons.lock_rounded
                                    : Icons.verified_rounded)
                                : Icons.vpn_key_rounded,
                            color: !used
                                ? theme.colorScheme.primary
                                : expired
                                    ? theme.colorScheme.error
                                    : const Color(0xFF16A34A),
                          ),
                          title: Text(
                            '${lic['owner_name']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                '${lic['code']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  letterSpacing: 1,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                used
                                    ? (expired
                                        ? 'منتهي الصلاحية'
                                        : 'مفعّل — ينتهي ${DateFormat('yyyy/MM/dd').format(expires!)}')
                                    : 'غير مستخدم',
                                style: TextStyle(
                                    fontSize: 12, color: theme.hintColor),
                              ),
                            ],
                          ),
                          trailing: !used
                              ? IconButton(
                                  icon: const Icon(Icons.copy_rounded,
                                      size: 20),
                                  tooltip: 'نسخ الكود',
                                  onPressed: () {
                                    showAppSnackBar(
                                        context, 'الكود: ${lic['code']}');
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
