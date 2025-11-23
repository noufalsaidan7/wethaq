import 'package:flutter_test/flutter_test.dart';
import 'package:wethaq/main.dart';

void main() {
  test('Handle notification without type', () {
    expect(() => handleNotificationTap({}), returnsNormally);
  });

  test('Handle notification with unknown type', () {
    expect(() => handleNotificationTap({'type': 'xyz'}), returnsNormally);
  });
}
