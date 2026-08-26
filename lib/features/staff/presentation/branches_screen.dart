import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../providers/staff_providers.dart';

class BranchesScreen extends ConsumerWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final branches = ref.watch(branchesProvider);

    Future<void> addBranch() async {
      final TextEditingController controller = TextEditingController();
      final String? name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('فرع جديد'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'اسم الفرع'),
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
        await ref.read(staffRepositoryProvider).insertBranch(name);
        ref.invalidate(branchesProvider);
      } catch (_) {
        if (context.mounted) {
          showAppSnackBar(context, 'تعذر الحفظ', isError: true);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الفروع')),
      floatingActionButton: FloatingActionButton(
        onPressed: addBranch,
        child: const Icon(Icons.add_rounded),
      ),
      body: branches.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(branchesProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyView(
              icon: Icons.account_tree_rounded,
              title: 'لا توجد فروع',
              subtitle: 'أضف أول فرع بالزر +',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final Map<String, dynamic> b = list[index];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.account_tree_rounded,
                      color: theme.colorScheme.primary),
                  title: Text('${b['name']}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: theme.colorScheme.error),
                    onPressed: () async {
                      final bool confirmed = await showConfirmDialog(
                        context,
                        title: 'حذف فرع',
                        message:
                            'حذف فرع "${b['name']}"؟ الموظفون فيه سينقلون للفرع الرئيسي.',
                        confirmLabel: 'حذف',
                        destructive: true,
                      );
                      if (!confirmed) return;
                      try {
                        await ref
                            .read(staffRepositoryProvider)
                            .deleteBranch(b['id'] as int);
                        ref.invalidate(branchesProvider);
                      } catch (_) {
                        if (context.mounted) {
                          showAppSnackBar(context, 'تعذر الحذف',
                              isError: true);
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
