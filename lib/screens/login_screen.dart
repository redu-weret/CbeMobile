import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/api_response.dart';
import '../services/auth_service.dart';
import '../services/i18n.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';
import '../widgets/app_toast.dart';
import '../widgets/language_selector.dart';
import 'register_screen.dart';
import 'server_settings_screen.dart';
import 'shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _generalError = null;
      _emailError = null;
      _passwordError = null;
    });

    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = AppLocalizations.t('login.errors.emailRequired'));
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = AppLocalizations.t('login.errors.passwordRequired'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().login(
        emailOrUserName: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      showAppToast(context, AppLocalizations.t('login.welcomeBack'),
          type: ToastType.success);
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ShellScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    } on ApiException catch (e) {
      final msg = e.message.toLowerCase();
      String? emailErr;
      String? passErr;
      if (msg.contains('password') || msg.contains('pass')) passErr = e.message;
      if (msg.contains('username') || msg.contains('email')) {
        emailErr = e.message;
      }
      if (msg.contains('credentials')) {
        emailErr = AppLocalizations.t('login.errors.emailInvalid');
        passErr = AppLocalizations.t('login.errors.passwordInvalid');
      }
      if (msg.contains('not found') || msg.contains('does not exist')) {
        emailErr = e.message;
      }
      setState(() {
        _generalError = emailErr == null && passErr == null ? e.message : null;
        _emailError = emailErr;
        _passwordError = passErr;
      });
    } catch (_) {
      setState(() =>
          _generalError = AppLocalizations.t('errors.network'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.blue50, AppColors.white, AppColors.blue50],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 150,
                      child: LanguageSelector(compact: true),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
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
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/cbe-logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.t('app.name'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.t('login.subtitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.gray500),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppInput(
                        label: AppLocalizations.t('login.emailLabel'),
                        hint: AppLocalizations.t('login.emailPlaceholder'),
                        icon: Icons.mail_outline,
                        controller: _emailController,
                        error: _emailError,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHint: 'username',
                        onChanged: (_) {
                          if (_emailError != null) setState(() => _emailError = null);
                        },
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        label: AppLocalizations.t('login.passwordLabel'),
                        hint: AppLocalizations.t('login.passwordPlaceholder'),
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        error: _passwordError,
                        obscureText: !_showPassword,
                        textInputAction: TextInputAction.done,
                        autofillHint: 'password',
                        onChanged: (_) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                        },
                        onSubmitted: (_) => _submit(),
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
                      if (_generalError != null) ...[
                        const SizedBox(height: 12),
                        _ErrorBanner(message: _generalError!),
                      ],
                      const SizedBox(height: 20),
                      AppButton(
                        label: AppLocalizations.t('login.signIn'),
                        isLoading: _isLoading,
                        fullWidth: true,
                        size: ButtonSize.lg,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.t('login.noAccount'),
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.gray500),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.t('login.registerHere'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ServerSettingsScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.settings_outlined,
                        size: 16, color: AppColors.gray500),
                    label: Text(
                      'Server settings',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.gray500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.red200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.red500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.red700),
            ),
          ),
        ],
      ),
    );
  }
}
