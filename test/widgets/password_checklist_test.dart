import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wethaq/widgets/password_checklist.dart';

void main() {
  testWidgets('تظهر نصوص الشروط الأربعة دائماً', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PasswordChecklist(password: ''),
        ),
      ),
    );

    expect(find.text('At least 8 characters'), findsOneWidget);
    expect(find.text('At least 4 letters (A–Z)'), findsOneWidget);
    expect(find.text('At least 3 digits (0–9)'), findsOneWidget);
    expect(find.text('At least 1 symbol'), findsOneWidget);
  });

  testWidgets('كل الشروط تكون فاشلة مع كلمة مرور فارغة',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PasswordChecklist(password: ''),
        ),
      ),
    );

    // مع كلمة فاضية: كل الأيقونات يجب أن تكون Icons.cancel
    expect(find.byIcon(Icons.cancel), findsNWidgets(4));
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('كل الشروط تكون ناجحة مع كلمة مرور قوية',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PasswordChecklist(password: 'Abcd123!9'),
        ),
      ),
    );

    // مع كلمة قوية: كل الأيقونات يجب أن تكون check_circle
    expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
    expect(find.byIcon(Icons.cancel), findsNothing);
  });
}
