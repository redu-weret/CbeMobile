import 'package:flutter/material.dart';

import '../core/theme.dart';

enum ToastType { success, error, info }

/// Floating toast/snackbar mirroring the web app's toast colors.
void showAppToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
}) {
  final (bg, fg) = switch (type) {
    ToastType.success => (AppColors.green700, AppColors.white),
    ToastType.error => (AppColors.red600, AppColors.white),
    ToastType.info => (AppColors.gray900, AppColors.white),
  };

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              switch (type) {
                ToastType.success => Icons.check_circle,
                ToastType.error => Icons.error,
                ToastType.info => Icons.info,
              },
              color: fg,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 3),
      ),
    );
}
