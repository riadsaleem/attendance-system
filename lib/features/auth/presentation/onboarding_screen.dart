import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/providers/auth_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const String routePath = '/onboarding';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _name = TextEditingController();
  String? _orgType;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.length < 2) {
      showAppSnackBar(context, 'أدخل الاسم', isError: true);
      return;
    }
    if (_orgType == null) {
      showAppSnackBar(context, 'اختر نوع الحساب', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .saveOnboarding(orgName: name, orgType: _orgType!);
      ref.invalidate(currentProfileProvider);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'تعذر الحفظ، حاول مجدداً', isError: true);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final List<(_String2, IconData, Color)> types = [
      (
        const _String2('staff_only', 'إدارة موظفين فقط'),
        Icons.badge_rounded,
        const Color(0xFF0EA5E9),
      ),
      (
        const _String2('school', 'مدرسة'),
        Icons.school_rounded,
        const Color(0xFF16A34A),
      ),
      (
        const _String2('university', 'جامعة / معهد'),
        Icons.account_balance_rounded,
        const Color(0xFF8B5CF6),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'لنبدأ الإعداد 👋',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'خطوة واحدة فقط — أخبرنا عن جهتك',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _name,
                    label: 'اسم الجهة *',
                    hint: 'اسم المدرسة / الجامعة / المحل / المؤسسة',
                    prefixIcon: Icons.store_rounded,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'نوع الحساب *',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  ...types.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _orgType = t.$1.type),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _orgType == t.$1.type
                                ? t.$3.withOpacity(0.12)
                                : theme.colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _orgType == t.$1.type
                                  ? t.$3
                                  : theme.colorScheme.outlineVariant
                                      .withOpacity(0.5),
                              width: _orgType == t.$1.type ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(t.$2, color: t.$3),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(t.$1.label,
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600)),
                              ),
                              if (_orgType == t.$1.type)
                                Icon(Icons.check_circle_rounded,
                                    color: t.$3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('ابدأ الاستخدام'),
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

class _String2 {
  const _String2(this.type, this.label);
  final String type;
  final String label;
}
