import 'package:flutter_test/flutter_test.dart';
import 'package:wethaq/widgets/validators.dart';

void main() {
  group('validateStrongPassword', () {
    test('يرفض كلمة مرور أقل من 8 حروف', () {
      final result = validateStrongPassword('Ab1@');
      expect(result, isNotNull);
    });

    test('يرفض كلمة مرور بدون عدد كافي من الحروف/الأرقام/الرموز', () {
      final result = validateStrongPassword('Abcd!!@@');
      expect(result, isNotNull);
    });

    test('يقبل كلمة مرور قوية', () {
      final result = validateStrongPassword('Abcd123!9');
      expect(result, isNull);
    });
  });

  group('isPasswordStrong', () {
    test('تعيد false لكلمة مرور ضعيفة', () {
      expect(isPasswordStrong('abc123'), isFalse);
    });

    test('تعيد true مع كلمة مرور قوية', () {
      expect(isPasswordStrong('Abcd123!9'), isTrue);
    });
  });
}
