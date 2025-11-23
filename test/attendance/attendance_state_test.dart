import 'package:flutter_test/flutter_test.dart';
import 'package:wethaq/child_attendance_screen.dart';

void main() {
  group('AttendanceState basic logic', () {
    test('initial state is all zeros', () {
      final s = AttendanceState.zero();

      expect(s.morningParentDropped, 0);
      expect(s.morningTeacherConfirm, 0);
      expect(s.noonParentNear, 0);
      expect(s.noonParentWaiting, 0);
      expect(s.noonTeacherReleased, 0);
    });

    test('copyWith updates only specific fields', () {
      var s = AttendanceState.zero();

      final updated = s.copyWith(morningParentDropped: 1);

      expect(updated.morningParentDropped, 1);
      expect(updated.morningTeacherConfirm, 0);
      expect(updated.noonParentNear, 0);
      expect(updated.noonParentWaiting, 0);
      expect(updated.noonTeacherReleased, 0);
    });
  });

  group('Attendance business rules', () {
    test('Parent can drop child only if not dropped and not confirmed', () {
      final s = AttendanceState.zero();

      final canParentDrop =
          (s.morningParentDropped == 0 && s.morningTeacherConfirm == 0);

      expect(canParentDrop, isTrue);
    });

    test('Staff can confirm only after parent drops', () {
      final s = AttendanceState(
        morningParentDropped: 1,
        morningTeacherConfirm: 0,
        noonParentNear: 0,
        noonParentWaiting: 0,
        noonTeacherReleased: 0,
      );

      final canStaffConfirm =
          (s.morningParentDropped == 1 && s.morningTeacherConfirm == 0);

      expect(canStaffConfirm, isTrue);
    });

    test('Parent cannot wait (afternoon) without Near first', () {
      final s = AttendanceState.zero();

      final canParentWait = (s.noonParentNear == 1 &&
          s.noonParentWaiting == 0 &&
          s.noonTeacherReleased == 0);

      expect(canParentWait, isFalse);
    });

    test('Staff can release only after Parent waiting', () {
      final s = AttendanceState(
        morningParentDropped: 0,
        morningTeacherConfirm: 0,
        noonParentNear: 1,
        noonParentWaiting: 1,
        noonTeacherReleased: 0,
      );

      final canStaffRelease =
          (s.noonParentWaiting == 1 && s.noonTeacherReleased == 0);

      expect(canStaffRelease, isTrue);
    });
  });
}
