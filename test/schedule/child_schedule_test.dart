import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Schedule formatting', () {
    String format2Digits(int v) => v.toString().padLeft(2, '0');

    test('Formats single digit numbers', () {
      expect(format2Digits(4), '04');
    });

    test('Formats double digit numbers', () {
      expect(format2Digits(12), '12');
    });
  });
}
