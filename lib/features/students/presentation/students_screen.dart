import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/models.dart';
import '../providers/students_providers.dart';
import 'classes_screen.dart';
import 'student_form_screen.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  String _search = '';
  int? _classFilter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<UserProfile?> profile = ref.watch(currentProfileProvider);
    final AsyncValue<List<Student>> students = ref.watch(studentsProvider);
    final AsyncValue<List<SchoolClass>> classes = ref.watch(classesProvider);

    final bool isAdmin = profile.valueOrNull?.role.canManageStudents ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلاب'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.school_outlined),
              tooltip: 'إدارة الصفوف',
              onPressed: () => _openClasses(),
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(null),
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('طالب جديد'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'ابحث عن طالب بالاسم...',
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
          classes.when(
            loading: () => const SizedBox(height: 48),
            error: (e, _) => const SizedBox(height: 48),
            data: (classList) => SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: const Text('الكل'),
                      selected: _classFilter == null,
                      onSelected: (_) => setState(() => _classFilter = null),
                    ),
                  ),
                  ...classList.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(c.name),
                        selected: _classFilter == c.id,
                        onSelected: (_) => setState(() {
                          _classFilter = _classFilter == c.id ? null : c.id;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: students.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(studentsProvider),
              ),
              data: (list) {
                final filtered = list.where((s) {
                  final matchesSearch = _search.isEmpty ||
                      s.fullName.contains(_search.trim());
                  final matchesClass =
                      _classFilter == null || s.classId == _classFilter;
                  return matchesSearch && matchesClass;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyView(
                    icon: Icons.people_outline_rounded,
                    title: 'لا يوجد طلاب',
                    subtitle: _search.isNotEmpty || _classFilter != null
                        ? 'جرب تغيير البحث أو الفلتر'
                        : 'أضف أول طالب بالزر الأسفل',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(studentsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final Student student = filtered[index];
                      return _StudentCard(
                        student: student,
                        isAdmin: isAdmin,
                        theme: theme,
                        onEdit: () => _openForm(student),
                        onDelete: () => _deleteStudent(student),
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

  void _openClasses() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ClassesScreen()),
    );
  }

  void _openForm(Student? student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentFormScreen(existing: student),
      ),
    );
  }

  Future<void> _deleteStudent(Student student) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'حذف طالب',
      message: 'هل أنت متأكد من حذف "$student.fullName" وجميع سجلات حضوره؟',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    showLoadingDialog(context);
    try {
      await ref.read(studentsRepositoryProvider).delete(student.id);
      ref.invalidate(studentsProvider);
      if (mounted) {
        hideLoadingDialog(context);
        showAppSnackBar(context, 'تم حذف الطالب');
      }
    } catch (_) {
      if (mounted) {
        hideLoadingDialog(context);
        showAppSnackBar(context, 'تعذر الحذف، حاول مجدداً', isError: true);
      }
    }
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.isAdmin,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
  });

  final Student student;
  final bool isAdmin;
  final ThemeData theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            student.fullName.isNotEmpty
                ? student.fullName.substring(0, 1)
                : '?',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          student.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${student.className}'
          '${student.section != null ? ' - شعبة ${student.section}' : ''}'
          '${student.guardianPhone != null ? '\nولي الأمر: ${student.guardianName} (${student.guardianPhone})' : ''}',
        ),
        isThreeLine: student.guardianPhone != null,
        trailing: isAdmin
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('تعديل'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('حذف'),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
