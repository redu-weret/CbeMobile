import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/i18n.dart';

/// Confirmation dialog matching the web app's danger Modals.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.gray900,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 14, color: AppColors.gray600),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            AppLocalizations.t('common.cancel'),
            style: const TextStyle(
                color: AppColors.gray600, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                danger ? AppColors.red600 : AppColors.blue700,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Generic bottom-sheet picker used for simple dropdown-like selection.
Future<T?> showPickerSheet<T>(
  BuildContext context, {
  required String title,
  required List<PickerItem<T>> items,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final item in items)
                  ListTile(
                    title: Text(
                      item.label,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.gray900),
                    ),
                    trailing: item.selected
                        ? const Icon(Icons.check,
                            color: AppColors.blue700, size: 20)
                        : null,
                    onTap: () => Navigator.pop(ctx, item.value),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class PickerItem<T> {
  final String label;
  final T value;
  final bool selected;
  const PickerItem({required this.label, required this.value, this.selected = false});
}
