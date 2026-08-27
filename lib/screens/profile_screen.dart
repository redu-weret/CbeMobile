import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';
import '../services/i18n.dart';
import '../services/profile_service.dart';
import '../services/session.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_spinner.dart';

/// My Profile — manage the profile picture and view account details.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isDeleting = false;
  String? _error;
  File? _selected;
  String? _selectedName;

  Future<void> _pickImage() async {
    setState(() => _error = null);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      final file = File(picked.path);
      final validation = ProfileService.validate(file, picked.name);
      if (validation != null) {
        setState(() => _error = validation);
        return;
      }
      setState(() {
        _selected = file;
        _selectedName = picked.name;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not pick the image.');
    }
  }

  Future<void> _upload() async {
    final file = _selected;
    final name = _selectedName;
    final user = Session.instance.user;
    if (file == null || name == null || user == null || _isUploading) return;

    setState(() {
      _isUploading = true;
      _error = null;
    });
    try {
      final hasPicture = user.profilePicturePath != null;
      final updated = hasPicture
          ? await ProfileService().update(
              userId: user.userId, file: file, fileName: name)
          : await ProfileService().upload(
              userId: user.userId, file: file, fileName: name);
      await Session.instance.updateUser(updated);
      if (!mounted) return;
      showAppToast(
        context,
        hasPicture
            ? AppLocalizations.t('profile.toasts.updated')
            : AppLocalizations.t('profile.toasts.uploaded'),
        type: ToastType.success,
      );
      setState(() {
        _selected = null;
        _selectedName = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _removePicture() async {
    final user = Session.instance.user;
    if (user == null || _isDeleting) return;
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      await ProfileService().remove(user.userId);
      await Session.instance.updateUser(user.copyWith(profilePicturePath: null));
      if (!mounted) return;
      showAppToast(context, AppLocalizations.t('profile.toasts.removed'),
          type: ToastType.success);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.instance.user;
    if (user == null) return const PageSpinner();

    final hasPicture = user.profilePicturePath != null;
    final t = AppLocalizations.t;

    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t('profile.title'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            t('profile.subtitle'),
            style: const TextStyle(fontSize: 13, color: AppColors.gray500),
          ),
          const SizedBox(height: 20),
          // Picture card
          AppCardSection(
            header: Text(
              t('profile.pictureTitle'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: AppAvatar(
                    name: user.userName,
                    picturePath: user.profilePicturePath,
                    localFile: _selected,
                    size: AvatarSize.xl,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Wrap(
                    spacing: 6,
                    children: [
                      for (final role in user.roles)
                        AppBadge(
                          text: role,
                          variant: role == 'Admin'
                              ? BadgeVariant.danger
                              : BadgeVariant.default_,
                        ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
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
                if (_selected != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.blue200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 18, color: AppColors.blue700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedName ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.blue800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: t('cropper.usePhoto'),
                          isLoading: _isUploading,
                          onPressed: _upload,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: t('common.cancel'),
                          variant: ButtonVariant.outline,
                          onPressed: () => setState(() {
                            _selected = null;
                            _selectedName = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Text(
                    hasPicture
                        ? t('profile.pictureIntro')
                        : t('profile.pictureIntroNone'),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.gray600, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      AppButton(
                        label: hasPicture
                            ? t('profile.chooseNewPicture')
                            : t('profile.choosePicture'),
                        icon: const Icon(Icons.add_a_photo_outlined,
                            size: 18, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                      if (hasPicture)
                        AppButton(
                          label: t('profile.removePicture'),
                          variant: ButtonVariant.danger,
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.white),
                          isLoading: _isDeleting,
                          onPressed: _removePicture,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t('profile.allowedTypes'),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.gray400),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Account details
          AppCardSection(
            header: Text(
              t('profile.accountDetails'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            child: Column(
              children: [
                _detailItem(
                  icon: Icons.person_outline,
                  label: t('profile.username'),
                  value: user.userName ?? '—',
                ),
                _detailItem(
                  icon: Icons.mail_outline,
                  label: t('profile.email'),
                  value: user.email ?? '—',
                ),
                _detailItem(
                  icon: Icons.badge_outlined,
                  label: t('profile.employee'),
                  value: user.employee?.fullName ?? '—',
                ),
                _detailItem(
                  icon: Icons.shield_outlined,
                  label: t('profile.role'),
                  value: user.roles.join(', '),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Icon(icon, size: 18, color: AppColors.blue700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray500,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
