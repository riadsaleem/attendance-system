import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/staff_models.dart';
import '../providers/staff_providers.dart';
import 'branches_screen.dart';
import 'staff_attendance_screen.dart';
import 'staff_form_screen.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key, required this.category});

  final StaffCategory category;

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  String _search = '';

  AutoDisposeFutureProvider<List<Staff>> get _provider =>
      widget.category == StaffCategory.employee
          ? employeesProvider
          : workersProvider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<UserProfile?> profile = ref.watch(currentProfileProvider);
    final staff = ref.watch(_provider);
    final bool isAdmin = profile.valueOrNull?.role.canManageStudents ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.pluralAr),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_rounded),
            tooltip: 'الفروع',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BranchesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.fact_check_rounded),
            tooltip: 'تسجيل الحضور',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    StaffAttendanceScreen(category: widget.category),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _openForm(null),
              child: const Icon(Icons.person_add_alt_rounded),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _search = ''),
                      ),
              ),
            ),
          ),
          Expanded(
            child: staff.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(_provider),
              ),
              data: (list) {
                final filtered = list
                    .where((s) => s.fullName.contains(_search.trim()))
                    .toList();
                if (filtered.isEmpty) {
                  return EmptyView(
                    icon: Icons.badge_outlined,
                    title: 'لا توجد سجلات',
                    subtitle: isAdmin
                        ? 'أضف أول ${widget.category.labelAr} بالزر العائم'
                        : 'لم تتم إضافة أي سجلات بعد',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(_provider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final Staff member = filtered[index];
                      return _StaffCard(
                        theme: theme,
                        member: member,
                        isAdmin: isAdmin,
                        onEdit: () => _openForm(member),
                        onDelete: () => _delete(member),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(Staff? member) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaffFormScreen(
          category: widget.category,
          existing: member,
        ),
      ),
    );
  }

  Future<void> _delete(Staff member) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'حذف ${widget.category.labelAr}',
      message: 'هل أنت متأكد من حذف "${member.fullName}" وسجلات حضوره؟',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    showLoadingDialog(context);
    try {
      await ref.read(staffRepositoryProvider).delete(member.id);
      ref.invalidate(_provider);
      if (mounted) {
        hideLoadingDialog(context);
        showAppSnackBar(context, 'تم الحذف');
      }
    } catch (_) {
      if (mounted) {
        hideLoadingDialog(context);
        showAppSnackBar(context, 'تعذر الحذف، حاول مجدداً', isError: true);
      }
    }
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.theme,
    required this.member,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  final ThemeData theme;
  final Staff member;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final String subtitle = [
      if (member.jobTitle != null && member.jobTitle!.isNotEmpty)
        member.jobTitle!,
      if (member.phone != null && member.phone!.isNotEmpty)
        'جوال: ${member.phone}',
      if (member.fingerprintId != null &&
          member.fingerprintId!.isNotEmpty)
        'رقم البصمة: ${member.fingerprintId}',
    ].join(' • ');

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Text(
            member.fullName.isNotEmpty ? member.fullName.substring(0, 1) : '?',
            style: TextStyle(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          member.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: isAdmin
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              )
            : null,
      ),
    );
  }
}
