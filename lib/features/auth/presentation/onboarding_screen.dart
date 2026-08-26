import 'dart:convert';

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
  const _OrgType(this.type, this.label, this.subtitle, this.placeholder,
      this.icon, this.color);
  final String type;
  final String label;
  final String subtitle;
  final String placeholder;
  final IconData icon;
  final Color color;
}

const List<_OrgType> kOrgTypes = [
  _OrgType(
      'staff_only',
      'إدارة موظفين فقط',
      'للمحلات والمكاتب والمراكز الصغيرة',
      'اكتب اسم المركز أو المحل أو المكتب',
      Icons.badge_rounded,
      Color(0xFF0EA5E9)),
  _OrgType(
      'school',
      'مدرسة',
      'إدارة طلاب وصفوف وموظفين',
      'اكتب اسم المدرسة',
      Icons.school_rounded,
      Color(0xFF16A34A)),
  _OrgType(
      'institute',
      'معهد',
      'إدارة موظفين وتخصصات وطلاب',
      'اكتب اسم المعهد',
      Icons.cast_for_education_rounded,
      Color(0xFF06B6D4)),
  _OrgType(
      'university',
      'جامعة',
      'إدارة كليات وتخصصات وموظفين وطلاب',
      'اكتب اسم الجامعة أو الكلية',
      Icons.account_balance_rounded,
      Color(0xFF8B5CF6)),
  _OrgType(
      'company',
      'مؤسسة أو شركة',
      'إدارة الفروع وموظفيها',
      'اكتب اسم المؤسسة أو الشركة',
      Icons.corporate_fare_rounded,
      Color(0xFFF59E0B)),
];

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final List<String> _items = [];
  int _selected = -1;
  String _systemType = 'years';
  bool _saving = false;

  _OrgType? get _type => _selected == -1 ? null : kOrgTypes[_selected];

  bool get _needsMajors =>
      _type != null && (_type!.type == 'institute' || _type!.type == 'university');

  bool get _needsBranches =>
      _type != null && _type!.type == 'company';

  bool get _needsSystemChoice => _type != null && _type!.type == 'institute';

  @override
  void dispose() {
    _name.dispose();
    _itemController.dispose();
    super.dispose();
  }

  void _addItem() {
    final String value = _itemController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _items.add(value);
      _itemController.clear();
    });
  }

  Future<void> _save() async {
    if (_selected == -1) {
      showAppSnackBar(context, 'اختر نوع الجهة أولاً', isError: true);
      return;
    }
    final String name = _name.text.trim();
    if (name.length < 2) {
      showAppSnackBar(context, 'أدخل اسم الجهة', isError: true);
      return;
    }
    if (_needsMajors && _items.isEmpty) {
      showAppSnackBar(
          context,
          _type!.type == 'institute'
              ? 'أضف التخصصات أولاً (4-5 على الأقل)'
              : 'أضف التخصصات أولاً',
          isError: true);
      return;
    }
    if (_needsBranches && _items.isEmpty) {
      showAppSnackBar(context, 'أضف الفروع أولاً', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> setup = {
        'type': _type!.type,
        'name': name,
        if (_needsMajors) 'majors': _items,
        if (_needsBranches) 'branches': _items,
        if (_needsSystemChoice) 'system_type': _systemType,
      };
      await prefs.setString('pending_setup', jsonEncode(setup));
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
                  ...List.generate(kOrgTypes.length, (i) {
                    final _OrgType t = kOrgTypes[i];
                    final bool selected = _selected == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() {
                          _selected = i;
                          _items.clear();
                        }),
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
                    child: _selected == -1
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: AppTextField(
                              controller: _name,
                              label: 'اسم الجهة *',
                              hint: kOrgTypes[_selected].placeholder,
                              prefixIcon: Icons.store_rounded,
                            ),
                          ),
                  ),
                  if (_needsSystemChoice) ...[
                    const SizedBox(height: 14),
                    Text('نظام المعهد *',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'years', label: Text('نظام السنوات')),
                        ButtonSegment(
                            value: 'courses', label: Text('نظام الدورات')),
                      ],
                      selected: {_systemType},
                      onSelectionChanged: (s) =>
                          setState(() => _systemType = s.first),
                    ),
                  ],
                  if (_needsMajors || _needsBranches) ...[
                    const SizedBox(height: 14),
                    Text(
                      _needsMajors ? 'التخصصات *' : 'الفروع *',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _itemController,
                            decoration: InputDecoration(
                              hintText: _needsMajors
                                  ? 'اسم التخصص'
                                  : 'اسم الفرع',
                              prefixIcon: const Icon(Icons.add_rounded,
                                  size: 20),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (_) => _addItem(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _items
                          .map(
                            (item) => Chip(
                              label: Text(item),
                              onDeleted: () =>
                                  setState(() => _items.remove(item)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
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
