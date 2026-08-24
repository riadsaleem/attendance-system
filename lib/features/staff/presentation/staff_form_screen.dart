import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/staff_models.dart';
import '../providers/staff_providers.dart';

class StaffFormScreen extends ConsumerStatefulWidget {
  const StaffFormScreen({
    super.key,
    required this.category,
    this.existing,
  });

  final StaffCategory category;
  final Staff? existing;

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.fullName ?? '');
  late final TextEditingController _jobTitle =
      TextEditingController(text: widget.existing?.jobTitle ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.existing?.phone ?? '');
  late final TextEditingController _fingerprint =
      TextEditingController(text: widget.existing?.fingerprintId ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _jobTitle.dispose();
    _phone.dispose();
    _fingerprint.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final Staff member = Staff(
      id: widget.existing?.id ?? 0,
      fullName: _name.text.trim(),
      category: widget.category,
      jobTitle: _jobTitle.text.trim().isEmpty ? null : _jobTitle.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      fingerprintId:
          _fingerprint.text.trim().isEmpty ? null : _fingerprint.text.trim(),
    );

    try {
      final repo = ref.read(staffRepositoryProvider);
      if (widget.existing == null) {
        await repo.insert(member);
      } else {
        await repo.update(member);
      }
      ref.invalidate(employeesProvider);
      ref.invalidate(workersProvider);
      if (mounted) {
        showAppSnackBar(context, 'تم الحفظ بنجاح');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String message = 'تعذر الحفظ، حاول مجدداً';
        if (e.toString().contains('duplicate key')) {
          message = 'رقم البصمة مستخدم لشخص آخر';
        }
        showAppSnackBar(context, message, isError: true);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null
            ? 'إضافة ${widget.category.labelAr}'
            : 'تعديل بيانات'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _name,
                label: 'الاسم الكامل *',
                hint: 'مثال: محمد أحمد',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v ?? '').trim().length < 3 ? 'أدخل الاسم الكامل' : null,
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _jobTitle,
                label: 'المسمى الوظيفي',
                hint: widget.category == StaffCategory.employee
                    ? 'مثال: معلم / محاسب / مدير'
                    : 'مثال: عامل نظافة / حارس',
                prefixIcon: Icons.work_outline_rounded,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _phone,
                label: 'رقم الجوال',
                hint: 'اختياري — مثال: 777123456',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _fingerprint,
                label: 'رقم البصمة',
                hint: 'اختياري — نفس رقم التسجيل في جهاز البصمة',
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
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(widget.existing == null ? 'إضافة' : 'حفظ التعديلات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
