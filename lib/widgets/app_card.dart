import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Card matching the web app: white, gray-200 border, rounded-xl, shadow-sm.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool hover;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.hover = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Card with a header row + content, matching CardHeader/CardContent.
class AppCardSection extends StatelessWidget {
  final Widget? header;
  final Widget child;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry contentPadding;

  const AppCardSection({
    super.key,
    this.header,
    required this.child,
    this.headerPadding =
        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.contentPadding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Container(
              width: double.infinity,
              padding: headerPadding,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.gray100)),
              ),
              child: header,
            ),
          ],
          Padding(padding: contentPadding, child: child),
        ],
      ),
    );
  }
}
