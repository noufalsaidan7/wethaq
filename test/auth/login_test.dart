import 'package:flutter_test/flutter_test.dart';
import 'package:wethaq/widgets/validators.dart';

void main() {
  group('Username validation', () {
    test('Rejects Arabic letters', () {
      final result = validateUsernameOptional('نوف123');
      expect(result, isNotNull);
    });

    test('Rejects spaces', () {
      final result = validateUsernameOptional('nou fa');
      expect(result, isNotNull);
    });

    test('Rejects invalid characters', () {
      final result = validateUsernameOptional('noufa@@');
      expect(result, isNotNull);
    });

    test('Accepts valid username', () {
      final result = validateUsernameOptional('noufa_123');
      expect(result, null);
    });
  });

  group('Password strength', () {
    test('Rejects short password', () {
      expect(validateStrongPassword('A1!'), isNotNull);
    });

    test('Rejects missing symbols', () {
      expect(validateStrongPassword('AAAA1234'), isNotNull);
    });

    test('Accepts valid strong password', () {
      expect(validateStrongPassword('ABcd123!'), null);
    });
  });
}
