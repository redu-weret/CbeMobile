import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/user.dart';
import '../services/i18n.dart';
import '../services/user_service.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_input.dart';
import '../widgets/app_spinner.dart';
import '../widgets/app_toast.dart';
import '../widgets/empty_state.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<UserDto> _users = [];
  bool _isLoading = true;
  final UserService _service = UserService();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getAll();
      if (mounted) setState(() => _users = list);
    } catch (e) {
      if (mounted) {
        showAppToast(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  BadgeVariant _roleVariant(String role) => switch (role) {
        'Admin' => BadgeVariant.danger,
        'Manager' => BadgeVariant.warning,
        _ => BadgeVariant.default_,
      };

  Future<void> _openRoleAction(UserDto user, String action) async {
    final t = AppLocalizations.t;
    final result = await showModalBottomSheet<_RoleResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RoleSheet(
        user: user,
        action: action,
        title: switch (action) {
          'assign' => t('users.modal.assignTitle'),
          'change' => t('users.modal.changeTitle'),
          _ => t('users.modal.removeTitle'),
        },
      ),
    );
    if (result == null || !mounted) return;
    try {
      switch (action) {
        case 'assign':
          await _service.assignRole(
              userId: user.id, roleName: result.roleName);
        case 'change':
          await _service.changeRole(
              userId: user.id,
              currentRole: result.currentRole,
              newRole: result.newRole);
        default:
          await _service.removeRole(
              userId: user.id, roleName: result.roleName);
      }
      if (!mounted) return;
      showAppToast(context, t('users.toasts.roleUpdated'),
          type: ToastType.success);
      _fetch();
    } catch (e) {
      if (mounted) {
        showAppToast(context, e.toString(), type: ToastType.error);
      }
    }
  }

  Future<void> _openResetPassword(UserDto user) async {
    final controller = TextEditingController();
    final newPassword = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.t('users.passwordModal.title'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.t('users.passwordModal.forUser')} ${user.userName}',
              style: const TextStyle(fontSize: 13, color: AppColors.gray500),
            ),
            const SizedBox(height: 16),
            AppInput(
              label: AppLocalizations.t('users.newPassword'),
              hint: AppLocalizations.t('users.newPasswordPlaceholder'),
              icon: Icons.lock_outline,
              controller: controller,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: AppLocalizations.t('users.resetBtn'),
              fullWidth: true,
              onPressed: () => Navigator.pop(ctx, controller.text),
            ),
          ],
        ),
      ),
    );
    if (newPassword == null || newPassword.trim().length < 6) {
      if (mounted && newPassword != null) {
        showAppToast(context, 'Password must be at least 6 characters.',
            type: ToastType.error);
      }
      return;
    }
    try {
      await _service.resetPassword(
          userId: user.id, newPassword: newPassword.trim());
      if (!mounted) return;
      showAppToast(context, AppLocalizations.t('users.toasts.passwordReset'),
          type: ToastType.success);
    } catch (e) {
      if (mounted) {
        showAppToast(context, e.toString(), type: ToastType.error);
      }
    }
  }

  Future<void> _deleteUser(UserDto user) async {
    final ok = await showConfirmDialog(
      context,
      title: AppLocalizations.t('users.deleteModal.title'),
      message:
          '${AppLocalizations.t('users.deleteModal.confirmBefore')} ${user.userName}${AppLocalizations.t('users.deleteModal.confirmAfter')}',
      confirmLabel: AppLocalizations.t('users.deleteUserBtn'),
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      await _service.deleteUser(user.id);
      if (!mounted) return;
      setState(() => _users.removeWhere((u) => u.id == user.id));
      showAppToast(context, AppLocalizations.t('users.toasts.userDeleted'),
          type: ToastType.success);
    } catch (e) {
      if (mounted) {
        showAppToast(context, e.toString(), type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppLocalizations.t('users.title'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppLocalizations.plural('users.registeredCount', _users.length),
            style: const TextStyle(fontSize: 13, color: AppColors.gray500),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: PageSpinner(),
            )
          else if (_users.isEmpty)
            AppCard(
              child: EmptyState(
                icon: Icons.people_outline,
                title: AppLocalizations.t('users.empty.title'),
                description: AppLocalizations.t('users.empty.description'),
              ),
            )
          else
            Column(
              children: [
                for (final user in _users)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppAvatar(
                                name: user.userName,
                                picturePath: user.profilePicturePath,
                                size: AvatarSize.md,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          user.userName ?? '',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.gray900,
                                          ),
                                        ),
                                        for (final role in user.roles)
                                          AppBadge(
                                            text: role,
                                            variant: _roleVariant(role),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email ??
                                          AppLocalizations.t('users.noEmail'),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.gray500),
                                    ),
                                    if (user.employee != null)
                                      Text(
                                        '${user.employee!.fullName}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.gray500),
                                      ),
                                    if (user.lockoutEnabled &&
                                        user.lockoutEnd != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '${AppLocalizations.t('users.lockedUntil', params: {'date': _formatDate(user.lockoutEnd!)})}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.red600),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AppButton(
                                label:
                                    AppLocalizations.t('users.assignRole'),
                                variant: ButtonVariant.outline,
                                size: ButtonSize.sm,
                                onPressed: () =>
                                    _openRoleAction(user, 'assign'),
                              ),
                              AppButton(
                                label:
                                    AppLocalizations.t('users.changeRole'),
                                variant: ButtonVariant.outline,
                                size: ButtonSize.sm,
                                onPressed: () =>
                                    _openRoleAction(user, 'change'),
                              ),
                              AppButton(
                                label:
                                    AppLocalizations.t('users.removeRole'),
                                variant: ButtonVariant.outline,
                                size: ButtonSize.sm,
                                onPressed: () =>
                                    _openRoleAction(user, 'remove'),
                              ),
                              AppButton(
                                label:
                                    AppLocalizations.t('users.resetPassword'),
                                variant: ButtonVariant.outline,
                                size: ButtonSize.sm,
                                onPressed: () => _openResetPassword(user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: AppColors.red500),
                                onPressed: () => _deleteUser(user),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _RoleResult {
  final String roleName;
  final String currentRole;
  final String newRole;
  const _RoleResult({
    required this.roleName,
    this.currentRole = '',
    this.newRole = '',
  });
}

class _RoleSheet extends StatefulWidget {
  final UserDto user;
  final String action;
  final String title;
  const _RoleSheet({
    required this.user,
    required this.action,
    required this.title,
  });

  @override
  State<_RoleSheet> createState() => _RoleSheetState();
}

class _RoleSheetState extends State<_RoleSheet> {
  final _roleController = TextEditingController();
  final _newRoleController = TextEditingController();

  @override
  void dispose() {
    _roleController.dispose();
    _newRoleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.t;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AppAvatar(
                name: widget.user.userName,
                picturePath: widget.user.profilePicturePath,
                size: AvatarSize.sm,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.userName ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    Text(
                      widget.user.email ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            switch (widget.action) {
              'assign' => t('users.modal.assignText',
                  params: {'name': widget.user.userName ?? ''}),
              'change' => t('users.modal.changeText',
                  params: {'name': widget.user.userName ?? ''}),
              _ => t('users.modal.removeText',
                  params: {'name': widget.user.userName ?? ''}),
            },
            style: const TextStyle(fontSize: 13, color: AppColors.gray600),
          ),
          const SizedBox(height: 14),
          AppInput(
            label: t('users.roleName'),
            hint: t('users.roleNamePlaceholder'),
            controller: _roleController,
          ),
          if (widget.action == 'change') ...[
            const SizedBox(height: 14),
            AppInput(
              label: t('users.newRole'),
              hint: t('users.newRolePlaceholder'),
              controller: _newRoleController,
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
                  label: switch (widget.action) {
                    'assign' => t('users.assignBtn'),
                    'change' => t('users.changeBtn'),
                    _ => t('users.removeBtn'),
                  },
                  onPressed: () {
                    if (widget.action == 'change') {
                      Navigator.pop(
                        context,
                        _RoleResult(
                          roleName: _roleController.text.trim(),
                          currentRole: _roleController.text.trim(),
                          newRole: _newRoleController.text.trim(),
                        ),
                      );
                    } else {
                      Navigator.pop(
                        context,
                        _RoleResult(roleName: _roleController.text.trim()),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
