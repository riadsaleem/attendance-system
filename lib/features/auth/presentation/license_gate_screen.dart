import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/providers/auth_providers.dart';

class LicenseGateScreen extends ConsumerStatefulWidget {
  const LicenseGateScreen({super.key});

  static const String routePath = '/license-gate';

  @override
  ConsumerState<LicenseGateScreen> createState() => _LicenseGateScreenState();
}

class _LicenseGateScreenState extends ConsumerState<LicenseGateScreen> {
  final TextEditingController _code = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final String code = _code.text.trim();
    if (code.isEmpty) {
      showAppSnackBar(context, 'أدخل كود التفعيل', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final DateTime expires =
          await ref.read(authRepositoryProvider).activateLicense(code);
      ref.invalidate(currentProfileProvider);
      if (mounted) {
        showAppSnackBar(context,
            'تم التفعيل بنجاح ✅ — صالح حتى ${DateFormat('yyyy/MM/dd').format(expires)}');
      }
    } catch (e) {
      if (mounted) {
        String message = 'تعذر التفعيل، حاول مجدداً';
        if (e.toString().contains('غير صالح أو مستخدم')) {
          message = 'الكود غير صالح أو مستخدم من قبل';
        }
        showAppSnackBar(context, message, isError: true);
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Icon(
                      Icons.key_rounded,
                      size: 44,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'تفعيل الاشتراك',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'انتهت فترة التجربة المجانية.\n'
                    'أدخل كود التفعيل الذي حصلت عليه للاستمرار — '
                    'الكود يمنحك اشتراكاً كاملاً لمدة سنة.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    controller: _code,
                    label: 'كود التفعيل',
                    hint: 'MTB-XXXX-XXXX-XXXX',
                    prefixIcon: Icons.key_rounded,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _activate(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _activate,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('تفعيل'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'للحصول على كود تواصل مع المطور',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
