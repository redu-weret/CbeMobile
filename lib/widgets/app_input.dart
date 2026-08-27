import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Text input mirroring the web app's Input component: label, leading icon,
/// optional suffix icon (e.g. password visibility toggle) and error text.
///
/// Stateful so `initialValue` can be honored without a controller (TextField
/// itself has no `initialValue` parameter — only TextFormField does).
class AppInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? error;
  final IconData? icon;
  final Widget? suffix;
  final TextEditingController? controller;
  final String? initialValue;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? autofillHint;

  const AppInput({
    super.key,
    this.label,
    this.hint,
    this.error,
    this.icon,
    this.suffix,
    this.controller,
    this.initialValue,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofillHint,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  TextEditingController? _internalController;

  TextEditingController get _controller =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController =
          TextEditingController(text: widget.initialValue ?? '');
    }
  }

  @override
  void didUpdateWidget(covariant AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the internal controller in sync when the widget config changes.
    if (widget.controller == null &&
        widget.initialValue != null &&
        _internalController != null &&
        _internalController!.text != widget.initialValue) {
      _internalController!.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: _controller,
          obscureText: widget.obscureText,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          autofillHints: widget.autofillHint != null
              ? <String>[widget.autofillHint!]
              : null,
          style: const TextStyle(fontSize: 14, color: AppColors.gray900),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppColors.gray400),
            errorText: hasError ? widget.error : null,
            counterText: widget.maxLength != null ? '' : null,
            prefixIcon: widget.icon != null
                ? Icon(widget.icon, size: 18, color: AppColors.gray400)
                : null,
            suffixIcon: widget.suffix,
            filled: true,
            fillColor: widget.enabled ? AppColors.white : AppColors.gray50,
            errorMaxLines: 3,
          ),
        ),
      ],
    );
  }
}
