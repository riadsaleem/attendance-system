import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const String routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text.trim(), password: _password.text);
    } on AuthException catch (e) {
      if (mounted) showAppSnackBar(context, _arabicError(e.message), isError: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'تعذر الاتصال بالخادم، تحقق من الإنترنت',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _arabicError(String message) {
    final String m = message.toLowerCase();
    if (m.contains('socketexception') ||
        m.contains('failed host lookup') ||
        m.contains('no address associated') ||
        m.contains('clientexception') ||
        m.contains('network')) {
      return 'لا يوجد اتصال بالإنترنت 📡\n'
          'تحقق من شبكتك (واي فاي أو بيانات الجوال) وحاول مجدداً';
    }
    if (message.contains('Invalid login credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (message.contains('Email not confirmed')) {
      return 'لم يتم تأكيد البريد الإلكتروني بعد';
    }
    if (message.contains('Too many requests')) {
      return 'محاولات كثيرة، انتظر قليلاً ثم أعد المحاولة';
    }
    return 'حدث خطأ: $message';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Icon(
                        Icons.fact_check_rounded,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppConfig.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'سجل دخولك لإدارة الحضور والغياب',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 36),
                    AppTextField(
                      controller: _email,
                      label: 'البريد الإلكتروني',
                      hint: 'example@mail.com',
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final String value = v?.trim() ?? '';
                        if (value.isEmpty) return 'أدخل البريد الإلكتروني';
                        if (!value.contains('@')) return 'بريد إلكتروني غير صالح';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _password,
                      label: 'كلمة المرور',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) {
                        if ((v ?? '').isEmpty) return 'أدخل كلمة المرور';
                        if (v!.length < 6) return 'كلمة المرور قصيرة جداً';
                        return null;
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('تسجيل الدخول'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ما عندك حساب؟',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('أنشئ حساباً جديداً'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
