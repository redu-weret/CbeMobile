import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Button mirroring the web app's variants:
/// primary (blue-700), secondary (gray-100), outline, danger (red-600), ghost.
class AppButton extends StatelessWidget {
  final String? label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool disabled;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool fullWidth;

  const AppButton({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.disabled = false,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = switch (variant) {
      ButtonVariant.primary => ButtonStyle(
          backgroundColor:
              const WidgetStatePropertyAll(AppColors.blue700),
          foregroundColor: const WidgetStatePropertyAll(AppColors.white),
          overlayColor: const WidgetStatePropertyAll(AppColors.blue800),
        ),
      ButtonVariant.secondary => ButtonStyle(
          backgroundColor:
              const WidgetStatePropertyAll(AppColors.gray100),
          foregroundColor: const WidgetStatePropertyAll(AppColors.gray900),
          overlayColor: const WidgetStatePropertyAll(AppColors.gray200),
        ),
      ButtonVariant.outline => ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.white),
          foregroundColor: const WidgetStatePropertyAll(AppColors.gray700),
          overlayColor: const WidgetStatePropertyAll(AppColors.gray50),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.gray300),
          ),
        ),
      ButtonVariant.danger => ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.red600),
          foregroundColor: const WidgetStatePropertyAll(AppColors.white),
          overlayColor: const WidgetStatePropertyAll(AppColors.red700),
        ),
      ButtonVariant.ghost => ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: const WidgetStatePropertyAll(AppColors.gray600),
          overlayColor: const WidgetStatePropertyAll(AppColors.gray100),
        ),
    };

    final padding = switch (size) {
      ButtonSize.sm => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ButtonSize.md => const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ButtonSize.lg => const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    };

    final fontSize = switch (size) {
      ButtonSize.sm => 13.0,
      ButtonSize.md => 14.0,
      ButtonSize.lg => 15.0,
    };

    final effectiveDisabled = disabled || isLoading || onPressed == null;

    // Spinner color must contrast with the button background (the web app's
    // buttons show a white spinner on primary/danger and dark on light variants).
    final spinnerColor = switch (variant) {
      ButtonVariant.primary || ButtonVariant.danger => Colors.white,
      _ => AppColors.gray700,
    };

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: effectiveDisabled ? null : onPressed,
        style: style.merge(ButtonStyle(
          padding: WidgetStatePropertyAll(padding),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          )),
          textStyle: WidgetStatePropertyAll(TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          )),
        )),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: spinnerColor,
                ),
              ),
              const SizedBox(width: 8),
            ] else if (icon != null) ...[
              icon!,
              const SizedBox(width: 8),
            ],
            if (label != null) Text(label!),
          ],
        ),
      ),
    );
  }
}

enum ButtonVariant { primary, secondary, outline, danger, ghost }

enum ButtonSize { sm, md, lg }
