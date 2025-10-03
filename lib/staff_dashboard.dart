// lib/staff_dashboard.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// عدّلي العنوان حسب بيئتك
//const String baseUrl = 'http://192.168.1.28/wethaq'
const String baseUrl = 'http://10.0.2.2/wethaq';

class StaffDashboard extends StatefulWidget {
  final int staffUserId;
  final String staffName;
  final String staffEmail;

  const StaffDashboard({
    super.key,
    required this.staffUserId,
    required this.staffName,
    required this.staffEmail,
  });

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  // ألوان ثابتة
  static const kGreen = Color(0xFF507C5C);
  static const kPanel = Color(0xFFE6F0EA);
  static const kButtonBg = Color(0xFFE4EFE7);

  int _tab = 0;

  // إجبار تغيير كلمة المرور (اختياري)
  bool mustChangePassword = false;
  final TextEditingController _newPass = TextEditingController();

  // Students
  bool _loadingStudents = false;
  List<Map<String, dynamic>> students = [];

  // Announcements
  bool _loadingAnns = false;
  List<Map<String, dynamic>> anns = [];

  // Parents (للشات/الإرسال الفردي)
  bool _loadingParents = false;
  List<Map<String, dynamic>> parents = [];

  @override
  void initState() {
    super.initState();
    _checkMustChange();
    _fetchStudents();
    _fetchAnnouncements();
  }

  // ===== Helpers =====
  Future<Map<String, dynamic>?> _getJson(Uri uri) async {
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final decoded = jsonDecode(res.body);
    return (decoded is Map<String, dynamic>) ? decoded : null;
  }

  Future<Map<String, dynamic>?> _postJson(
      Uri uri, Map<String, String> body) async {
    final res =
        await http.post(uri, body: body).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) return null;
    final decoded = jsonDecode(res.body);
    return (decoded is Map<String, dynamic>) ? decoded : null;
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ===== Must-change password (اختياري) =====
  Future<void> _checkMustChange() async {
    try {
      final uri =
          Uri.parse('$baseUrl/get_user_detail.php?id=${widget.staffUserId}');
      final data = await _getJson(uri);
      if (data != null && data['status'] == 'success') {
        setState(() =>
            mustChangePassword = (data['user']?['must_change_password'] == 1));
        if (mustChangePassword) _openChangePasswordDialog(force: true);
      }
    } catch (_) {}
  }

