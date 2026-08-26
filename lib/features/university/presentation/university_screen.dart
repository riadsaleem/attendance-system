import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/models.dart';
import '../providers/university_providers.dart';

class UniversityScreen extends ConsumerWidget {
  const UniversityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final colleges = ref.watch(collegesProvider);
    final majors = ref.watch(majorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الكليات والتخصصات')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCollege(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: colleges.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(collegesProvider),
        ),
        data: (collegeList) => majors.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(majorsProvider),
          ),
          data: (majorList) {
            if (collegeList.isEmpty) {
              return const EmptyView(
                icon: Icons.account_balance_rounded,
                title: 'لا توجد كليات',
                subtitle: 'أضف أول كلية بالزر +',
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                for (final College college in collegeList) ...[
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.account_balance_rounded,
                              color: theme.colorScheme.primary),
                          title: Text(college.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: theme.colorScheme.error),
                            onPressed: () => _deleteCollege(
                                context, ref, college: college),
                          ),
                        ),
                        ...majorList
                            .where((m) => m.collegeId == college.id)
                            .map(
                              (m) => ListTile(
                                dense: true,
                                contentPadding:
                                    const EdgeInsetsDirectional.only(
                                        start: 40, end: 12),
                                leading: const Icon(Icons.menu_book_rounded,
                                    size: 20),
                                title: Text(m.name),
                                subtitle: Text(
                                    '${m.yearsCount} ${m.yearsCount <= 3 ? "دورات" : "سنوات"}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: theme.hintColor)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'تعديل عدد السنوات',
                                      icon: const Icon(Icons.edit_rounded,
                                          size: 18),
                                      onPressed: () => _editMajorYears(
                                          context, ref,
                                          major: m),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          size: 18,
                                          color: theme.colorScheme.error),
                                      onPressed: () => _deleteMajor(context, ref,
                                          major: m),
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
                            onPressed: () => _addMajor(context, ref,
                                college: college),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('إضافة تخصص'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _addCollege(BuildContext context, WidgetRef ref) async {
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('كلية جديدة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'اسم الكلية'),
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
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(universityRepositoryProvider).insertCollege(name);
      ref.invalidate(collegesProvider);
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'تعذر الحفظ (الاسم مكرر؟)', isError: true);
      }
    }
  }

  Future<void> _addMajor(
    BuildContext context,
    WidgetRef ref, {
    required College college,
  }) async {
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تخصص جديد — ${college.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'اسم التخصص'),
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
    if (name == null || name.isEmpty) return;
    try {
      await ref
          .read(universityRepositoryProvider)
          .insertMajor(name, college.id);
      ref.invalidate(majorsProvider);
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'تعذر الحفظ (الاسم مكرر؟)', isError: true);
      }
    }
  }

  Future<void> _deleteCollege(
    BuildContext context,
    WidgetRef ref, {
    required College college,
  }) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'حذف كلية',
      message:
          'سيتم حذف "${college.name}" وجميع تخصصاتها — الطلاب المسجلون فيها سيبقون بدون تخصص!',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(universityRepositoryProvider).deleteCollege(college.id);
      ref.invalidate(collegesProvider);
      ref.invalidate(majorsProvider);
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'تعذر الحذف', isError: true);
      }
    }
  }

  Future<void> _editMajorYears(
    BuildContext context,
    WidgetRef ref, {
    required Major major,
  }) async {
    int years = major.yearsCount;
    final int? result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('سنوات ${major.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('عدد السنوات الدراسية للتخصص:'),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: years,
                items: List.generate(8, (i) => i + 1)
                    .map((y) => DropdownMenuItem(
                        value: y, child: Text('$y سنوات')))
                    .toList(),
                onChanged: (v) => setState(() => years = v ?? 4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, years),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result == major.yearsCount) return;
    try {
      await ref
          .read(universityRepositoryProvider)
          .updateMajorYears(major.id, result);
      ref.invalidate(majorsProvider);
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'تعذر الحفظ', isError: true);
      }
    }
  }

  Future<void> _deleteMajor(
    BuildContext context,
    WidgetRef ref, {
    required Major major,
  }) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'حذف تخصص',
      message: 'سيتم حذف تخصص "${major.name}" — الطلاب فيه سيبقون بدون تخصص!',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(universityRepositoryProvider).deleteMajor(major.id);
      ref.invalidate(majorsProvider);
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'تعذر الحذف', isError: true);
      }
    }
  }
}
