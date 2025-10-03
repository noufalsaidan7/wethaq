import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// استخدمي نفس العنوان اللي عندك
//const String baseUrl = 'http://192.168.1.28/wethaq';
const String baseUrl = 'http://10.0.2.2/wethaq';

class ParentDashboard extends StatefulWidget {
  final int parentUserId;
  final String parentName;
  final String parentEmail;

  const ParentDashboard({
    super.key,
    required this.parentUserId,
    required this.parentName,
    required this.parentEmail,
  });

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  // نفس ألوان ستايلك الحالي
  static const kGreen = Color(0xFF507C5C);
  static const kPanel = Color(0xFFE6F0EA);

  int _tab = 0;

  // ===== Children =====
  bool _loadingChildren = false;
  List<Map<String, dynamic>> children = [];

  // ===== Announcements (قراءة فقط) =====
  bool _loadingAnns = false;
  List<Map<String, dynamic>> anns = [];

  // ===== تغيير كلمة المرور =====
  final TextEditingController _newPass = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchChildren();
    _fetchAnnouncements(); // يعرض العام/الموجّه للأب إن كان مدعوم في PHP
  }

  // ----------------- API -----------------

  Future<void> _fetchChildren() async {
    setState(() => _loadingChildren = true);
    try {
      // نجيب أطفال هذا الأب فقط
      final uri = Uri.parse(
        '$baseUrl/list_children.php?parent_user_id=${widget.parentUserId}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['status'] == 'success') {
          final items = (data['items'] as List?) ?? const [];
          setState(() => children = items.cast<Map<String, dynamic>>());
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingChildren = false);
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _loadingAnns = true);
    try {
      // الأفضل أن يكون لديك في الـ PHP فلترة حسب parent_user_id
      // إن لم تكن موجودة، سيجلب العامة على الأقل
      final uri = Uri.parse(
        '$baseUrl/list_announcements.php?parent_user_id=${widget.parentUserId}',
      );
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

  Future<void> _changePasswordDialog() async {
    _newPass.clear();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change password'),
        content: TextField(
          controller: _newPass,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final res = await http.post(
                Uri.parse('$baseUrl/change_password.php'),
                body: {
                  'user_id': '${widget.parentUserId}',
                  'new_password': _newPass.text.trim(),
                },
              );
              if (res.statusCode == 200) {
                final j = jsonDecode(res.body);
                if (j is Map && j['status'] == 'success') {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password changed')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        (j is Map ? j['message'] : 'Error').toString(),
                      ),
                    ),
                  );
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
            title: const Text('Log out'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Log out'),
              ),
            ],
          ),
        ) ??
        false;

    if (ok && mounted) Navigator.pop(context);
  }

  // ----------------- UI -----------------

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
            Text(
              'Wethaq',
              style: TextStyle(
                fontFamily: 'serif',
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: kGreen,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Parent',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: CircleAvatar(
              backgroundColor: kPanel,
              foregroundColor: kGreen,
              child: Text(_initials(widget.parentName)),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _buildChildrenTab(),
          _buildAnnouncementsTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        selectedItemColor: kGreen,
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          setState(() => _tab = i);
          if (i == 0) _fetchChildren();
          if (i == 1) _fetchAnnouncements();
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.child_care), label: 'Children'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // ===== Tab 0: Children =====
  Widget _buildChildrenTab() {
    return RefreshIndicator(
      onRefresh: _fetchChildren,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loadingChildren) const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 8),
          if (children.isEmpty && !_loadingChildren)
            _empty('No children yet', 'Your children will appear here.'),
          ...children.map(
            (c) => Card(
              color: kPanel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.school, color: kGreen),
                title: Text(c['child_name']?.toString() ?? '-'),
                subtitle: Text('Class: ${c['class']?.toString() ?? '-'}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Tab 1: Announcements (read-only) =====
  Widget _buildAnnouncementsTab() {
    return RefreshIndicator(
      onRefresh: _fetchAnnouncements,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loadingAnns) const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 8),
          if (anns.isEmpty && !_loadingAnns)
            _empty('No announcements',
                'Announcements addressed to you appear here.'),
          ...anns.map(
            (a) => Card(
              color: kPanel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.campaign, color: kGreen),
                title: Text(a['title']?.toString() ?? ''),
                subtitle: Text(
                  '${a['body']?.toString() ?? ''}\n${a['created_at']?.toString() ?? ''}',
                ),
                isThreeLine: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Tab 2: Profile =====
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: kPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.person, color: kGreen),
            title: Text(widget.parentName),
            subtitle: Text(widget.parentEmail),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: kGreen,
              ),
              onPressed: _changePasswordDialog,
              icon: const Icon(Icons.lock_reset),
              label: const Text('Change password'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: _confirmLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    );
  }

  // ===== Helpers =====
  Widget _empty(String t, String s) => Column(
        children: [
          const SizedBox(height: 64),
          const Icon(Icons.inbox, color: Colors.grey, size: 48),
          const SizedBox(height: 8),
          Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            s,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      );

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
