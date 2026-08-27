import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';
import '../services/i18n.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/app_toast.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_spinner.dart';

/// Admin dashboard — stat cards + recent attendance table (matches the web page).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final data = await AttendanceService().getDashboard();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) {
        showAppToast(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppLocalizations.t('dashboard.title'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.t('dashboard.subtitle'),
            style: const TextStyle(fontSize: 13, color: AppColors.gray500),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: PageSpinner(),
            )
          else if (_data == null)
            const SizedBox.shrink()
          else ...[
            _statGrid(_data!),
            const SizedBox(height: 20),
            _recentSection(_data!),
          ],
        ],
      ),
    );
  }

  Widget _statGrid(DashboardData data) {
    final stats = [
      (
        label: AppLocalizations.t('dashboard.totalEmployees'),
        value: data.totalEmployees.toString(),
        icon: Icons.people,
        bg: AppColors.blue50,
        fg: AppColors.blue600,
      ),
      (
        label: AppLocalizations.t('dashboard.morningAttendance'),
        value: data.todayMorningCount.toString(),
        icon: Icons.wb_sunny_outlined,
        bg: AppColors.amber50,
        fg: AppColors.amber600,
      ),
      (
        label: AppLocalizations.t('dashboard.afternoonAttendance'),
        value: data.todayAfternoonCount.toString(),
        icon: Icons.nightlight_outlined,
        bg: AppColors.indigo50,
        fg: AppColors.indigo600,
      ),
    ];

    return Column(
      children: [
        for (final s in stats)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.label,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.gray500,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.value,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: s.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(s.icon, color: s.fg, size: 24),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _recentSection(DashboardData data) {
    return AppCardSection(
      header: Text(
        AppLocalizations.t('dashboard.recentAttendances'),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.gray900,
        ),
      ),
      contentPadding: EdgeInsets.zero,
      child: data.recentAttendances.isEmpty
          ? EmptyState(
              icon: Icons.fact_check_outlined,
              title: AppLocalizations.t('dashboard.empty.title'),
              description: AppLocalizations.t('dashboard.empty.description'),
            )
          : Column(
              children: [
                for (final record in data.recentAttendances)
                  _recordTile(record),
              ],
            ),
    );
  }

  Widget _recordTile(AttendanceRecord record) {
    final isMorning = record.session.toLowerCase() == 'morning';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blue50,
              shape: BoxShape.circle,
            ),
            child: Text(
              record.employeeFullName.isNotEmpty
                  ? record.employeeFullName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.blue700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.employeeFullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                Text(
                  record.employeeUniqueId,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.gray500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppBadge(
                text: isMorning
                    ? AppLocalizations.t('dashboard.session.morning')
                    : AppLocalizations.t('dashboard.session.afternoon'),
                variant:
                    isMorning ? BadgeVariant.warning : BadgeVariant.info,
                leading: Icon(
                  isMorning ? Icons.wb_sunny : Icons.nightlight,
                  size: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(record.attendanceTime),
                style:
                    const TextStyle(fontSize: 12, color: AppColors.gray500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return iso;
    }
  }
}
