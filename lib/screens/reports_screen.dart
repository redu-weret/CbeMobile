import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import '../services/attendance_service.dart';
import '../services/i18n.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_toast.dart';

/// Reports & Export — pick CSV/Excel/PDF, download the report, save it to the
/// device and offer to share it.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _format = 'csv';
  bool _isExporting = false;

  static const _formats = [
    (id: 'csv', icon: Icons.table_chart_outlined, key: 'reports.formats.csv'),
    (id: 'excel', icon: Icons.grid_on_outlined, key: 'reports.formats.excel'),
    (id: 'pdf', icon: Icons.picture_as_pdf_outlined, key: 'reports.formats.pdf'),
  ];

  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await AttendanceService().exportData(_format);
      final ext = _format == 'excel' ? 'xlsx' : _format;
      final now = DateTime.now();
      final date =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final fileName = 'AttendanceReport_$date.$ext';

      final dir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      showAppToast(
        context,
        '${AppLocalizations.t('reports.toasts.downloaded')}\n${file.path}',
        type: ToastType.success,
      );

      // Offer to share the file (email, WhatsApp, drive, etc.)
      try {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: _mimeType(_format))],
          text: AppLocalizations.t('reports.title'),
        );
      } catch (_) {
        // Sharing is best-effort.
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _mimeType(String format) => switch (format) {
        'csv' => 'text/csv',
        'pdf' => 'application/pdf',
        _ => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          AppLocalizations.t('reports.title'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.t('reports.subtitle'),
          style: const TextStyle(fontSize: 13, color: AppColors.gray500),
        ),
        const SizedBox(height: 20),
        // Format cards
        Column(
          children: [
            for (final f in _formats)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _formatCard(f),
              ),
          ],
        ),
        AppCardSection(
          header: Text(
            AppLocalizations.t('reports.settingsTitle'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.blue50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.blue200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.blue700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalizations.t('reports.infoText'),
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.blue700,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: AppLocalizations.t('reports.download'),
                icon: const Icon(Icons.download, size: 18, color: Colors.white),
                isLoading: _isExporting,
                fullWidth: true,
                size: ButtonSize.lg,
                onPressed: _export,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _formatCard(({String id, IconData icon, String key}) f) {
    final selected = _format == f.id;
    return InkWell(
      onTap: () => setState(() => _format = f.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue50 : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.blue500 : AppColors.gray200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? AppColors.blue600 : AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                f.icon,
                color: selected ? AppColors.white : AppColors.gray600,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.t(f.key),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  Text(
                    AppLocalizations.t('${f.key}Desc'),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.gray500),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.blue600, size: 20),
          ],
        ),
      ),
    );
  }
}
