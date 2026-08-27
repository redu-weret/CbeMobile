import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/attendance.dart';
import '../models/auth.dart';
import '../services/attendance_service.dart';
import '../services/employee_service.dart';
import '../services/i18n.dart';
import '../services/session.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_input.dart';
import '../widgets/app_spinner.dart';
import '../widgets/app_toast.dart';

/// Take Attendance — auto-detects the logged-in user's employee ID, shows the
/// check result and records attendance (matches the web page).
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  AttendanceCheckResult? _checkResult;
  bool _isChecking = false;
  bool _isTaking = false;
  String? _checkError;
  String _session = '';

  @override
  void initState() {
    super.initState();
    _autoCheck();
  }

  Future<void> _autoCheck() async {
    final employee = Session.instance.user?.employee;
    if (employee == null) return; // No linked employee — show the hint card.
    setState(() {
      _isChecking = true;
      _checkError = null;
      _checkResult = null;
    });
    try {
      final result = await EmployeeService().checkStatus(employee.employeeId);
      if (mounted) setState(() => _checkResult = result);
    } catch (e) {
      if (mounted) {
        setState(() => _checkError = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _takeAttendance() async {
    final result = _checkResult;
    if (result == null || _isTaking) return;
    setState(() => _isTaking = true);
    try {
      await AttendanceService().take(
        employeeId: result.employeeId,
        session: _session.isEmpty ? null : _session,
      );
      if (!mounted) return;
      showAppToast(
        context,
        AppLocalizations.t('attendance.toasts.recordedFor',
            params: {'name': result.fullName}),
        type: ToastType.success,
      );
      setState(() {
        _checkResult = result.copyWith(
          isAttended: true,
          attendanceTime: DateTime.now().toIso8601String(),
          session: _session.isEmpty ? result.session : _session,
        );
      });
    } catch (e) {
      if (mounted) {
        showAppToast(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isTaking = false);
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final employee = Session.instance.user?.employee;

    return RefreshIndicator(
      onRefresh: _autoCheck,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppLocalizations.t('attendance.title'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.t('attendance.subtitle'),
            style: const TextStyle(fontSize: 13, color: AppColors.gray500),
          ),
          const SizedBox(height: 20),

          // No linked employee
          if (employee == null)
            AppCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.amber50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined,
                        size: 40, color: AppColors.amber500),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.t('attendance.noEmployee.title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.t('attendance.noEmployee.description'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.gray500),
                  ),
                ],
              ),
            )
          else ...[
            _identityCard(employee),
            const SizedBox(height: 16),
            _statusCard(),
          ],
        ],
      ),
    );
  }

  Widget _identityCard(EmployeeLite employee) {
    return AppCardSection(
      header: Row(
        children: [
          const Icon(Icons.shield_outlined,
              size: 18, color: AppColors.blue600),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.t('attendance.identityTitle'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            label: AppLocalizations.t('attendance.employeeId'),
            initialValue: employee.employeeId,
            icon: Icons.shield_outlined,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.t('attendance.sessionOptional'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showPickerSheet<String>(
                context,
                title: AppLocalizations.t('attendance.sessionOptional'),
                items: [
                  PickerItem(
                    label: AppLocalizations.t('attendance.sessionAutoDetect'),
                    value: '',
                    selected: _session.isEmpty,
                  ),
                  PickerItem(
                    label: AppLocalizations.t('attendance.sessionMorning'),
                    value: 'Morning',
                    selected: _session == 'Morning',
                  ),
                  PickerItem(
                    label: AppLocalizations.t('attendance.sessionAfternoon'),
                    value: 'Afternoon',
                    selected: _session == 'Afternoon',
                  ),
                ],
              );
              if (picked != null) setState(() => _session = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gray300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 18, color: AppColors.gray400),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _session.isEmpty
                          ? AppLocalizations.t('attendance.sessionAutoDetect')
                          : _session == 'Morning'
                              ? AppLocalizations.t('attendance.sessionMorning')
                              : AppLocalizations.t('attendance.sessionAfternoon'),
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.gray900),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down,
                      color: AppColors.gray400),
                ],
              ),
            ),
          ),
          if (_isChecking) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.blue50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.blue200),
              ),
              child: InlineSpinner(
                  message: AppLocalizations.t('attendance.checking')),
            ),
          ],
          if (_checkError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.red200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel_outlined,
                      size: 18, color: AppColors.red500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _checkError!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.red700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusCard() {
    final result = _checkResult;
    return AppCardSection(
      header: Row(
        children: [
          const Icon(Icons.fact_check_outlined,
              size: 18, color: AppColors.blue600),
          const SizedBox(width: 8),
          Text(
            result != null
                ? AppLocalizations.t('attendance.statusTitle')
                : AppLocalizations.t('attendance.awaitingCheck'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
        ],
      ),
      child: result == null
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline,
                        size: 36, color: AppColors.gray300),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.t('attendance.checkingStatus'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.t('attendance.checkingStatusDesc'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.gray500),
                  ),
                ],
              ),
            )
          : _resultBody(result),
    );
  }

  Widget _resultBody(AttendanceCheckResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.blue500, AppColors.blue700],
                ),
                shape: BoxShape.circle,
              ),
              child: Text(
                result.fullName.isNotEmpty ? result.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  Text(
                    AppLocalizations.t('attendance.id',
                        params: {'id': result.employeeId}),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.gray500),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _infoGrid(result),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: result.isAttended ? AppColors.green50 : AppColors.amber50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: result.isAttended ? AppColors.green200 : AppColors.amber200,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                result.isAttended
                    ? Icons.check_circle
                    : Icons.cancel_outlined,
                size: 26,
                color:
                    result.isAttended ? AppColors.green600 : AppColors.amber600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.isAttended
                          ? AppLocalizations.t('attendance.alreadyAttended')
                          : AppLocalizations.t('attendance.notYetAttended'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: result.isAttended
                            ? AppColors.green800
                            : AppColors.amber800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${result.meetingDate} — ${result.session}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              if (result.attendanceTime != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule,
                          size: 13, color: AppColors.gray500),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(result.attendanceTime),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (result.isAttended)
          AppBadge(
            text: '✅ ${AppLocalizations.t('attendance.attendanceCompleted')}',
            variant: BadgeVariant.success,
          )
        else
          AppButton(
            label: AppLocalizations.t('attendance.recordAttendance'),
            icon: const Icon(Icons.fact_check, size: 18, color: Colors.white),
            isLoading: _isTaking,
            fullWidth: true,
            size: ButtonSize.lg,
            onPressed: _takeAttendance,
          ),
      ],
    );
  }

  Widget _infoGrid(AttendanceCheckResult result) {    final items = [
      (
        label: AppLocalizations.t('attendance.division'),
        value: result.division,
        icon: Icons.apartment_outlined
      ),
      (
        label: AppLocalizations.t('attendance.jobTitle'),
        value: result.jobTitle,
        icon: Icons.work_outline
      ),
      (
        label: AppLocalizations.t('attendance.department'),
        value: result.department,
        icon: Icons.apartment_outlined
      ),
      (
        label: AppLocalizations.t('attendance.phone'),
        value: result.phoneNumber,
        icon: Icons.phone_outlined
      ),
    ];
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(item.icon, size: 17, color: AppColors.gray400),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.gray500),
                        ),
                        Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
