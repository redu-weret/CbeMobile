import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/i18n.dart';

/// Language dropdown mirroring the web app's LanguageSelector.
class LanguageSelector extends StatelessWidget {
  final bool compact;
  final Color? textColor;
  final Color? borderColor;

  const LanguageSelector({
    super.key,
    this.compact = false,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.locale,
      builder: (context, current, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor ?? AppColors.gray300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              isExpanded: true,
              isDense: true,
              icon: Icon(
                Icons.language,
                size: 16,
                color: textColor ?? AppColors.gray500,
              ),
              items: [
                for (final code in AppLocalizations.supportedLocales)
                  DropdownMenuItem(
                    value: code,
                    child: Text(
                      compact
                          ? code.toUpperCase()
                          : AppLocalizations.localeNames[code]!,
                      style: TextStyle(
                        fontSize: compact ? 12 : 14,
                        color: textColor ?? AppColors.gray700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
              onChanged: (code) {
                if (code != null) AppLocalizations.setLocale(code);
              },
            ),
          ),
        );
      },
    );
  }
}
