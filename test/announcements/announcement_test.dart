import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Announcement fields presence', () {
    final map = {
      'title': 'Important Message',
      'body': 'School closed tomorrow',
      'created_at': '2025-01-01 10:00'
    };

    expect(map['title'], isNotEmpty);
    expect(map['body'], isNotEmpty);
    expect(map['created_at'], isNotEmpty);
  });
}
