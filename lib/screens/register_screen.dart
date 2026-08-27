import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/api_response.dart';
import '../services/auth_service.dart';
import '../services/i18n.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';
import '../widgets/app_toast.dart';
import 'shell_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirm = false;
  bool _isLoading = false;
  String? _generalError;
  final Map<String, String> _errors = {};

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _employeeIdController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _clearError(String field) {
    if (_errors.containsKey(field)) {
      setState(() => _errors.remove(field));
    }
  }

  Future<void> _submit() async {
    setState(() {
      _generalError = null;
      _errors.clear();
    });

    final t = AppLocalizations.t;
    final email = _emailController.text.trim();
    final userName = _usernameController.text.trim();
    final employeeId = _employeeIdController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty) _errors['email'] = t('register.errors.emailRequired');
    else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
      _errors['email'] = t('register.errors.emailInvalid');
    }
    if (userName.isEmpty) _errors['userName'] = t('register.errors.usernameRequired');
    if (employeeId.isEmpty) _errors['employeeId'] = t('register.errors.employeeIdRequired');
    if (password.isEmpty) _errors['password'] = t('register.errors.passwordRequired');
    else if (password.length < 6) _errors['password'] = t('register.errors.passwordMin');
    if (confirm.isEmpty) _errors['confirm'] = t('register.errors.confirmRequired');
    else if (password != confirm) _errors['confirm'] = t('register.errors.confirmMismatch');

    if (_errors.isNotEmpty) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().register(
        email: email,
        userName: userName,
        password: password,
        employeeId: employeeId,
      );
      if (!mounted) return;
      showAppToast(context, t('register.success'), type: ToastType.success);
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ShellScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('password')) _errors['password'] = e.message;
      if (msg.contains('email') || msg.contains('already taken') ||
          msg.contains('already exists')) {
        _errors['email'] = e.message;
      }
      if (msg.contains('username') || msg.contains('user name')) {
        _errors['userName'] = e.message;
      }
      if (msg.contains('employee')) _errors['employeeId'] = e.message;
      setState(() {
        if (_errors.isEmpty) _generalError = e.message;
      });
    } catch (_) {
      setState(() => _generalError = AppLocalizations.t('errors.network'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.t('register.title')),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.blue50, AppColors.white, AppColors.blue50],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.gray200),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A93C5FD),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/images/cbe-logo.png',
                        fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.t('register.title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
              Text(
                AppLocalizations.t('register.subtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.gray500),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppInput(
                      label: AppLocalizations.t('register.emailLabel'),
                      hint: AppLocalizations.t('register.emailPlaceholder'),
                      icon: Icons.mail_outline,
                      controller: _emailController,
                      error: _errors['email'],
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => _clearError('email'),
                    ),
                    const SizedBox(height: 16),
                    AppInput(
                      label: AppLocalizations.t('register.usernameLabel'),
                      hint: AppLocalizations.t('register.usernamePlaceholder'),
                      icon: Icons.person_outline,
                      controller: _usernameController,
                      error: _errors['userName'],
                      onChanged: (_) => _clearError('userName'),
                    ),
                    const SizedBox(height: 16),
                    AppInput(
                      label: AppLocalizations.t('register.employeeIdLabel'),
                      hint: AppLocalizations.t('register.employeeIdPlaceholder'),
                      icon: Icons.badge_outlined,
                      controller: _employeeIdController,
                      error: _errors['employeeId'],
                      onChanged: (_) => _clearError('employeeId'),
                    ),
                    const SizedBox(height: 16),
                    AppInput(
                      label: AppLocalizations.t('register.passwordLabel'),
                      hint: AppLocalizations.t('register.passwordPlaceholder'),
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      error: _errors['password'],
                      obscureText: !_showPassword,
                      onChanged: (_) => _clearError('password'),
                      suffix: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.gray400,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppInput(
                      label: AppLocalizations.t('register.confirmLabel'),
                      hint: AppLocalizations.t('register.confirmPlaceholder'),
                      icon: Icons.lock_outline,
                      controller: _confirmController,
                      error: _errors['confirm'],
                      obscureText: !_showConfirm,
                      onChanged: (_) => _clearError('confirm'),
                      suffix: IconButton(
                        icon: Icon(
                          _showConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.gray400,
                        ),
                        onPressed: () =>
                            setState(() => _showConfirm = !_showConfirm),
                      ),
                    ),
                    if (_generalError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.red50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.red200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 18, color: AppColors.red500),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _generalError!,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.red700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    AppButton(
                      label: AppLocalizations.t('register.title'),
                      isLoading: _isLoading,
                      fullWidth: true,
                      size: ButtonSize.lg,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.t('register.haveAccount'),
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.gray500),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      AppLocalizations.t('register.signIn'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
