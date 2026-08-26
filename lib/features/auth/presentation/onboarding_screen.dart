import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const String routePath = '/onboarding';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OrgType {
  const _OrgType(this.type, this.label, this.subtitle, this.icon, this.color);
  final String type;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _name = TextEditingController();
  int? _selected;
  bool _saving = false;

  static const List<_OrgType> _types = [
    _OrgType('staff_only', 'إدارة موظفين فقط', 'للمحلات والمكاتب والدوام الحر',
        Icons.badge_rounded, Color(0xFF0EA5E9)),
    _OrgType('school', 'مدرسة', 'إدارة طلاب وصفوف وموظفين',
        Icons.school_rounded, Color(0xFF16A34A)),
    _OrgType('institute', 'معهد', 'تخصصات وسنوات دراسية',
        Icons.cast_for_education_rounded, Color(0xFF06B6D4)),
    _OrgType('university', 'جامعة', 'كليات وتخصصات وسنوات',
        Icons.account_balance_rounded, Color(0xFF8B5CF6)),
    _OrgType('company', 'مؤسسة / شركة', 'إدارة موظفي الفروع',
        Icons.corporate_fare_rounded, Color(0xFFF59E0B)),
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selected == null) {
      showAppSnackBar(context, 'اختر نوع الجهة أولاً', isError: true);
      return;
    }
    final String name = _name.text.trim();
    if (name.length < 2) {
      showAppSnackBar(context, 'أدخل اسم الجهة', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_org_type', _types[_selected!].type);
      await prefs.setString('pending_org_name', name);
      await prefs.setBool('onboarded', true);
      if (mounted) context.go('/login');
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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'مرحباً بك في متتبع البصمة 👋',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اختر نوع جهتك ثم اكتب اسمها — بعدها سجل دخولك أو أنشئ حساباً',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 18),
                  ...List.generate(_types.length, (i) {
                    final _OrgType t = _types[i];
                    final bool selected = _selected == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _selected = i),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected
                                ? t.color.withOpacity(0.12)
                                : theme.colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? t.color
                                  : theme.colorScheme.outlineVariant
                                      .withOpacity(0.5),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(t.icon, color: t.color),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(t.label,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                fontWeight:
                                                    FontWeight.w700)),
                                    Text(t.subtitle,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: theme.hintColor)),
                                  ],
                                ),
                              ),
                              if (selected)
                                Icon(Icons.check_circle_rounded,
                                    color: t.color),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _selected == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: AppTextField(
                              controller: _name,
                              label: 'اسم الجهة *',
                              hint: 'اكتب اسم ${_types[_selected!].label}',
                              prefixIcon: Icons.store_rounded,
                            ),
                          ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('متابعة إلى تسجيل الدخول'),
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
