import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  static const String routePath = '/register';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _name.text.trim(),
          );
      if (mounted) {
        showAppSnackBar(
          context,
          'تم إنشاء الحساب بنجاح 🎉',
        );
      }
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
    if (message.contains('already registered')) {
      return 'هذا البريد مسجل مسبقاً، سجل دخول مباشرة';
    }
    if (message.contains('Password') && message.contains('characters')) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return 'حدث خطأ: $message';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('حساب جديد')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'أنشئ حسابك',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'أول حساب ينشأ في النظام يحصل على صلاحية مدير تلقائياً',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      controller: _name,
                      label: 'الاسم الكامل',
                      hint: 'مثال: رياض سليم',
                      prefixIcon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if ((v ?? '').trim().length < 3) {
                          return 'أدخل الاسم الكامل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
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
                      hint: '6 أحرف على الأقل',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if ((v ?? '').length < 6) {
                          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _confirm,
                      label: 'تأكيد كلمة المرور',
                      hint: 'أعد كتابة كلمة المرور',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) {
                        if (v != _password.text) return 'كلمتا المرور غير متطابقتين';
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
                          : const Text('إنشاء الحساب'),
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
