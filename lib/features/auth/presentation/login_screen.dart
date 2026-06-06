import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _routeToDashboard() async {
    final user = await ref.read(userProfileProvider.future);
    if (!mounted) return;
    final role = user?.role ?? '';
    if (user?.isActive != true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
      _showError('account_not_approved');
    } else if (role == 'admin') {
      context.go('/admin-dashboard');
    } else if (role == 'teacher') {
      context.go('/prof-dashboard');
    } else if (role == 'student') {
      context.go('/home');
    } else {
      await ref.read(authControllerProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
      _showError('account_not_approved');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text, _passwordController.text);

    if (!mounted) return;
    if (success) {
      await _routeToDashboard();
    } else {
      context.go('/login');
      _showControllerError();
    }
  }

  Future<void> _handleGoogleLogin() async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .loginWithGoogle(confirmAgreement: _showAgreementDialog);

    if (!mounted) return;
    if (success) {
      await _routeToDashboard();
    } else {
      context.go('/login');
      _showControllerError();
    }
  }

  Future<bool> _showAgreementDialog(String email) async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('agreement_title')),
          content: Text('${tr('agreement_message')}\n\n${tr('email')}: $email'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('no')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('yes')),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  void _showControllerError() {
    final state = ref.read(authControllerProvider);
    final errorKey = state.error?.toString() ?? 'error_occurred';
    _showError(errorKey);
  }

  void _showError(String errorKey) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(errorKey)),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: LoadingOverlay(
        isLoading: authState.isLoading,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 82,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('app_name'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('auth_tagline'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x140F172A),
                            blurRadius: 24,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tr('login_title'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tr('login_hint'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 22),
                            CustomTextField(
                              controller: _emailController,
                              labelText: tr('email'),
                              hintText: 'exemplo@email.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null ||
                                    val.isEmpty ||
                                    !val.contains('@')) {
                                  return tr('invalid_email');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _passwordController,
                              labelText: tr('password'),
                              hintText: '******',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF64748B),
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.length < 6) {
                                  return tr('invalid_password');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text(tr('forgot_password')),
                              ),
                            ),
                            const SizedBox(height: 8),
                            CustomButton(
                              text: tr('login'),
                              isLoading: authState.isLoading,
                              onPressed: _handleLogin,
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: authState.isLoading
                                  ? null
                                  : _handleGoogleLogin,
                              icon: const Icon(
                                Icons.g_mobiledata_rounded,
                                size: 28,
                              ),
                              label: Text(tr('continue_with_google')),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              tr('admin_contact_hint'),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
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
