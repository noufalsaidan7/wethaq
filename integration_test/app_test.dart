import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wethaq/main.dart' as app;

void main() {
  // تهيئة الـ Integration Test
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Splash -> Welcome -> Parent login -> empty fields validation',
    (WidgetTester tester) async {
      // نشغل التطبيق الحقيقي
      app.main();

      // ننتظر السبلاتش + الانتقال للـ WelcomeScreen
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 🔹 نلقى نص "Parent" ونضغط عليه مباشرة
      final parentText = find.text('Parent');
      expect(parentText, findsOneWidget);

      await tester.tap(parentText);
      await tester.pumpAndSettle();

      // نتأكد إننا في شاشة تسجيل دخول الـ Parent
      expect(find.text('Welcome Parent'), findsOneWidget);

      // 🔹 نضغط Log in بدون ما نكتب شيء
      final loginButton = find.widgetWithText(ElevatedButton, 'Log in');
      expect(loginButton, findsOneWidget);

      await tester.tap(loginButton);
      await tester.pump(); // نسمح للـ SnackBar يطلع

      // نتأكد من رسالة الخطأ في SnackBar
      expect(
        find.text('Please enter username and password'),
        findsOneWidget,
      );
    },
  );
}
