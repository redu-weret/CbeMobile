import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/auth.dart';
import '../services/i18n.dart';
import '../services/session.dart';
import '../services/user_service.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_toast.dart';
import '../widgets/language_selector.dart';
import 'attendance_screen.dart';
import 'change_password_sheet.dart';
import 'dashboard_screen.dart';
import 'employees_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'server_settings_screen.dart';
import 'users_screen.dart';

/// Main authenticated shell — mirrors the web layout:
///  - hamburger + slide-in sidebar (logo header, nav, user section)
///  - bottom navigation for the primary destinations
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _NavItem {
  final String key;
  final IconData icon;
  final IconData activeIcon;
  final bool adminOnly;
  final Widget Function() builder;
  const _NavItem({
    required this.key,
    required this.icon,
    required this.activeIcon,
    this.adminOnly = false,
    required this.builder,
  });
}

class _ShellScreenState extends State<ShellScreen> {
  static const int _maxBottomNav = 5;
  int _index = 0;
  bool _drawerOpen = false;

  final List<_NavItem> _allNav = [
    _NavItem(
      key: 'nav.dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      adminOnly: true,
      builder: () => const DashboardScreen(),
    ),
    _NavItem(
      key: 'nav.takeAttendance',
      icon: Icons.fact_check_outlined,
      activeIcon: Icons.fact_check,
      builder: () => const AttendanceScreen(),
    ),
    _NavItem(
      key: 'nav.myProfile',
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle,
      builder: () => const ProfileScreen(),
    ),
    _NavItem(
      key: 'nav.employees',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      adminOnly: true,
      builder: () => const EmployeesScreen(),
    ),
    _NavItem(
      key: 'nav.reports',
      icon: Icons.insert_chart_outlined,
      activeIcon: Icons.insert_chart,
      adminOnly: true,
      builder: () => const ReportsScreen(),
    ),
    _NavItem(
      key: 'nav.users',
      icon: Icons.manage_accounts_outlined,
      activeIcon: Icons.manage_accounts,
      adminOnly: true,
      builder: () => const UsersScreen(),
    ),
  ];

  List<_NavItem> get _visibleNav =>
      _allNav.where((n) => !n.adminOnly || Session.instance.isAdmin).toList();

