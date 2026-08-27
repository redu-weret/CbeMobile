import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Full-page centered spinner (matches `PageSpinner`).
class PageSpinner extends StatelessWidget {
  const PageSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Small inline spinner row (matches the `Spinner` component with text).
class InlineSpinner extends StatelessWidget {
  final String? message;
  final Color color;

  const InlineSpinner({super.key, this.message, this.color = AppColors.blue700});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
        ),
        if (message != null) ...[
          const SizedBox(width: 10),
          Text(
            message!,
            style: const TextStyle(fontSize: 14, color: AppColors.blue700),
          ),
        ],
      ],
    );
  }
}
