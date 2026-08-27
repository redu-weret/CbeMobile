import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';
import '../services/i18n.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_input.dart';
import '../widgets/app_spinner.dart';
import '../widgets/app_toast.dart';
import '../widgets/empty_state.dart';
import 'employee_form_screen.dart';

class EmployeesScreen extends StatefulWidget {
  final bool openForm;
  const EmployeesScreen({super.key, this.openForm = false});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Employee> _employees = [];
  bool _isLoading = true;
  String _search = '';
  final EmployeeService _service = EmployeeService();

  @override
  void initState() {
    super.initState();
    if (widget.openForm) {
      // Open the register form on top after first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openForm(null));
    }
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getAll();
      if (mounted) setState(() => _employees = list);
    } catch (e) {
      if (mounted) {
        showAppToast(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Employee> get _filtered {
    final q = _search.toLowerCase();
    if (q.isEmpty) return _employees;
    return _employees
        .where((e) =>
            e.fullName.toLowerCase().contains(q) ||
            e.employeeId.toLowerCase().contains(q) ||
            e.department.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _delete(Employee emp) async {
    final ok = await showConfirmDialog(
      context,
      title: AppLocalizations.t('employees.deleteModal.title'),
      message:
          '${AppLocalizations.t('employees.deleteModal.confirmBefore')} ${emp.fullName}${AppLocalizations.t('employees.deleteModal.confirmAfter')}',
      confirmLabel: AppLocalizations.t('employees.delete'),
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      await _service.delete(emp.id);
      if (!mounted) return;
      setState(() => _employees.removeWhere((e) => e.id == emp.id));
      showAppToast(context, AppLocalizations.t('employees.toasts.deleted'),
          type: ToastType.success);
    } catch (e) {
      if (mounted) {
        showAppToast(context, e.toString(), type: ToastType.error);
      }
    }
  }

  void _openForm(Employee? emp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeFormScreen(employee: emp),
      ),
    ).then((changed) {
      if (changed == true && mounted) _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.t('employees.title'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.plural('employees.registeredCount',
                          _employees.length),
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: AppLocalizations.t('employees.addEmployee'),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                onPressed: () => _openForm(null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppInput(
            hint: AppLocalizations.t('employees.searchPlaceholder'),
            icon: Icons.search,
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: PageSpinner(),
            )
          else if (filtered.isEmpty)
            AppCard(
              child: EmptyState(
                icon: Icons.people_outline,
                title: _search.isNotEmpty
                    ? AppLocalizations.t('employees.empty.noSearch')
                    : AppLocalizations.t('employees.empty.noEmployees'),
                description: _search.isNotEmpty
                    ? AppLocalizations.t('employees.empty.tryDifferent')
                    : AppLocalizations.t('employees.empty.registerFirst'),
                action: _search.isEmpty
                    ? AppButton(
                        label:
                            AppLocalizations.t('employees.registerEmployee'),
                        icon: const Icon(Icons.add,
                            size: 18, color: Colors.white),
                        onPressed: () => _openForm(null),
                      )
                    : null,
              ),
            )
          else
            Column(
              children: [
                for (final emp in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          AppAvatar(
                            name: emp.fullName,
                            picturePath: emp.profilePicturePath,
                            size: AvatarSize.md,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  emp.fullName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray900,
                                  ),
                                ),
                                Text(
                                  '${emp.employeeId} • ${emp.jobTitle}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.gray500),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.blue50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    emp.department,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.blue700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 20, color: AppColors.gray400),
                            onPressed: () => _openForm(emp),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 20, color: AppColors.gray400),
                            onPressed: () => _delete(emp),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
