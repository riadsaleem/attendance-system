import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../../device/presentation/device_screen.dart';
import 'license_codes_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<UserProfile?> profile = ref.watch(currentProfileProvider);
    final ThemeMode themeMode = ref.watch(themeProvider);
    final UserProfile? user = profile.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      (user?.fullName.isNotEmpty ?? false)
                          ? user!.fullName.substring(0, 1)
                          : '?',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? '',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(user?.email ?? '',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user?.role.labelAr ?? '',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(theme: theme, label: 'المظهر'),
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded, size: 18)),
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded, size: 18)),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded, size: 18)),
                ],
                selected: {themeMode},
                onSelectionChanged: (s) =>
                    ref.read(themeProvider.notifier).setMode(s.first),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(theme: theme, label: 'الحساب'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('تعديل الاسم'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: _editName,
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text('تغيير كلمة المرور'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: _changePassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (user?.isAdmin ?? false) ...[
            _SectionTitle(theme: theme, label: 'إدارة التراخيص'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.key_rounded),
                title: const Text('أكواد التفعيل'),
                subtitle: const Text('إنشاء وإدارة أكواد الاشتراك السنوي'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LicenseCodesScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(theme: theme, label: 'الأجهزة'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.fingerprint_rounded),
                title: const Text('ربط جهاز البصمة'),
                subtitle: const Text('الاتصال بالجهاز عبر الشبكة وسحب السجلات'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DeviceScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: ListTile(
              leading:
                  Icon(Icons.logout_rounded, color: theme.colorScheme.error),
              title: Text('تسجيل الخروج',
                  style: TextStyle(color: theme.colorScheme.error)),
              onTap: _logout,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  '${AppConfig.appName} • الإصدار 1.0.0',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'تطوير: رياض سليم © 2026',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName() async {
    final UserProfile? user = ref.read(currentProfileProvider).value;
    if (user == null) return;

    final TextEditingController controller =
        TextEditingController(text: user.fullName);
    final String? name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الاسم'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'الاسم الكامل'),
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

    if (name == null || name.isEmpty || name == user.fullName) return;
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfileName(user.id, name);
      ref.invalidate(currentProfileProvider);
      if (mounted) showAppSnackBar(context, 'تم تحديث الاسم');
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'تعذر التحديث', isError: true);
      }
    }
  }

  Future<void> _changePassword() async {
    final TextEditingController pass = TextEditingController();
    final TextEditingController confirm = TextEditingController();

    final String? newPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: pass,
              label: 'كلمة المرور الجديدة',
              hint: '6 أحرف على الأقل',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: confirm,
              label: 'تأكيد كلمة المرور',
              hint: 'أعد كتابتها',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (pass.text.length < 6) {
                showAppSnackBar(context,
                    'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                    isError: true);
                return;
              }
              if (pass.text != confirm.text) {
                showAppSnackBar(context, 'كلمتا المرور غير متطابقتين',
                    isError: true);
                return;
              }
              Navigator.pop(context, pass.text);
            },
            child: const Text('تغيير'),
          ),
        ],
      ),
    );

    if (newPassword == null) return;
    try {
      await ref.read(authRepositoryProvider).updatePassword(newPassword);
      if (mounted) showAppSnackBar(context, 'تم تغيير كلمة المرور ✅');
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'تعذر تغيير كلمة المرور', isError: true);
      }
    }
  }

  Future<void> _logout() async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'تسجيل الخروج',
      message: 'هل أنت متأكد من تسجيل الخروج؟',
      confirmLabel: 'خروج',
      destructive: true,
    );
    if (confirmed && mounted) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.theme, required this.label});

  final ThemeData theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Text(label,
          style: theme.textTheme.titleSmall
              ?.copyWith(color: theme.hintColor)),
    );
  }
}
