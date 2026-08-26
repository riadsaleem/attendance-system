import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../../university/domain/models.dart';
import '../../university/providers/university_providers.dart';
import '../domain/models.dart';
import '../providers/students_providers.dart';

class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({super.key, this.existing});

  final Student? existing;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.fullName ?? '');
  late final TextEditingController _guardianName =
      TextEditingController(text: widget.existing?.guardianName ?? '');
  late final TextEditingController _guardianPhone =
      TextEditingController(text: widget.existing?.guardianPhone ?? '');
  late final TextEditingController _fingerprint =
      TextEditingController(text: widget.existing?.fingerprintId ?? '');
  int? _classId;
  String? _section;
  int? _collegeId;
  int? _majorId;
  int? _year;
  bool _saving = false;

  static const List<String> _sections = ['أ', 'ب', 'ج', 'د'];

  bool get _university =>
      ref.read(currentProfileProvider).valueOrNull?.isUniversity ?? false;

  bool get _isInstituteCourses {
    final UserProfile? profile =
        ref.read(currentProfileProvider).valueOrNull;
    return profile?.orgType == 'institute' &&
        profile?.systemType == 'courses';
  }

  int get _majorYears {
    final List<Major> majorList = ref.watch(majorsProvider).valueOrNull ?? [];
    return majorList
        .where((m) => m.id == _majorId)
        .map((m) => m.yearsCount)
        .firstOrNull ?? 4;
  }

  @override
  void initState() {
    super.initState();
    _classId = widget.existing?.classId;
    _section = widget.existing?.section;
    _collegeId = widget.existing?.majorId == null
        ? null
        : null; // resolved below from majors
    _majorId = widget.existing?.majorId;
    _year = widget.existing?.yearNumber;
  }

  @override
  void dispose() {
    _name.dispose();
    _guardianName.dispose();
    _guardianPhone.dispose();
    _fingerprint.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_university) {
      if (_majorId == null) {
        showAppSnackBar(context, 'اختر التخصص أولاً', isError: true);
        return;
      }
      if (_year == null) {
        showAppSnackBar(context, 'اختر السنة الدراسية', isError: true);
        return;
      }
    } else if (_classId == null) {
      showAppSnackBar(context, 'اختر الصف أولاً', isError: true);
      return;
    }

    setState(() => _saving = true);
    final Student student = Student(
      id: widget.existing?.id ?? 0,
      fullName: _name.text.trim(),
      classId: _classId ?? 0,
      majorId: _majorId,
      yearNumber: _year,
      section: _section,
      guardianName: _guardianName.text.trim().isEmpty
          ? null
          : _guardianName.text.trim(),
      guardianPhone: _guardianPhone.text.trim().isEmpty
          ? null
          : _guardianPhone.text.trim(),
      fingerprintId:
          _fingerprint.text.trim().isEmpty ? null : _fingerprint.text.trim(),
    );

    try {
      final repo = ref.read(studentsRepositoryProvider);
      if (widget.existing == null) {
        await repo.insert(student, university: _university);
      } else {
        await repo.update(student, university: _university);
      }
      ref.invalidate(studentsProvider);
      if (mounted) {
        showAppSnackBar(
            context,
            widget.existing == null
                ? 'تمت إضافة الطالب'
                : 'تم تحديث بيانات الطالب');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String message = 'تعذر الحفظ، حاول مجدداً';
        if (e.toString().contains('duplicate key')) {
          message = 'رقم البصمة مستخدم لطالب آخر';
        }
        showAppSnackBar(context, message, isError: true);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool university = _university;
    final AsyncValue<List<SchoolClass>> classes = ref.watch(classesProvider);
    final colleges = ref.watch(collegesProvider);
    final majors = ref.watch(majorsProvider);

    // resolve college of the selected major (edit mode)
    if (university && _collegeId == null && _majorId != null) {
      final majorList = majors.valueOrNull ?? [];
      for (final m in majorList) {
        if (m.id == _majorId) _collegeId = m.collegeId;
      }
    }
    final List<Major> filteredMajors = (majors.valueOrNull ?? [])
        .where((m) => _collegeId == null || m.collegeId == _collegeId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'طالب جديد' : 'تعديل بيانات'),
      ),
      body: university
          ? _universityBody(theme, colleges, majors, filteredMajors)
          : classes.when(
              loading: () => const LoadingView(label: 'تحميل الصفوف...'),
              error: (e, _) => ErrorView(error: e),
              data: (classList) {
                if (classList.isEmpty) {
                  return const EmptyView(
                    icon: Icons.school_outlined,
                    title: 'لا توجد صفوف',
                    subtitle: 'أضف المراحل والصفوف أولاً من شاشة إدارة الصفوف',
                  );
                }
                _classId ??= classList.first.id;
                return _schoolBody(theme, classList);
              },
            ),
    );
  }

  Widget _universityBody(
    ThemeData theme,
    AsyncValue<List<College>> colleges,
    AsyncValue<List<Major>> majors,
    List<Major> filteredMajors,
  ) {
    final collegeList = colleges.valueOrNull ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _name,
              label: 'الاسم الكامل *',
              hint: 'مثال: أحمد محمد صالح',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v ?? '').trim().length < 3 ? 'أدخل الاسم الكامل' : null,
            ),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الكلية *',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _collegeId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.account_balance_rounded),
                  ),
                  items: collegeList
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _collegeId = v;
                    if (_majorId != null &&
                        !(majors.valueOrNull ?? [])
                            .any((m) => m.id == _majorId && m.collegeId == v)) {
                      _majorId = null;
                    }
                  }),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('التخصص *',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _majorId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.menu_book_rounded),
                  ),
                  items: filteredMajors
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _majorId = v;
                    if (_year != null && _year! > _majorYears) _year = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isInstituteCourses ? 'الدورة *' : 'السنة الدراسية *',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _year,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.format_list_numbered_rounded),
                  ),
                  items: List.generate(_majorYears, (i) => i + 1)
                      .map((y) => DropdownMenuItem(
                            value: y,
                            child: Text(
                                '${_isInstituteCourses ? "الدورة" : "السنة"} $y'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _year = v),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المجموعة',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _section,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.groups_rounded),
                  ),
                  items: _sections
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text('مجموعة $s'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _section = v),
                  hint: const Text('اختياري'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: _guardianName,
              label: 'اسم ولي الأمر *',
              hint: 'مثال: محمد صالح',
              prefixIcon: Icons.family_restroom_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v ?? '').trim().length < 3 ? 'أدخل اسم ولي الأمر' : null,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: _guardianPhone,
              label: 'جوال ولي الأمر *',
              hint: 'مثال: 777123456 — لإبلاغه بالغياب',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final String digits = (v ?? '').replaceAll(RegExp(r'[^\d]'), '');
                if (digits.isEmpty) return 'أدخل رقم جوال ولي الأمر';
                if (digits.length != 9) return 'الرقم يجب أن يكون 9 أرقام';
                if (!RegExp(r'^(77|78|71|73|70|79)').hasMatch(digits)) {
                  return 'الرقم غير صحيح — يجب أن يبدأ 77 أو 78 أو 71 أو 73 أو 70 أو 79';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: _fingerprint,
              label: 'رقم البصمة *',
              hint: 'إجباري — من 201 فأعلى (200 وأقل للموظفين)',
              prefixIcon: Icons.fingerprint_rounded,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.number,
              onFieldSubmitted: (_) => _save(),
              validator: (v) {
                final String digits = (v ?? '').trim();
                if (digits.isEmpty) return 'رقم البصمة إجباري';
                final int? number = int.tryParse(digits);
                if (number == null) return 'أدخل رقماً صحيحاً';
                if (number <= 200) {
                  return 'أرقام الطلاب من 201 فأعلى (200 وأقل للموظفين)';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(widget.existing == null
                      ? 'إضافة الطالب'
                      : 'حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _schoolBody(ThemeData theme, List<SchoolClass> classList) {
    return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _name,
                    label: 'الاسم الكامل *',
                    hint: 'مثال: أحمد محمد صالح',
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v ?? '').trim().length < 3 ? 'أدخل الاسم الكامل' : null,
                  ),
                  const SizedBox(height: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الصف *',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _classId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.class_rounded),
                        ),
                        items: classList
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _classId = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الشعبة',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _section,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.call_split_rounded),
                        ),
                        items: _sections
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text('شعبة $s'),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _section = v),
                        hint: const Text('اختياري'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _guardianName,
                    label: 'اسم ولي الأمر *',
                    hint: 'مثال: محمد صالح',
                    prefixIcon: Icons.family_restroom_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v ?? '').trim().length < 3 ? 'أدخل اسم ولي الأمر' : null,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _guardianPhone,
                    label: 'جوال ولي الأمر *',
                    hint: 'مثال: 777123456 — لإبلاغه بالغياب',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final String digits =
                          (v ?? '').replaceAll(RegExp(r'[^\d]'), '');
                      if (digits.isEmpty) return 'أدخل رقم جوال ولي الأمر';
                      if (digits.length != 9) return 'الرقم يجب أن يكون 9 أرقام';
                      if (!RegExp(r'^(77|78|71|73|70|79)').hasMatch(digits)) {
                        return 'الرقم غير صحيح — يجب أن يبدأ 77 أو 78 أو 71 أو 73 أو 70 أو 79';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _fingerprint,
                    label: 'رقم البصمة *',
                    hint: 'إجباري — من 201 فأعلى (200 وأقل للموظفين)',
                    prefixIcon: Icons.fingerprint_rounded,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (_) => _save(),
                    validator: (v) {
                      final String digits = (v ?? '').trim();
                      if (digits.isEmpty) return 'رقم البصمة إجباري';
                      final int? number = int.tryParse(digits);
                      if (number == null) return 'أدخل رقماً صحيحاً';
                      if (number <= 200) {
                        return 'أرقام الطلاب من 201 فأعلى (200 وأقل للموظفين)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.existing == null
                            ? 'إضافة الطالب'
                            : 'حفظ التعديلات'),
                  ),
                ],
              ),
            ),
          );
  }
}
