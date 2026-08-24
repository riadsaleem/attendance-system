import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/providers/auth_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile?> profile = ref.watch(currentProfileProvider);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('خروج'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(authRepositoryProvider).signOut();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: profile.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('خطأ في تحميل البيانات: $e'),
          data: (user) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  (user?.fullName.isNotEmpty ?? false)
                      ? user!.fullName.substring(0, 1)
                      : '?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.fullName ?? '...',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(user?.role.labelAr ?? ''),
                backgroundColor: theme.colorScheme.secondaryContainer,
              ),
              const SizedBox(height: 24),
              Text(
                'الواجهة الرئيسية قيد الإنشاء — Stage 4 قادم',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
