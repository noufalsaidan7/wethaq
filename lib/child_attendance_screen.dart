// child_attendance_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// شاشة حضور/انصراف طفل واحد
class ChildAttendanceScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final String staffName;
  final int parentUserId;
  final int staffUserId;

  /// true = عرض المعلّم، false = عرض ولي الأمر
  final bool isStaffView;

  const ChildAttendanceScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.staffName,
    required this.parentUserId,
    required this.staffUserId,
    this.isStaffView = false, // الافتراضي Parent view
  });

  @override
  State<ChildAttendanceScreen> createState() => _ChildAttendanceScreenState();
}

class _ChildAttendanceScreenState extends State<ChildAttendanceScreen> {
  // غيّري الجذر لو مجلّدك مختلف
  static const String baseUrl = 'http://10.0.2.2/wethaq';
  static const Color kGreen = Color(0xFF507C5C);

  bool get _isStaff => widget.isStaffView;
  bool get _isParent => !widget.isStaffView;

  /// الحالة تبدأ بصفر (مهم عشان الأزرار تشتغل من أول ما تفتح الصفحة)
  AttendanceState _state = AttendanceState.zero();
  bool _loadingState = false;

  /// جدول الحضور/الانصراف
  final Map<String, String> _attendance = {
    'sun': '',
    'mon': '',
    'tue': '',
    'wed': '',
    'thu': '',
  };
  final Map<String, String> _dismissal = {
    'sun': '',
    'mon': '',
    'tue': '',
    'wed': '',
    'thu': '',
  };

