import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';
import '../services/i18n.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_input.dart';
import '../widgets/app_spinner.dart';
import '../widgets/app_toast.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee;
  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _employeeId = TextEditingController();
  final _fullName = TextEditingController();
  final _division = TextEditingController();
  final _jobTitle = TextEditingController();
  final _department = TextEditingController();
  final _phone = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = false;
  final Map<String, String> _errors = {};

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    if (e != null) {
      _employeeId.text = e.employeeId;
      _fullName.text = e.fullName;
      _division.text = e.division;
      _jobTitle.text = e.jobTitle;
      _department.text = e.department;
      _phone.text = e.phoneNumber;
    }
  }

  @override
  void dispose() {
    _employeeId.dispose();
    _fullName.dispose();
    _division.dispose();
    _jobTitle.dispose();
    _department.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool _validate() {
    final errors = <String, String>{};
    if (!_isEdit && _employeeId.text.trim().isEmpty) {
      errors['employeeId'] =
          AppLocalizations.t('employeeForm.errors.employeeIdRequired');
    }
    if (_fullName.text.trim().isEmpty) {
      errors['fullName'] =
          AppLocalizations.t('employeeForm.errors.fullNameRequired');
    }
    if (_division.text.trim().isEmpty) {
      errors['division'] =
          AppLocalizations.t('employeeForm.errors.divisionRequired');
    }
    if (_jobTitle.text.trim().isEmpty) {
      errors['jobTitle'] =
          AppLocalizations.t('employeeForm.errors.jobTitleRequired');
    }
    if (_department.text.trim().isEmpty) {
      errors['department'] =
          AppLocalizations.t('employeeForm.errors.departmentRequired');
    }
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (_phone.text.trim().isEmpty) {
      errors['phone'] =
          AppLocalizations.t('employeeForm.errors.phoneRequired');
    } else if (digits.length < 10 || digits.length > 11) {
      errors['phone'] =
          AppLocalizations.t('employeeForm.errors.phoneInvalid');
    }
    setState(() => _errors..clear()..addAll(errors));
    return errors.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);
    try {
      if (_isEdit) {
        await EmployeeService().update(
          widget.employee!.id,
          UpdateEmployeeDto(
            fullName: _fullName.text.trim(),
            division: _division.text.trim(),
            jobTitle: _jobTitle.text.trim(),
            department: _department.text.trim(),
            phoneNumber: _phone.text.trim(),
          ),
        );
        if (!mounted) return;
        showAppToast(context, AppLocalizations.t('employeeForm.toasts.updated'),
            type: ToastType.success);
      } else {
        await EmployeeService().register(
          RegisterEmployeeDto(
            employeeId: _employeeId.text.trim(),
            fullName: _fullName.text.trim(),
            division: _division.text.trim(),
            jobTitle: _jobTitle.text.trim(),
            department: _department.text.trim(),
            phoneNumber: _phone.text.trim(),
          ),
        );
        if (!mounted) return;
        showAppToast(
            context, AppLocalizations.t('employeeForm.toasts.registered'),
            type: ToastType.success);
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showAppToast(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEdit
            ? AppLocalizations.t('employeeForm.editTitle')
            : AppLocalizations.t('employeeForm.registerTitle')),
      ),
      body: _isLoading
          ? const PageSpinner()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (_isEdit) ...[
                        AppAvatar(
                          name: _fullName.text,
                          picturePath: widget.employee?.profilePicturePath,
                          size: AvatarSize.lg,
                        ),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEdit
                                  ? AppLocalizations.t(
                                      'employeeForm.editTitle')
                                  : AppLocalizations.t(
                                      'employeeForm.registerTitle'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray900,
                              ),
                            ),
                            Text(
                              _isEdit
                                  ? AppLocalizations.t(
                                      'employeeForm.editSubtitle')
                                  : AppLocalizations.t(
                                      'employeeForm.registerSubtitle'),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.gray500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isEdit) ...[
                          AppInput(
                            label: AppLocalizations.t('employeeForm.employeeId'),
                            hint: AppLocalizations.t(
                                'employeeForm.employeeIdPlaceholder'),
                            controller: _employeeId,
                            error: _errors['employeeId'],
                            onChanged: (_) =>
                                setState(() => _errors.remove('employeeId')),
                          ),
                          const SizedBox(height: 16),
                        ],
                        AppInput(
                          label: AppLocalizations.t('employeeForm.fullName'),
                          hint: AppLocalizations.t(
                              'employeeForm.fullNamePlaceholder'),
                          controller: _fullName,
                          error: _errors['fullName'],
                          onChanged: (_) =>
                              setState(() => _errors.remove('fullName')),
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          label: AppLocalizations.t('employeeForm.division'),
                          hint: AppLocalizations.t(
                              'employeeForm.divisionPlaceholder'),
                          controller: _division,
                          error: _errors['division'],
                          onChanged: (_) =>
                              setState(() => _errors.remove('division')),
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          label: AppLocalizations.t('employeeForm.jobTitle'),
                          hint: AppLocalizations.t(
                              'employeeForm.jobTitlePlaceholder'),
                          controller: _jobTitle,
                          error: _errors['jobTitle'],
                          onChanged: (_) =>
                              setState(() => _errors.remove('jobTitle')),
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          label: AppLocalizations.t('employeeForm.department'),
                          hint: AppLocalizations.t(
                              'employeeForm.departmentPlaceholder'),
                          controller: _department,
                          error: _errors['department'],
                          onChanged: (_) =>
                              setState(() => _errors.remove('department')),
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          label:
                              AppLocalizations.t('employeeForm.phoneNumber'),
                          hint: AppLocalizations.t(
                              'employeeForm.phoneNumberPlaceholder'),
                          controller: _phone,
                          error: _errors['phone'],
                          keyboardType: TextInputType.phone,
                          onChanged: (_) =>
                              setState(() => _errors.remove('phone')),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: AppLocalizations.t('common.cancel'),
                                variant: ButtonVariant.outline,
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton(
                                label: _isEdit
                                    ? AppLocalizations.t(
                                        'employeeForm.updateBtn')
                                    : AppLocalizations.t(
                                        'employeeForm.registerBtn'),
                                icon: const Icon(Icons.save_outlined,
                                    size: 18, color: Colors.white),
                                isLoading: _isSaving,
                                onPressed: _submit,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
