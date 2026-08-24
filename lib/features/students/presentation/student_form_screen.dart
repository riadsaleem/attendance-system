import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _classId = widget.existing?.classId;
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
    if (_classId == null) {
      showAppSnackBar(context, 'اختر الصف أولاً', isError: true);
      return;
    }

    setState(() => _saving = true);
    final Student student = Student(
      id: widget.existing?.id ?? 0,
      fullName: _name.text.trim(),
      classId: _classId!,
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
        await repo.insert(student);
      } else {
        await repo.update(student);
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
    final AsyncValue<List<SchoolClass>> classes = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'طالب جديد' : 'تعديل بيانات'),
      ),
      body: classes.when(
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
                      if (digits.length < 9) return 'الرقم قصير جداً';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _fingerprint,
                    label: 'رقم البصمة',
                    hint: 'اختياري — لربط جهاز البصمة مستقبلاً',
                    prefixIcon: Icons.fingerprint_rounded,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
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
                        : Text(widget.existing == null ? 'إضافة الطالب' : 'حفظ التعديلات'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
