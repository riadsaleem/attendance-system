import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/models.dart';
import '../providers/students_providers.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<Grade>> grades = ref.watch(gradesProvider);
    final AsyncValue<List<SchoolClass>> classes = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المراحل والصفوف')),
      body: grades.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(gradesProvider),
        ),
        data: (gradeList) => classes.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(classesProvider),
          ),
          data: (classList) {
            if (gradeList.isEmpty) {
              return const EmptyView(
                icon: Icons.school_outlined,
                title: 'لا توجد مراحل',
                subtitle: 'أضف أول مرحلة دراسية بالزر +',
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                for (final Grade grade in gradeList) ...[
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.school_rounded,
                              color: theme.colorScheme.primary),
                          title: Text(
                            grade.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 20),
                                onPressed: () => _editGrade(context, ref,
                                    grade: grade),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    size: 20,
                                    color: theme.colorScheme.error),
                                onPressed: () => _deleteGrade(
                                    context, ref, grade: grade),
                              ),
                            ],
                          ),
                        ),
                        ...classList
                            .where((c) => c.gradeId == grade.id)
                            .map(
                              (c) => ListTile(
                                contentPadding:
                                    const EdgeInsetsDirectional.only(
                                        start: 40, end: 12),
                                dense: true,
                                leading: const Icon(Icons.class_outlined,
                                    size: 20),
                                title: Text(c.name),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18),
                                      onPressed: () => _editClass(context,
                                          ref,
                                          schoolClass: c,
                                          grades: gradeList),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          size: 18,
                                          color: theme.colorScheme.error),
                                      onPressed: () => _deleteClass(context,
                                          ref,
                                          schoolClass: c),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(40),
                            ),
                            onPressed: () => _editClass(context, ref,
                                gradeId: grade.id, grades: gradeList),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('إضافة صف'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _editGrade(context, ref),
                  icon: const Icon(Icons.add_moderator_outlined),
                  label: const Text('إضافة مرحلة جديدة'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _editGrade(
    BuildContext context,
    WidgetRef ref, {
    Grade? grade,
  }) async {
    final TextEditingController controller =
        TextEditingController(text: grade?.name ?? '');
    final String? name = await _textInputDialog(
      context,
      title: grade == null ? 'مرحلة جديدة' : 'تعديل المرحلة',
      label: 'اسم المرحلة',
      controller: controller,
    );
    if (name == null || name.isEmpty) return;
    try {
      final repo = ref.read(classesRepositoryProvider);
      if (grade == null) {
        await repo.insertGrade(name);
      } else {
        await repo.updateGrade(grade.id, name);
      }
      ref.invalidate(gradesProvider);
      ref.invalidate(classesProvider);
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'تعذر الحفظ (تأكد أن الاسم غير مكرر)',
            isError: true);
      }
    }
  }

  Future<void> _editClass(
    BuildContext context,
    WidgetRef ref, {
    SchoolClass? schoolClass,
    int? gradeId,
    required List<Grade> grades,
  }) async {
    final TextEditingController controller =
        TextEditingController(text: schoolClass?.name ?? '');
    int selectedGrade = schoolClass?.gradeId ?? gradeId ?? grades.first.id;

    final String? name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title:
              Text(schoolClass == null ? 'صف جديد' : 'تعديل الصف'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'اسم الصف',
                  hintText: 'مثال: الثالث ب',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedGrade,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'المرحلة'),
                items: grades
                    .map((g) => DropdownMenuItem(
                          value: g.id,
                          child: Text(g.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selectedGrade = v!),
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
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (name == null || name.isEmpty) return;
    try {
      final repo = ref.read(classesRepositoryProvider);
      if (schoolClass == null) {
        await repo.insertClass(name, selectedGrade);
      } else {
        await repo.updateClass(schoolClass.id, name, selectedGrade);
      }
      ref.invalidate(gradesProvider);
      ref.invalidate(classesProvider);
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'تعذر الحفظ (تأكد أن الاسم غير مكرر)',
            isError: true);
      }
    }
  }

  Future<void> _deleteGrade(
    BuildContext context,
    WidgetRef ref, {
    required Grade grade,
  }) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'حذف مرحلة',
      message:
          'سيتم حذف "$grade.name" وجميع صفوفها وطلابها وسجلات حضورهم نهائياً!',
      confirmLabel: 'حذف نهائي',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(classesRepositoryProvider).deleteGrade(grade.id);
      ref.invalidate(gradesProvider);
      ref.invalidate(classesProvider);
      ref.invalidate(studentsProvider);
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'تعذر الحذف', isError: true);
      }
    }
  }

  Future<void> _deleteClass(
    BuildContext context,
    WidgetRef ref, {
    required SchoolClass schoolClass,
  }) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'حذف صف',
      message:
          'سيتم حذف "${schoolClass.name}" وطلابه وسجلات حضورهم نهائياً!',
      confirmLabel: 'حذف نهائي',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(classesRepositoryProvider).deleteClass(schoolClass.id);
      ref.invalidate(gradesProvider);
      ref.invalidate(classesProvider);
      ref.invalidate(studentsProvider);
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'تعذر الحذف', isError: true);
      }
    }
  }

  Future<String?> _textInputDialog(
    BuildContext context, {
    required String title,
    required String label,
    required TextEditingController controller,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
