import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://10.0.2.2/wethaq';
const kGreen = Color(0xFF507C5C);

class AttendanceLogScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const AttendanceLogScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<AttendanceLogScreen> createState() => _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends State<AttendanceLogScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
          '$baseUrl/list_attendance_logs.php?child_id=${widget.childId}');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j is Map && j['status'] == 'success') {
          _items = ((j['items'] as List?) ?? const [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else {
          _items = [];
        }
      } else {
        _items = [];
      }
    } catch (_) {
      _items = [];
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  String _eventLabel(String e) {
    switch (e) {
      case 'parent_dropped':
        return 'Parent dropped (Morning)';
      case 'staff_checked_in':
        return 'Teacher confirmed (Morning)';
      case 'parent_waiting':
        return 'Parent waiting (Afternoon)';
      case 'staff_checked_out':
        return 'Teacher released (Afternoon)';
      default:
        return e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance log • ${widget.childName}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
            if (!_loading && _items.isEmpty)
              const Center(child: Text('No entries yet')),
            ..._items.map((it) {
              final event = _eventLabel('${it['event']}');
              final actor =
                  (it['actor_name'] ?? it['actor_role'] ?? '').toString();
              final ts = (it['created_at'] ?? '').toString();
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.history, color: kGreen),
                  title: Text(event),
                  subtitle: Text('$actor\n$ts'),
                  isThreeLine: true,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