  bool _loadingSchedule = false;
  bool _savingSchedule = false;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadState(), _loadSchedule()]);
  }

  // -------------------- Attendance state --------------------

  Future<void> _loadState() async {
    setState(() => _loadingState = true);
    try {
      final uri = Uri.parse(
          '$baseUrl/get_attendance_state.php?child_id=${widget.childId}');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j is Map && j['status'] == 'success') {
          final s = Map<String, dynamic>.from(j['state'] ?? {});
          setState(() {
            _state = AttendanceState(
              morningParentDropped: _toInt(s['morning_parent_dropped']),
              morningTeacherConfirm: _toInt(s['morning_teacher_confirm']),
              noonParentWaiting: _toInt(s['noon_parent_waiting']),
              noonTeacherReleased: _toInt(s['noon_teacher_released']),
            );
          });
        }
      }
    } catch (_) {
      // تجاهل بهدوء
    } finally {
      if (mounted) setState(() => _loadingState = false);
    }
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// يرسل أحد الأحداث الأربع ويحدّث الحالة (تفاؤلي + تأكيد من السيرفر)
  Future<void> _sendAttendanceAction({required String action}) async {
    // تحديث تفاؤلي سريع
    setState(() {
      if (action == 'parent_dropped') {
        _state = _state.copyWith(morningParentDropped: 1);
      } else if (action == 'staff_checked_in') {
        _state = _state.copyWith(morningTeacherConfirm: 1);
      } else if (action == 'parent_waiting') {
        _state = _state.copyWith(noonParentWaiting: 1);
      } else if (action == 'staff_checked_out') {
        _state = _state.copyWith(noonTeacherReleased: 1);
      }
    });

    try {
      final uri = Uri.parse('$baseUrl/notify_attendance_event.php');
      final body = {
        'actor_role': _isParent ? 'Parent' : 'Staff',
        'actor_user_id':
            _isParent ? '${widget.parentUserId}' : '${widget.staffUserId}',
        'child_id': '${widget.childId}',
        // one of: parent_dropped | staff_checked_in | parent_waiting | staff_checked_out
        'action': action,
      };

      final res =
          await http.post(uri, body: body).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j is Map && j['status'] == 'success') {
          // لو السيرفر يرجّع الحالة الحالية نقرأها (يفيد لما المعلّم يرجّع للوضع الافتراضي)
          final st = Map<String, dynamic>.from(j['state'] ?? {});
          if (st.isNotEmpty) {
            setState(() {
              _state = AttendanceState(
                morningParentDropped: _toInt(st['morning_parent_dropped']),
                morningTeacherConfirm: _toInt(st['morning_teacher_confirm']),
                noonParentWaiting: _toInt(st['noon_parent_waiting']),
                noonTeacherReleased: _toInt(st['noon_teacher_released']),
              );
            });
          } else {
            // وإلا نتأكد بقراءة صريحة
            await _loadState();
          }
          _snack('تم التحديث ✅');
        } else {
          _snack((j is Map ? j['message'] : 'تعذّر الإرسال').toString());
          await _loadState(); // نرجّع الحقيقة لو صار خطأ
        }
      } else {
        _snack('فشل الاتصال (${res.statusCode})');
        await _loadState();
      }
    } catch (e) {
      _snack('خطأ في الاتصال: $e');
      await _loadState();
    }
  }

  // -------------------- Schedule (table) --------------------

  Future<void> _loadSchedule() async {
    setState(() => _loadingSchedule = true);
    try {
      final viewerRole = _isStaff ? 'Staff' : 'Parent';
      final uri = Uri.parse(
          '$baseUrl/get_child_schedule.php?child_id=${widget.childId}&viewer_role=$viewerRole');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j is Map && j['status'] == 'success') {
          final sched = Map<String, dynamic>.from(j['schedule'] ?? {});
          final att = Map<String, dynamic>.from(sched['attendance'] ?? {});
          final dis = Map<String, dynamic>.from(sched['dismissal'] ?? {});
          for (final d in _attendance.keys) {
            _attendance[d] = (att[d] ?? '').toString();
          }
          for (final d in _dismissal.keys) {
            _dismissal[d] = (dis[d] ?? '').toString();
          }
          setState(() {});
        }
      }
    } catch (_) {
      // تجاهل
    } finally {
      if (mounted) setState(() => _loadingSchedule = false);
    }
  }

  Future<void> _saveSchedule({required bool publish}) async {
    if (!_isStaff) return; // الأب غير مسموح له

    setState(() => _savingSchedule = true);
    try {
      final uri = Uri.parse('$baseUrl/save_child_schedule.php');
      final body = {
        'child_id': '${widget.childId}',
        'publish': publish ? '1' : '0',
        // إرسال جميع الأيام
        'attendance_sun': _attendance['sun'] ?? '',
        'attendance_mon': _attendance['mon'] ?? '',
        'attendance_tue': _attendance['tue'] ?? '',
        'attendance_wed': _attendance['wed'] ?? '',
        'attendance_thu': _attendance['thu'] ?? '',
        'dismissal_sun': _dismissal['sun'] ?? '',
        'dismissal_mon': _dismissal['mon'] ?? '',
        'dismissal_tue': _dismissal['tue'] ?? '',
        'dismissal_wed': _dismissal['wed'] ?? '',
        'dismissal_thu': _dismissal['thu'] ?? '',
      };

      final res =
          await http.post(uri, body: body).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j is Map && j['status'] == 'success') {
          _snack(publish ? 'تم نشر الجدول ✅' : 'تم حفظ الجدول ✅');
        } else {
          _snack((j is Map ? j['message'] : 'خطأ في الحفظ').toString());
        }
      } else {
        _snack('فشل الاتصال (${res.statusCode})');
      }
    } catch (e) {
      _snack('خطأ: $e');
    } finally {
      if (mounted) setState(() => _savingSchedule = false);
    }
  }

  // -------------------- Helpers --------------------

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _format2Digits(int v) => v.toString().padLeft(2, '0');
  String _fmt(TimeOfDay t) =>
      '${_format2Digits(t.hour)}:${_format2Digits(t.minute)}';

  Future<void> _pickTime({
    required bool isAttendance,
    required String dayKey,
  }) async {
    if (!_isStaff) return; // الأب لا يعدّل
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      helpText: isAttendance ? 'اختر وقت الحضور' : 'اختر وقت الانصراف',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) {
      setState(() {
        if (isAttendance) {
          _attendance[dayKey] = _fmt(picked);
        } else {
          _dismissal[dayKey] = _fmt(picked);
        }
      });
    }
  }

  // -------------------- Permission logic --------------------

  bool get _canParentDropMorning =>
      _isParent &&
      _state.morningParentDropped == 0 &&
      _state.morningTeacherConfirm == 0;

  bool get _canStaffCheckInMorning =>
      _isStaff &&
      _state.morningParentDropped == 1 &&
      _state.morningTeacherConfirm == 0;

  bool get _canParentWaitNoon =>
      _isParent &&
      _state.noonParentWaiting == 0 &&
      _state.noonTeacherReleased == 0;

  bool get _canStaffReleaseNoon =>
      _isStaff &&
      _state.noonParentWaiting == 1 &&
      _state.noonTeacherReleased == 0;

  // حالات "معلّقة" لعمل زر الأب باللون الأحمر
  bool get _isMorningPending =>
      _state.morningParentDropped == 1 && _state.morningTeacherConfirm == 0;

  bool get _isNoonPending =>
      _state.noonParentWaiting == 1 && _state.noonTeacherReleased == 0;

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green.shade50,
        title: Text(
          widget.childName,
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(20),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text("Attendance",
                style: TextStyle(color: Colors.black54, fontSize: 12)),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_loadingState || _loadingSchedule)
                const LinearProgressIndicator(minHeight: 2),

              // بطاقة معلومات عامة
              Card(
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("المعلّم: ${widget.staffName}",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text("الصف: KG-1",
                          style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Morning / Afternoon
              _buildMorningSection(),
              const SizedBox(height: 12),
              _buildAfternoonSection(),
              const SizedBox(height: 18),

              // جدول الحضور/الانصراف
              _buildAttendanceTable(isStaff: _isStaff),
              const SizedBox(height: 16),

              // أزرار الجدول للمعلّم فقط
              if (_isStaff)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _savingSchedule
                          ? null
                          : () => _saveSchedule(publish: false),
                      child: _savingSchedule
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("حفظ الجدول",
                              style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _savingSchedule
                          ? null
                          : () => _saveSchedule(publish: true),
                      child: _savingSchedule
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("نشر للجميع",
                              style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Widgets: Morning / Afternoon ----------

  Widget _buildMorningSection() {
    String caption;
    if (_state.morningParentDropped == 0 && _state.morningTeacherConfirm == 0) {
      caption = 'اضغط الزر المناسب لبدء حضور الصباح';
    } else if (_isMorningPending) {
      caption = 'الأب سجّل الإنزال — بانتظار تأكيد المعلّم';
    } else {
      caption = 'الطفل داخل المدرسة الآن';
    }

    // نستخدم أحمر فقط في وضع الانتظار
    final Color cardColor =
        _isMorningPending ? Colors.red.shade100 : Colors.green.shade50;

    return _ActionCard(
      title: 'Morning',
      caption: caption,
      color: cardColor,
      icon: Icons.wb_sunny_rounded,
      child: Column(
        children: [
          if (_isParent)
            _PrimaryButton(
              label: _isMorningPending
                  ? 'تم الإنزال (بانتظار المعلّم)'
                  : 'نزلت طفلي',
              enabled: _canParentDropMorning,
              onPressed: _canParentDropMorning
                  ? () => _sendAttendanceAction(action: 'parent_dropped')
                  : null,
              icon: Icons.directions_walk_rounded,
              background: _isMorningPending ? Colors.red.shade300 : kGreen,
              foreground: Colors.white,
            ),
          if (_isStaff) const SizedBox(height: 10),
          if (_isStaff)
            _PrimaryButton(
              label: 'الطفل داخل المدرسة الآن',
              enabled: _canStaffCheckInMorning,
              onPressed: _canStaffCheckInMorning
                  ? () => _sendAttendanceAction(action: 'staff_checked_in')
                  : null,
              background: Colors.red.shade300,
              foreground: Colors.white,
              icon: Icons.verified_rounded,
            ),
        ],
      ),
    );
  }

  Widget _buildAfternoonSection() {
    String caption;
    if (_state.noonParentWaiting == 0 && _state.noonTeacherReleased == 0) {
      caption = 'اضغط الزر المناسب للانصراف';
    } else if (_isNoonPending) {
      caption = 'ولي الأمر بانتظار الاستلام';
    } else {
      caption = 'تم تسليم الطفل لولي الأمر';
    }

    final Color cardColor =
        _isNoonPending ? Colors.red.shade100 : Colors.green.shade50;

    return _ActionCard(
      title: 'Afternoon',
      caption: caption,
      color: cardColor,
      icon: Icons.nights_stay_rounded,
      child: Column(
        children: [
          if (_isParent)
            _PrimaryButton(
              label: _isNoonPending ? 'بانتظار التسليم' : 'أنا خارج المدرسة',
              enabled: _canParentWaitNoon,
              onPressed: _canParentWaitNoon
                  ? () => _sendAttendanceAction(action: 'parent_waiting')
                  : null,
              icon: Icons.door_front_door_outlined,
              background: _isNoonPending ? Colors.red.shade300 : kGreen,
              foreground: Colors.white,
            ),
          if (_isStaff) const SizedBox(height: 10),
          if (_isStaff)
            _PrimaryButton(
              label: 'تم تسليم الطفل',
              enabled: _canStaffReleaseNoon,
              onPressed: _canStaffReleaseNoon
                  ? () => _sendAttendanceAction(action: 'staff_checked_out')
                  : null,
              background: Colors.red.shade300,
              foreground: Colors.white,
              icon: Icons.check_circle_outline_rounded,
            ),
        ],
      ),
    );
  }

  /// جدول الحضور/الانصراف
  Widget _buildAttendanceTable({required bool isStaff}) {
    final header = const TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        Padding(
            padding: EdgeInsets.all(6),
            child: Text("اليوم/الوقت",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(
            padding: EdgeInsets.all(6),
            child: Text("الأحد", textAlign: TextAlign.center)),
        Padding(
            padding: EdgeInsets.all(6),
            child: Text("الإثنين", textAlign: TextAlign.center)),
        Padding(
            padding: EdgeInsets.all(6),
            child: Text("الثلاثاء", textAlign: TextAlign.center)),
        Padding(
            padding: EdgeInsets.all(6),
            child: Text("الأربعاء", textAlign: TextAlign.center)),
        Padding(
            padding: EdgeInsets.all(6),
            child: Text("الخميس", textAlign: TextAlign.center)),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("جدول الحضور والانصراف",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Table(
            border: TableBorder.all(color: Colors.black26),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
              3: FlexColumnWidth(),
              4: FlexColumnWidth(),
              5: FlexColumnWidth(),
            },
            children: [
              header,
              _buildRow(title: "الحضور", isAttendance: true, isStaff: isStaff),
              _buildRow(
                  title: "الانصراف", isAttendance: false, isStaff: isStaff),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildRow({
    required String title,
    required bool isAttendance,
    required bool isStaff,
  }) {
    final keys = ['sun', 'mon', 'tue', 'wed', 'thu'];

    Widget _cell(String key) {
      final value = isAttendance ? _attendance[key]! : _dismissal[key]!;
      if (!isStaff) {
        // عرض فقط
        return Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.center,
          ),
        );
      }
      // قابل للنقر لاختيار وقت
      return InkWell(
        onTap: () => _pickTime(isAttendance: isAttendance, dayKey: key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          alignment: Alignment.center,
          child: Text(
            value.isEmpty ? 'اختر' : value,
            style: TextStyle(
              fontWeight: value.isEmpty ? FontWeight.normal : FontWeight.w600,
              color: value.isEmpty ? Colors.black54 : kGreen,
            ),
          ),
        ),
      );
    }

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        for (final k in keys) _cell(k),
      ],
    );
  }
}

// ===== Models & shared widgets =====

class AttendanceState {
  final int morningParentDropped;
  final int morningTeacherConfirm;
  final int noonParentWaiting;
  final int noonTeacherReleased;

  AttendanceState({
    required this.morningParentDropped,
    required this.morningTeacherConfirm,
    required this.noonParentWaiting,
    required this.noonTeacherReleased,
  });

  factory AttendanceState.zero() => AttendanceState(
        morningParentDropped: 0,
        morningTeacherConfirm: 0,
        noonParentWaiting: 0,
        noonTeacherReleased: 0,
      );

  AttendanceState copyWith({
    int? morningParentDropped,
    int? morningTeacherConfirm,
    int? noonParentWaiting,
    int? noonTeacherReleased,
  }) {
    return AttendanceState(
      morningParentDropped: morningParentDropped ?? this.morningParentDropped,
      morningTeacherConfirm:
          morningTeacherConfirm ?? this.morningTeacherConfirm,
      noonParentWaiting: noonParentWaiting ?? this.noonParentWaiting,
      noonTeacherReleased: noonTeacherReleased ?? this.noonTeacherReleased,
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String caption;
  final Color color;
  final IconData icon;
  final Widget child;

  const _ActionCard({
    required this.title,
    required this.caption,
    required this.color,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const _PrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.background = const Color(0xFF507C5C),
    this.foreground = Colors.white,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
