import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/profile_service.dart';

enum AvatarSize { sm, md, lg, xl }

/// Avatar matching the web app's ProfileAvatar: shows the profile picture if
/// available, otherwise a colored circle with the first letter.
class AppAvatar extends StatelessWidget {
  final String? name;
  final String? picturePath;
  final File? localFile;
  final AvatarSize size;
  final Color? background;

  const AppAvatar({
    super.key,
    this.name,
    this.picturePath,
    this.localFile,
    this.size = AvatarSize.md,
    this.background,
  });

  double get _dimension => switch (size) {
        AvatarSize.sm => 36,
        AvatarSize.md => 44,
        AvatarSize.lg => 56,
        AvatarSize.xl => 96,
      };

  double get _fontSize => switch (size) {
        AvatarSize.sm => 15,
        AvatarSize.md => 18,
        AvatarSize.lg => 22,
        AvatarSize.xl => 36,
      };

  @override
  Widget build(BuildContext context) {
    final url = ProfileService.pictureUrl(picturePath);
    final initial = (name ?? '?').trim().isEmpty
        ? '?'
        : (name!.trim()[0]).toUpperCase();

    return Container(
      width: _dimension,
      height: _dimension,
      decoration: BoxDecoration(
        color: background ?? AppColors.blue50,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.blue100, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: localFile != null
          ? Image.file(
              localFile!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initial(initial),
            )
          : url != null
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initial(initial),
                )
              : _initial(initial),
    );
  }

  Widget _initial(String initial) => Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.blue700,
          ),
        ),
      );
}
