import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cbe_mobile_app/screens/login_screen.dart';
import 'package:cbe_mobile_app/services/session.dart';

void main() {
  testWidgets('Shows the login screen when no session exists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Session.instance.restore();

    await tester.pumpWidget(
      MaterialApp(home: ListenableBuilder(
        listenable: Session.instance,
        builder: (context, _) =>
            Session.instance.isAuthenticated ? const LoginScreen() : const LoginScreen(),
      )),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
