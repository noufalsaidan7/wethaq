import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'child_attendance_screen.dart';
import 'chat_screen.dart';

//  إضافات الواجهات المساعدة
import 'widgets/validators.dart';
import 'widgets/nice_dialogs.dart';
import 'widgets/password_checklist.dart';

// const String baseUrl = 'http://192.168.1.28:8080/wethaq';
const String baseUrl = 'http://10.0.2.2/wethaq';

class ParentDashboard extends StatefulWidget {
  final int parentUserId;
  final String parentName;
  final String parentEmail;

  const ParentDashboard({
    Key? key,
    required this.parentUserId,
    required this.parentName,
    required this.parentEmail,
  }) : super(key: key);

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  static const kGreen = Color(0xFF507C5C);
  static const kPanel = Color(0xFFE6F0EA);

  int _tab = 0;

  bool _loadingChildren = false;
  List<Map<String, dynamic>> _children = [];

  bool _loadingAssigned = false;
  int? _assignedStaffUserId;
  String _assignedStaffName = '';

  bool _loadingAnns = false;
  List<Map<String, dynamic>> _anns = [];

  final TextEditingController _newPass = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchChildren();
    _fetchAnnouncements();
    _fetchAssignedStaffForThisParent();
  }

  Future<void> _fetchChildren() async {
    setState(() => _loadingChildren = true);
    try {
      final uri = Uri.parse(
          '$baseUrl/list_children.php?parent_user_id=${widget.parentUserId}');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['status'] == 'success') {
          final items = (data['items'] as List?) ?? const [];
          _children = items.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loadingChildren = false);
  }

  Future<void> _fetchAssignedStaffForThisParent() async {
    setState(() => _loadingAssigned = true);
    try {
      final uri = Uri.parse('$baseUrl/list_parents.php');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['status'] == 'success') {
          final items = (data['items'] as List?) ?? const [];
          for (final raw in items) {
            final m = Map<String, dynamic>.from(raw);
            final pid = int.tryParse('${m['id']}') ?? -1;
            if (pid == widget.parentUserId) {
              _assignedStaffUserId =
                  int.tryParse('${m['staff_user_id'] ?? '0'}') ?? 0;
              _assignedStaffName = (m['staff_name'] ?? '').toString();
              break;
            }
          }
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loadingAssigned = false);
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _loadingAnns = true);
    try {
      final uri = Uri.parse(
          '$baseUrl/list_announcements.php?parent_user_id=${widget.parentUserId}');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['status'] == 'success') {
          final items = (data['items'] as List?) ?? const [];
          _anns = items.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          _anns = [];
        }
      } else {
        _anns = [];
      }
    } catch (_) {
      _anns = [];
    }
    if (!mounted) return;
    setState(() => _loadingAnns = false);
  }

  /// حوار تغيير كلمة المرور (Checklist + تعطيل زر الحفظ حتى تتحقق الشروط)
  Future<void> _changePasswordDialog() async {
    _newPass.clear();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setM) {
            final pass = _newPass.text.trim();
            final isStrong = isPasswordStrong(pass); // من validators.dart

            return AlertDialog(
              title: const Text('Change password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _newPass,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setM(() {}),
                    ),
                    const SizedBox(height: 12),
                    PasswordChecklist(password: pass), // UI  للشروط
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isStrong
                      ? () async {
                          //  API لتغيير كلمة المرور
                          final res = await http.post(
                            Uri.parse('$baseUrl/change_password.php'),
                            body: {
                              'user_id': '${widget.parentUserId}',
                              'new_password': pass,
                            },
                          );

                          Map<String, dynamic>? j;
                          try {
                            j = jsonDecode(res.body);
                          } catch (_) {}

                          if (res.statusCode == 200 &&
                              j != null &&
                              j['status'] == 'success') {
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            await showNiceSuccessDialog(
                              context,
                              title: 'Password updated',
                              message:
                                  'Your password has been changed successfully.',
                            );
                          } else {
                            final msg = j?['message']?.toString() ??
                                'Failed to change password. Please try again.';
                            await showNiceErrorDialog(
                              context,
                              title: 'Couldn\'t update',
                              message: msg,
                            );
                          }
                        }
                      : null, // يتعطل إذا الشروط ما اكتملت
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
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
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Log out'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok && mounted) Navigator.pop(context);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

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
          if (i == 0) {
            _fetchChildren();
            _fetchAssignedStaffForThisParent();
          }
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

  Widget _buildChildrenTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchChildren();
        await _fetchAssignedStaffForThisParent();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loadingChildren || _loadingAssigned)
            const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 8),
          if (_children.isEmpty && !_loadingChildren && !_loadingAssigned) ...[
            _empty('No children yet', 'Your children will appear here.'),
          ] else
            ..._children.map((c) {
              final childId = c['id'] ?? c['child_id'] ?? 0;
              final childName =
                  (c['child_name'] ?? c['name'] ?? '-').toString();
              final klass = (c['class'] ?? c['class_name'] ?? '-').toString();
              final staffId = _assignedStaffUserId ?? 0;
              final staffName = _assignedStaffName;

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
                    'Class: $klass',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Open chat',
                        icon: const Icon(Icons.chat_bubble_outline,
                            color: kGreen),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                role: 'Parent',
                                staffUserId: staffId,
                                parentUserId: widget.parentUserId,
                                childId: childId,
                                peerName:
                                    staffName.isEmpty ? 'Teacher' : staffName,
                                childName: childName,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Attendance',
                        icon: const Icon(Icons.calendar_month,
                            color: Colors.black87),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChildAttendanceScreen(
                                childId: childId,
                                childName: childName,
                                staffName:
                                    staffName.isEmpty ? 'Teacher' : staffName,
                                parentUserId: widget.parentUserId,
                                staffUserId: staffId,
                                isStaffView: false, // <<< Parent view
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChildAttendanceScreen(
                          childId: childId,
                          childName: childName,
                          staffName: staffName.isEmpty ? 'Teacher' : staffName,
                          parentUserId: widget.parentUserId,
                          staffUserId: staffId,
                          isStaffView: false, // <<< Parent view
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsTab() {
    return RefreshIndicator(
      onRefresh: _fetchAnnouncements,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loadingAnns) const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 8),
          if (_anns.isEmpty && !_loadingAnns)
            _empty('No announcements',
                'Announcements addressed to you appear here.'),
          ..._anns.map(
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
