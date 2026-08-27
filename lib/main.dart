import 'package:flutter/material.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'services/i18n.dart';
import 'services/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  await AppLocalizations.load();
  await Session.instance.restore();
  runApp(const CbeAttendanceApp());
}

class CbeAttendanceApp extends StatelessWidget {
  const CbeAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CBE Meeting Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: ListenableBuilder(
        listenable: Session.instance,
        builder: (context, _) {
          if (!Session.instance.initialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Session.instance.isAuthenticated
              ? const ShellScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
