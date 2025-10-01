import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// غيّري على حسب مكان تعريفك
const String baseUrl = 'http://192.168.1.28/wethaq';

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
  static const kGreen = Color(0xFF507C5C);
  static const kPanel = Color(0xFFE6F0EA);

  int _tab = 0;

  // إجبار تغيير كلمة المرور
  bool mustChangePassword = false;
  final TextEditingController _newPass = TextEditingController();

  // Students
  bool _loadingStudents = false;
  List<Map<String, dynamic>> students = [];

  // Announcements (رسائل عامة)
  bool _loadingAnns = false;
  List<Map<String, dynamic>> anns = [];

  // Parents list (للإرسال لولي محدد)
  List<Map<String, dynamic>> parents = [];
  bool _loadingParents = false;

  @override
  void initState() {
    super.initState();
    _checkMustChange();
    _fetchStudents();
    _fetchAnnouncements();
  }

  Future<void> _checkMustChange() async {
    // لو عندك API يرجّع تفاصيل المستخدم بعد اللوجين استخدمه؛
    // أو نزّل هذا الفلاغ من استجابة اللوجين. هنا مثال مبسّط:
    // اعتبرنا في users فيه must_change_password، نجيبها عبر endpoint موجود عندك.
    try {
      final uri =
          Uri.parse('$baseUrl/get_user_detail.php?id=${widget.staffUserId}');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['status'] == 'success') {
          setState(() =>
              mustChangePassword = (data['user']['must_change_password'] == 1));
          if (mustChangePassword) _openChangePasswordDialog(force: true);
        }
      }
    } catch (_) {}
  }

  // ===== Students =====
  Future<void> _fetchStudents() async {
    setState(() => _loadingStudents = true);
    try {
      final uri = Uri.parse(
          '$baseUrl/list_assigned_students.php?staff_user_id=${widget.staffUserId}');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['status'] == 'success') {
          final items = (data['items'] as List?) ?? const [];
          setState(() => students = items.cast<Map<String, dynamic>>());
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingStudents = false);
  }

  // ===== Announcements =====
  Future<void> _fetchAnnouncements() async {
    setState(() => _loadingAnns = true);
    try {
      final uri = Uri.parse(
          '$baseUrl/list_announcements.php?staff_user_id=${widget.staffUserId}');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['status'] == 'success') {
          final items = (data['items'] as List?) ?? const [];
          setState(() => anns = items.cast<Map<String, dynamic>>());
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingAnns = false);
  }

  Future<void> _loadParentsForSend() async {
    setState(() => _loadingParents = true);
    try {
      final uri = Uri.parse(
          '$baseUrl/list_parents_for_staff.php?staff_user_id=${widget.staffUserId}');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['status'] == 'success') {
          final items = (data['items'] as List?) ?? const [];
          setState(() => parents = items.cast<Map<String, dynamic>>());
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingParents = false);
  }

  Future<void> _sendAnnouncement() async {
    String? parentId; // null = الكل
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    await _loadParentsForSend();

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
            TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title')),
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
              final res = await http.post(
                Uri.parse('$baseUrl/send_announcement.php'),
                body: {
                  'staff_user_id': '${widget.staffUserId}',
                  'parent_user_id': parentId ?? '',
                  'title': titleCtrl.text.trim(),
                  'body': bodyCtrl.text.trim(),
                },
              );
              if (res.statusCode == 200) {
                final j = jsonDecode(res.body);
                if (j['status'] == 'success') {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Announcement sent')));
                    _fetchAnnouncements();
                  }
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
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
              final res = await http
                  .post(Uri.parse('$baseUrl/change_password.php'), body: {
                'user_id': '${widget.staffUserId}',
                'new_password': _newPass.text.trim(),
              });
              if (res.statusCode == 200) {
                final j = jsonDecode(res.body);
                if (j['status'] == 'success') {
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() => mustChangePassword = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password changed')));
                  }
                }
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
            title: const Text('Confirm logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Log out'),
              ),
            ],
          ),
        ) ??
        false;

    if (ok && mounted) Navigator.pop(context);
  }

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
          children: [
            const SizedBox(width: 12),
            const Text('Wethaq',
                style: TextStyle(
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: kGreen)),
            const SizedBox(width: 8),
            const Text('Staff',
                style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
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

  // ===== Tabs UI =====
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
          ...students.map((c) => Card(
                color: kPanel,
                child: ListTile(
                  leading: const Icon(Icons.child_care, color: kGreen),
                  title: Text(c['child_name'] ?? '-'),
                  subtitle: Text(
                      (c['class'] ?? '-') + ' • ' + (c['parent_email'] ?? '')),
                  trailing: const Icon(Icons.chevron_right),
                ),
              )),
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
          ...anns.map((a) => Card(
                color: kPanel,
                child: ListTile(
                  leading: const Icon(Icons.campaign, color: kGreen),
                  title: Text(a['title'] ?? ''),
                  subtitle:
                      Text((a['body'] ?? '') + '\n${a['created_at'] ?? ''}'),
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
        Card(
          color: kPanel,
          child: ListTile(
            leading: const Icon(Icons.person, color: kGreen),
            title: Text(widget.staffName),
            subtitle: Text(widget.staffEmail),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: kGreen),
              onPressed: () => _openChangePasswordDialog(),
              icon: const Icon(Icons.lock_reset),
              label: const Text('Change password'),
            ),
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

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1)
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
