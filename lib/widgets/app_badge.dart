import 'package:flutter/material.dart';

import '../core/theme.dart';

enum BadgeVariant { default_, success, warning, danger, info }

/// Badge mirroring the web app's Badge variants.
class AppBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final Widget? leading;

  const AppBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.default_,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      BadgeVariant.default_ => (AppColors.gray100, AppColors.gray700),
      BadgeVariant.success => (AppColors.green50, AppColors.green700),
      BadgeVariant.warning => (AppColors.amber50, AppColors.amber700),
      BadgeVariant.danger => (AppColors.red50, AppColors.red700),
      BadgeVariant.info => (AppColors.blue50, AppColors.blue700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