  @override
  void dispose() {
    Session.instance.removeListener(_onSession);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Session.instance.addListener(_onSession);
    // If the user is not admin and the current tab is admin-only, jump to
    // the first visible destination.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final visible = _visibleNav;
      if (_index >= visible.length) {
        setState(() => _index = 0);
      }
    });
  }

  void _onSession() {
    if (mounted && !Session.instance.isAuthenticated) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
        (route) => false,
      );
    }
  }

  void _openDrawer() => setState(() => _drawerOpen = true);
  void _closeDrawer() => setState(() => _drawerOpen = false);

  void _navigateTo(int index) {
    setState(() => _index = index);
    _closeDrawer();
  }

  Future<void> _handleLogout() async {
    _closeDrawer();
    await Session.instance.logout();
  }

  Future<void> _handleDeleteAccount() async {
    _closeDrawer();
    final ok = await showConfirmDialog(
      context,
      title: AppLocalizations.t('deleteAccount.title'),
      message: AppLocalizations.t('deleteAccount.warning') +
          '. ' +
          AppLocalizations.t('deleteAccount.description'),
      confirmLabel: AppLocalizations.t('deleteAccount.confirm'),
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      await UserService().deleteCurrentUser();
      if (!mounted) return;
      showAppToast(context, AppLocalizations.t('deleteAccount.success'),
          type: ToastType.success);
      await Session.instance.logout();
    } catch (e) {
      if (mounted) {
        showAppToast(context, e.toString(), type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.instance.user;
    final visible = _visibleNav;
    if (visible.isEmpty) {
      return const Center(child: Text('No accessible sections.'));
    }
    final safeIndex = _index.clamp(0, visible.length - 1);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _topBar(visible[safeIndex]),
              Expanded(child: visible[safeIndex].builder()),
            ],
          ),
          // Drawer + scrim overlay
          if (_drawerOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeDrawer,
                child: Container(color: Colors.black.withValues(alpha: 0.3)),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            left: _drawerOpen ? 0 : -300,
            top: 0,
            bottom: 0,
            width: 280,
            child: Material(
              color: AppColors.white,
              elevation: 16,
              child: _buildDrawer(user, visible, safeIndex),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final bottomItems = visible.take(_maxBottomNav).toList();
          final bottomIndex = safeIndex.clamp(0, bottomItems.length - 1);
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.gray200, width: 0.5)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 62,
                child: Row(
                  children: [
                    for (var i = 0; i < bottomItems.length; i++)
                      Expanded(
                        child: _BottomNavItem(
                          item: bottomItems[i],
                          isSelected: i == bottomIndex,
                          onTap: () => _navigateTo(visible.indexOf(bottomItems[i])),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _topBar(_NavItem current) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              IconButton(
                onPressed: _openDrawer,
                icon: const Icon(Icons.menu, size: 22, color: AppColors.gray700),
                tooltip: AppLocalizations.t('nav.toggleMenu'),
              ),
              const SizedBox(width: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/cbe-logo.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.t('app.name').split(' ').take(3).join(' '),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    Text(
                      AppLocalizations.t(current.key),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 110,
                child: LanguageSelector(compact: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(CurrentUser? user, List<_NavItem> visible, int safeIndex) {
    return Column(
      children: [
        // Logo header (blue-700, like the web sidebar)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: AppColors.blue700),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/cbe-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CBE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      AppLocalizations.t('app.tagline'),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.blue100),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Nav
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            children: [
              for (var i = 0; i < visible.length; i++)
                _drawerItem(visible[i], i == safeIndex, () => _navigateTo(i)),
              const Divider(height: 24),
              ListTile(
                dense: true,
                leading: const Icon(Icons.settings_outlined,
                    size: 20, color: AppColors.gray500),
                title: const Text('Server settings',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.gray700)),
                onTap: () {
                  _closeDrawer();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ServerSettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        // User section
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.gray200)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  final idx = visible.indexWhere((n) => n.key == 'nav.myProfile');
                  _navigateTo(idx >= 0 ? idx : 0);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      AppAvatar(
                        name: user?.userName,
                        picturePath: user?.profilePicturePath,
                        size: AvatarSize.sm,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.userName ?? AppLocalizations.t('common.user'),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray900,
                              ),
                            ),
                            Text(
                              user?.email ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.gray500),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.settings, size: 16, color: AppColors.gray400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _menuButton(
                icon: Icons.lock_reset,
                label: AppLocalizations.t('userMenu.changePassword'),
                onTap: () {
                  _closeDrawer();
                  _openChangePassword();
                },
              ),
              _menuButton(
                icon: Icons.delete_outline,
                label: AppLocalizations.t('userMenu.deleteAccount'),
                color: AppColors.red600,
                onTap: _handleDeleteAccount,
              ),
              _menuButton(
                icon: Icons.logout,
                label: AppLocalizations.t('userMenu.signOut'),
                onTap: _handleLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _drawerItem(_NavItem item, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: active ? AppColors.blue50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              active ? item.activeIcon : item.icon,
              size: 20,
              color: active ? AppColors.blue700 : AppColors.gray600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.t(item.key),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: active ? AppColors.blue700 : AppColors.gray600,
                ),
              ),
            ),
            if (active)
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.blue700),
          ],
        ),
      ),
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.gray700,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(fontSize: 13.5, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _openChangePassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ChangePasswordSheet(),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.blue50 : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                size: 22,
                color: isSelected ? AppColors.blue700 : AppColors.gray500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _shortLabel(item.key),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.blue700 : AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _shortLabel(String key) {
    switch (key) {
      case 'nav.dashboard': return 'Home';
      case 'nav.takeAttendance': return 'Attendance';
      case 'nav.myProfile': return 'Profile';
      case 'nav.employees': return 'Employees';
      case 'nav.reports': return 'Reports';
      case 'nav.users': return 'Users';
      default: return key.split('.').last;
    }
  }
}
