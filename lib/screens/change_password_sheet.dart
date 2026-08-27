import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/i18n.dart';
import '../services/session.dart';
import '../services/user_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';
import '../widgets/app_toast.dart';

/// Change Password bottom sheet (mirrors the web sidebar modal).
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _current = TextEditingController();
  final _newPwd = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPwd.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final t = AppLocalizations.t;
    if (_current.text.isEmpty) {
      setState(() => _error = t('password.errors.currentRequired'));
      return;
    }
    if (_newPwd.text.length < 6) {
      setState(() => _error = t('password.errors.minLength'));
      return;
    }
    if (_newPwd.text != _confirm.text) {
      setState(() => _error = t('password.errors.mismatch'));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await UserService().changePassword(
        userId: Session.instance.user?.userId ?? '',
        currentPassword: _current.text,
        newPassword: _newPwd.text,
      );
      if (!mounted) return;
      showAppToast(context, t('password.success'), type: ToastType.success);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.t;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.key_outlined, size: 20, color: AppColors.blue600),
              const SizedBox(width: 8),
              Text(
                t('password.title'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.blue100),
            ),
            child: Text(
              t('password.hint'),
              style: const TextStyle(fontSize: 13, color: AppColors.blue700),
            ),
          ),
          const SizedBox(height: 16),
          AppInput(
            label: t('password.current'),
            hint: t('password.currentPlaceholder'),
            icon: Icons.key_outlined,
            controller: _current,
            obscureText: !_showCurrent,
            suffix: IconButton(
              icon: Icon(
                _showCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.gray400,
              ),
              onPressed: () => setState(() => _showCurrent = !_showCurrent),
            ),
          ),
          const SizedBox(height: 14),
          AppInput(
            label: t('password.new'),
            hint: t('password.newPlaceholder'),
            icon: Icons.key_outlined,
            controller: _newPwd,
            obscureText: !_showNew,
            suffix: IconButton(
              icon: Icon(
                _showNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.gray400,
              ),
              onPressed: () => setState(() => _showNew = !_showNew),
            ),
          ),
          const SizedBox(height: 14),
          AppInput(
            label: t('password.confirm'),
            hint: t('password.confirmPlaceholder'),
            icon: Icons.key_outlined,
            controller: _confirm,
            obscureText: !_showConfirm,
            suffix: IconButton(
              icon: Icon(
                _showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.gray400,
              ),
              onPressed: () => setState(() => _showConfirm = !_showConfirm),
            ),
          ),
          if (_error != null) ...[
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
                      _error!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.red700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: t('common.cancel'),
                  variant: ButtonVariant.outline,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: t('password.title'),
                  isLoading: _isSaving,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