  // ===== Students =====
  Future<void> _fetchStudents() async {
    setState(() => _loadingStudents = true);
    List<Map<String, dynamic>> list = [];
    try {
      final uri = Uri.parse(
          '$baseUrl/list_assigned_students.php?staff_user_id=${widget.staffUserId}');
      final data = await _getJson(uri);
      if (data != null && data['status'] == 'success') {
        final items = (data['items'] as List?) ?? const [];
        list = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      // لو ما رجّع parent_name نجيب جدول أولياء الأمور ونلحقه
      final hasParentName =
          list.any((e) => (e['parent_name'] ?? '').toString().isNotEmpty);
      if (!hasParentName) {
        await _loadParentsForSend();
        // parents: [{parent_user_id, name, email}]
        final byId = <String, Map<String, dynamic>>{
          for (final p in parents) '${p['parent_user_id']}': p
        };
        for (final s in list) {
          final pid = '${s['parent_user_id'] ?? ''}';
          s['parent_name'] = byId[pid]?['name'] ?? byId[pid]?['email'] ?? '';
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      students = list;
      _loadingStudents = false;
    });
  }

  // ===== Announcements =====
  Future<void> _fetchAnnouncements() async {
    setState(() => _loadingAnns = true);
    try {
      final uri = Uri.parse(
          '$baseUrl/list_announcements.php?staff_user_id=${widget.staffUserId}');
      final data = await _getJson(uri);
      if (mounted) {
        if (data != null && data['status'] == 'success') {
          final items = (data['items'] as List?) ?? const [];
          anns = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else {
          anns = [];
        }
        _loadingAnns = false;
      }
    } catch (_) {
      if (mounted) {
        _loadingAnns = false;
        anns = [];
      }
    }
    if (mounted) setState(() {});
  }

  // Parents
  Future<void> _loadParentsForSend() async {
    setState(() => _loadingParents = true);
    try {
      final uri = Uri.parse(
          '$baseUrl/list_parents_for_staff.php?staff_user_id=${widget.staffUserId}');
      final data = await _getJson(uri);
      if (mounted) {
        if (data != null && data['status'] == 'success') {
          final items = (data['items'] as List?) ?? const [];
          parents =
              items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else {
          parents = [];
        }
        _loadingParents = false;
      }
    } catch (_) {
      if (mounted) {
        parents = [];
        _loadingParents = false;
      }
    }
    if (mounted) setState(() {});
  }

  // إرسال إعلان عام/أو لولي محدد
  Future<void> _sendAnnouncement() async {
    await _loadParentsForSend();
    String? parentId; // null = الكل
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: parentId,
              items: [
                const DropdownMenuItem(value: null, child: Text('All parents')),
                ...parents.map((p) => DropdownMenuItem(
                      value: '${p['parent_user_id']}',
                      child: Text('${p['name'] ?? p['email']}'),
                    )),
              ],
              onChanged: (v) => parentId = v,
              decoration: const InputDecoration(labelText: 'Send to'),
            ),
            const SizedBox(height: 8),
            TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(labelText: 'Message')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kGreen, foregroundColor: Colors.white),
            onPressed: () async {
              final j = await _postJson(
                Uri.parse('$baseUrl/send_announcement.php'),
                {
                  'staff_user_id': '${widget.staffUserId}',
                  'parent_user_id': parentId ?? '',
                  'title': titleCtrl.text.trim(),
                  'body': bodyCtrl.text.trim(),
                },
              );
              if (j != null && j['status'] == 'success') {
                if (!mounted) return;
                Navigator.pop(context);
                _snack('Announcement sent');
                _fetchAnnouncements();
              } else {
                _snack('Failed to send');
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  // صفحة قائمة المحادثات (أولياء الأمور التابعين لهذا المعلّم)
  Future<void> _openChats() async {
    await _loadParentsForSend();
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _ChatsPage(
        parents: parents,
        staffName: widget.staffName,
      ),
    ));
  }

  Future<void> _openChangePasswordDialog({bool force = false}) async {
    _newPass.clear();
    await showDialog(
      barrierDismissible: !force,
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change password'),
        content: TextField(
          controller: _newPass,
          decoration: const InputDecoration(labelText: 'New password'),
          obscureText: true,
        ),
        actions: [
          if (!force)
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kGreen, foregroundColor: Colors.white),
            onPressed: () async {
              final j = await _postJson(
                Uri.parse('$baseUrl/change_password.php'),
                {
                  'user_id': '${widget.staffUserId}',
                  'new_password': _newPass.text.trim()
                },
              );
              if (j != null && j['status'] == 'success') {
                if (!mounted) return;
                Navigator.pop(context);
                setState(() => mustChangePassword = false);
                _snack('Password changed');
              } else {
                _snack('Failed to change password');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Log out'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Log out'),
              ),
            ],
          ),
        ) ??
        false;

    if (ok && mounted) Navigator.pop(context);
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        title: Row(
          children: const [
            SizedBox(width: 12),
            Text('Wethaq',
                style: TextStyle(
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: kGreen)),
            SizedBox(width: 8),
            Text('Staff',
                style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chats',
            onPressed: _openChats,
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: CircleAvatar(
              backgroundColor: kPanel,
              foregroundColor: kGreen,
              child: Text(_initials(widget.staffName)),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.logout, color: Colors.black87),
              onPressed: _confirmLogout),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _buildStudentsTab(),
          _buildMessagesTab(),
          _buildProfileTab(),
        ],
      ),
      floatingActionButton: _tab == 1
          ? FloatingActionButton(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              onPressed: _sendAnnouncement,
              child: const Icon(Icons.campaign),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        selectedItemColor: kGreen,
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          setState(() => _tab = i);
          if (i == 0) _fetchStudents();
          if (i == 1) _fetchAnnouncements();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Students'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    return RefreshIndicator(
      onRefresh: _fetchStudents,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loadingStudents) const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 8),
          if (students.isEmpty && !_loadingStudents)
            _empty('No students yet', 'Assigned children will appear here.'),
          ...students.map((c) {
            // نقرأ الحقول بأسماء مرنة حسب الـ API
            final childName = (c['child_name'] ?? c['name'] ?? '-').toString();
            final parentName = (c['parent_name'] ??
                    c['parent_fullname'] ??
                    c['parent'] ??
                    c['parent_email'] ??
                    '-')
                .toString();
            final klass = (c['class'] ?? c['class_name'] ?? '-').toString();

            return Card(
              color: kPanel,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.school, color: kGreen),
                title: Text(
                  childName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Parent: $parentName\nClass: $klass',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    return RefreshIndicator(
      onRefresh: _fetchAnnouncements,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loadingAnns) const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 8),
          if (anns.isEmpty && !_loadingAnns)
            _empty('No announcements', 'Tap the speaker button to send one.'),
          ...anns.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: kPanel, borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: const Icon(Icons.campaign, color: kGreen),
                  title: Text('${a['title'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle:
                      Text('${a['body'] ?? ''}\n${a['created_at'] ?? ''}'),
                  isThreeLine: true,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
              color: kPanel, borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: const Icon(Icons.person, color: kGreen),
            title: Text(widget.staffName,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(widget.staffEmail),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _openChangePasswordDialog,
            icon: const Icon(Icons.lock_reset),
            label: const Text('Change password'),
            style: ElevatedButton.styleFrom(
                backgroundColor: kButtonBg, foregroundColor: kGreen),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _empty(String t, String s) => Column(
        children: [
          const SizedBox(height: 64),
          const Icon(Icons.inbox, color: Colors.grey, size: 48),
          const SizedBox(height: 8),
          Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(s,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
        ],
      );
}

// ===== صفحة المحادثات (قائمة أولياء الأمور) =====
class _ChatsPage extends StatelessWidget {
  final List<Map<String, dynamic>> parents;
  final String staffName;

  const _ChatsPage({required this.parents, required this.staffName});

  static const kGreen = Color(0xFF507C5C);
  static const kPanel = Color(0xFFE6F0EA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats', style: TextStyle(color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black87),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: parents.length,
        itemBuilder: (_, i) {
          final p = parents[i];
          final display = '${p['name'] ?? p['email'] ?? ''}';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
                color: kPanel, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: const Icon(Icons.person_outline, color: kGreen),
              title: Text(display,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Parent • linked to $staffName'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // مكان التوسعة لاحقاً لفتح محادثة خاصة
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Open chat with $display')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
