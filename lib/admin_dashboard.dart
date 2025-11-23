// lib/admin_dashboard.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

//const String baseUrl = 'http://192.168.1.28:8080/wethaq';

const String baseUrl = 'http://10.0.2.2/wethaq';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  // form keys
  final GlobalKey<FormState> _parentFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _childFormKey = GlobalKey<FormState>();

  // colors
  static const Color kGreen = Color(0xFF507C5C);
  static const Color kPanelLight = Color(0xFFE6F0EA);
  static const Color kButtonBg = Color(0xFFE4EFE7);

  // tabs
  int _selectedIndex = 0;

  // admin info (ثابتة للواجهة فقط)
  String adminName = 'System Admin';
  String adminEmail = 'admin@wethaq.com';

  // lists
  List<Map<String, dynamic>> staffList = [];
  List<Map<String, dynamic>> parentList = [];
  List<Map<String, dynamic>> childList = [];

  bool _loadingStaff = false;
  bool _loadingParents = false;
  bool _loadingChildren = false;

  // endpoints
  String get listStaffApi => '$baseUrl/list_staff.php';
  String get listParentsApi => '$baseUrl/list_parents.php';
  String get listChildrenApi => '$baseUrl/list_children.php';

  String get staffAddApi => '$baseUrl/add_staff.php';
  String get parentAddApi => '$baseUrl/add_parent.php';
  String get parentUpdateApi => '$baseUrl/update_parent.php';
  String get childAddApi => '$baseUrl/add_child.php';

  String get staffDeleteApi => '$baseUrl/delete_staff.php';
  String get parentDeleteApi => '$baseUrl/delete_parent.php';
  String get childDeleteApi => '$baseUrl/delete_child.php';

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([fetchStaff(), fetchParents(), fetchChildren()]);
  }

  // ===== Fetchers =====
  Future<void> fetchStaff() async {
    setState(() => _loadingStaff = true);
    try {
      final res = await http
          .get(Uri.parse(listStaffApi))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['status'] == 'success') {
          final items = (data['items'] as List?) ?? [];
          staffList = items.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          staffList = [];
        }
      } else {
        staffList = [];
      }
    } catch (_) {
      staffList = [];
    }
    if (mounted) setState(() => _loadingStaff = false);
  }

  Future<void> fetchParents() async {
    setState(() => _loadingParents = true);
    try {
      final res = await http
          .get(Uri.parse(listParentsApi))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final data = jsonDecode(res.body);
      if (data is Map && data['status'] == 'success') {
        final items = (data['items'] as List?) ?? const [];
        setState(() {
          parentList =
              items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      } else {
        throw Exception(
            (data is Map ? data['message'] : null) ?? 'Unknown error');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parents fetch failed: $e')),
      );
      setState(() => parentList = []);
    } finally {
      if (mounted) setState(() => _loadingParents = false);
    }
  }

  Future<void> fetchChildren() async {
    setState(() => _loadingChildren = true);
    try {
      final res = await http
          .get(Uri.parse(listChildrenApi))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
      final data = jsonDecode(res.body);
      if (data is Map && data['status'] == 'success') {
        final list = (data['children'] ?? data['items'] ?? []) as List;
        childList = List<Map<String, dynamic>>.from(
          list.map((e) => Map<String, dynamic>.from(e as Map)),
        );
      } else {
        throw Exception(
            (data is Map ? data['message'] : null) ?? 'Unknown error');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Children fetch failed: $e')),
      );
      childList = [];
    } finally {
      if (mounted) setState(() => _loadingChildren = false);
    }
  }

  Future<Map<String, dynamic>> _postJson(
      String url, Map<String, String> body) async {
    final res = await http
        .post(Uri.parse(url), body: body)
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid JSON: ${res.body}');
    }
    return decoded;
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
        title: const Row(
          children: [
            SizedBox(width: 12),
            Text('Wethaq',
                style: TextStyle(
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: kGreen)),
            SizedBox(width: 8),
            Text('Admin',
                style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: _Avatar(initials: _initials(adminName)),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildOverviewTab(),
          _buildStaffTab(),
          _buildParentsTab(),
          _buildChildrenTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: kGreen,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Staff'),
          BottomNavigationBarItem(
              icon: Icon(Icons.family_restroom), label: 'Parents'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Children'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final staffCount = staffList.length;
    final parentCount = parentList.length;
    final childrenCount = childList.length;

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _GlassCard(
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: _Avatar(initials: _initials(adminName), big: true),
                title: Text(
                  adminName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black87),
                ),
                subtitle: Text(
                  adminEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
                trailing: ElevatedButton.icon(
                  onPressed: _openEditProfileSheet,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonBg,
                    foregroundColor: kGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _statCard(
              icon: Icons.badge,
              title: 'Staff',
              count: staffCount,
              loading: _loadingStaff,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            const SizedBox(height: 8),
            _statCard(
              icon: Icons.family_restroom,
              title: 'Parents',
              count: parentCount,
              loading: _loadingParents,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            const SizedBox(height: 8),
            _statCard(
              icon: Icons.school,
              title: 'Children',
              count: childrenCount,
              loading: _loadingChildren,
              onTap: () => setState(() => _selectedIndex = 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required int count,
    required bool loading,
    VoidCallback? onTap,
  }) {
    return _GlassCard(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: kGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: loading
            ? const SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator())
            : Text('$count',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
    );
  }

  // ===== Staff Tab =====
  Widget _buildStaffTab() {
    return RefreshIndicator(
      onRefresh: fetchStaff,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _openAddStaffSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add Staff'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kButtonBg,
                foregroundColor: kGreen,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loadingStaff
                  ? const Center(child: CircularProgressIndicator())
                  : staffList.isEmpty
                      ? const _EmptyState(
                          icon: Icons.badge,
                          title: 'No staff yet',
                          subtitle:
                              'Tap “Add Staff” to create the first member.',
                        )
                      : ListView.separated(
                          itemCount: staffList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (c, i) {
                            final s = staffList[i];
                            final name = '${s['name'] ?? '-'}';
                            final email = '${s['email'] ?? '-'}';
                            final phone = '${s['phone'] ?? '-'}';
                            return _GlassCard(
                              child: ListTile(
                                leading: _Avatar(initials: _initials(name)),
                                title: Text(name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  'Email: $email\nPhone: $phone',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                isThreeLine: true,
                                trailing: Wrap(
                                  spacing: 6,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit,
                                          color: Colors.black87),
                                      onPressed: () => _openEditStaffSheet(s),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () => _deleteStaff(s),
                                    ),
                                  ],
                                ),
                                onTap: () => _openEditStaffSheet(s),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Parents Tab =====
  Widget _buildParentsTab() {
    return RefreshIndicator(
      onRefresh: fetchParents,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _openAddParentSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add Parent'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kButtonBg,
                foregroundColor: kGreen,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loadingParents
                  ? const Center(child: CircularProgressIndicator())
                  : parentList.isEmpty
                      ? const _EmptyState(
                          icon: Icons.family_restroom,
                          title: 'No parents yet',
                          subtitle:
                              'Tap “Add Parent” to create the first parent.',
                        )
                      : ListView.separated(
                          itemCount: parentList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (c, i) {
                            final p = parentList[i];
                            final name = '${p['name'] ?? '-'}';
                            final email = '${p['email'] ?? '-'}';
                            final phone = '${p['phone'] ?? '-'}';

                            // عدد أطفال هذا الأب من childList
                            final childCount = childList
                                .where((cc) =>
                                    '${cc['parent_user_id']}' == '${p['id']}')
                                .length;

                            return _GlassCard(
                              child: ListTile(
                                leading: _Avatar(initials: _initials(name)),
                                title: Text(name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  'Email: $email\nPhone: $phone\nChildren: $childCount',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                isThreeLine: true,
                                trailing: Wrap(
                                  spacing: 6,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit,
                                          color: Colors.black87),
                                      onPressed: () => _openEditParentSheet(p),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () => _deleteParent(p),
                                    ),
                                  ],
                                ),
                                onTap: () => _openEditParentSheet(p),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Children Tab =====
  Widget _buildChildrenTab() {
    return RefreshIndicator(
      onRefresh: fetchChildren,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // زر الإضافة
            ElevatedButton.icon(
              onPressed: _openAddChildSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add Child'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kButtonBg,
                foregroundColor: kGreen,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loadingChildren
                  ? const Center(child: CircularProgressIndicator())
                  : childList.isEmpty
                      ? const _EmptyState(
                          icon: Icons.school,
                          title: 'No children yet',
                          subtitle:
                              'Tap “Add Child” to create the first child (must be linked to a parent).',
                        )
                      : ListView.separated(
                          itemCount: childList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final c = childList[i];
                            final name =
                                '${c['child_name'] ?? c['name'] ?? '-'}';
                            final klass =
                                '${c['class'] ?? c['class_name'] ?? '-'}';
                            final pId =
                                '${c['parent_user_id'] ?? c['parent_id'] ?? ''}';
                            final parentName = parentList
                                    .firstWhere(
                                      (p) => '${p['id']}' == pId,
                                      orElse: () => const {},
                                    )['name']
                                    ?.toString() ??
                                '-';

                            return _GlassCard(
                              child: ListTile(
                                leading: const Icon(Icons.emoji_people,
                                    color: kGreen),
                                title: Text(name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  'Class: $klass\nParent: $parentName',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Wrap(
                                  spacing: 6,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit,
                                          color: Colors.black87),
                                      onPressed: () => _openEditChildSheet(c),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () => _deleteChild(c),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Profile Sheet =====
  void _openEditProfileSheet() {
    final nameCtrl = TextEditingController(text: adminName);
    final emailCtrl = TextEditingController(text: adminEmail);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        final safeBottom = MediaQuery.of(ctx).padding.bottom;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: viewInsets + safeBottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SheetTitle('Edit Profile'),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (nameCtrl.text.trim().isNotEmpty) {
                            adminName = nameCtrl.text.trim();
                          }
                          if (emailCtrl.text.trim().isNotEmpty) {
                            adminEmail = emailCtrl.text.trim();
                          }
                        });
                        Navigator.pop(ctx);
                        _snack('Profile updated');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== Staff add/edit/delete =====
  void _openAddStaffSheet() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final empCtrl = TextEditingController();
    String password = _generatePassword();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        final safeBottom = MediaQuery.of(ctx).padding.bottom;
        return StatefulBuilder(
          builder: (ctx, setM) => SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 20,
                  bottom: viewInsets + safeBottom + 16),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _SheetHeader(title: 'Add Staff'),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Phone Number'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: empCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Employee Number (4 digits)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null ||
                                v.trim().isEmpty ||
                                v.trim().length < 4)
                            ? 'Required 4 digits'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      ActionChip(
                        avatar: const Icon(Icons.key, size: 18),
                        label: Text('Password: $password',
                            overflow: TextOverflow.ellipsis),
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: password));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password copied')),
                          );
                        },
                        backgroundColor: kButtonBg,
                        labelStyle: const TextStyle(
                            color: kGreen, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            Navigator.pop(ctx);
                            try {
                              final result = await _postJson(staffAddApi, {
                                'name': nameCtrl.text.trim(),
                                'email': emailCtrl.text.trim(),
                                'password': password,
                                'phone': phoneCtrl.text.trim(),
                                'employee_number': empCtrl.text.trim(),
                              });
                              if (result['status'] == 'success') {
                                _snack('Staff added');
                                await fetchStaff();
                              } else {
                                _snack('Server said: ${result['message']}');
                              }
                            } catch (e) {
                              _snack('Server error: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Add Staff'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openEditStaffSheet(Map<String, dynamic> staff) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: '${staff['name'] ?? ''}');
    final emailCtrl = TextEditingController(text: '${staff['email'] ?? ''}');
    final phoneCtrl = TextEditingController(text: '${staff['phone'] ?? ''}');
    final empCtrl =
        TextEditingController(text: '${staff['employee_number'] ?? ''}');
    final passCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        final safeBottom = MediaQuery.of(ctx).padding.bottom;

        return StatefulBuilder(
          builder: (ctx, setM) => SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: viewInsets + safeBottom + 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _SheetHeader(title: 'Edit Staff'),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Phone Number'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: empCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Employee Number'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passCtrl,
                        decoration: const InputDecoration(
                          labelText: 'New Password (optional)',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            Navigator.pop(ctx);
                            try {
                              final payload = <String, String>{
                                'user_id':
                                    '${staff['id'] ?? staff['user_id'] ?? ''}',
                                'name': nameCtrl.text.trim(),
                                'email': emailCtrl.text.trim(),
                                'phone': phoneCtrl.text.trim(),
                                'employee_number': empCtrl.text.trim(),
                              };
                              if (passCtrl.text.trim().isNotEmpty) {
                                payload['password'] = passCtrl.text.trim();
                              }

                              final result = await _postJson(
                                '$baseUrl/update_staff.php',
                                payload,
                              );

                              if (result['status'] == 'success') {
                                _snack('Staff updated');
                                await fetchStaff();
                              } else {
                                _snack('Server said: ${result['message']}');
                              }
                            } catch (e) {
                              _snack('Server error: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteStaff(Map<String, dynamic> staff) async {
    final ok = await _confirmDelete('Delete Staff',
        'Are you sure you want to delete ${staff['name'] ?? 'this staff'}?');
    if (!ok) return;
    try {
      final res = await http.post(Uri.parse(staffDeleteApi), body: {
        'user_id': '${staff['id'] ?? staff['user_id'] ?? ''}'
      }).timeout(const Duration(seconds: 20));
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        _snack('Staff deleted');
        await fetchStaff();
      } else {
        _snack('Server said: ${data['message']}');
      }
    } catch (e) {
      _snack('Server error: $e');
    }
  }

  // ===== Parent add/edit/delete =====
  void _openAddParentSheet() async {
    // نتأكد أنّ قائمة المعلّمين محمّلة لاختيار المعلّم
    if (staffList.isEmpty) {
      setState(() => _loadingStaff = true);
      await fetchStaff();
      if (mounted) setState(() => _loadingStaff = false);
    }
    if (staffList.isEmpty) {
      _snack('Please add a staff first');
      return;
    }

    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    String password = _generatePassword();
    String? selectedStaffId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        final safeBottom = MediaQuery.of(ctx).padding.bottom;
        return StatefulBuilder(
          builder: (ctx, setM) => SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 20,
                  bottom: viewInsets + safeBottom + 16),
              child: SingleChildScrollView(
                child: Form(
                  key: _parentFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _SheetHeader(title: 'Add Parent'),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Phone Number'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: idCtrl,
                        decoration: const InputDecoration(
                            labelText: 'ID Number (min 5 digits)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null ||
                                v.trim().isEmpty ||
                                v.trim().length < 5)
                            ? 'Required (min 5 digits)'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedStaffId,
                        isExpanded: true,
                        items: staffList.map<DropdownMenuItem<String>>((s) {
                          final display = '${s['name'] ?? s['email'] ?? ''}';
                          return DropdownMenuItem(
                            value: '${s['id']}',
                            child:
                                Text(display, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (v) => setM(() => selectedStaffId = v),
                        decoration: const InputDecoration(
                            labelText: 'Assign Staff (required)'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please select a staff'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      ActionChip(
                        avatar: const Icon(Icons.key, size: 18),
                        label: Text('Password: $password',
                            overflow: TextOverflow.ellipsis),
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: password));
                          _snack('Password copied');
                        },
                        backgroundColor: kButtonBg,
                        labelStyle: const TextStyle(
                            color: kGreen, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!(_parentFormKey.currentState?.validate() ??
                                false)) {
                              return;
                            }
                            Navigator.pop(ctx);
                            try {
                              final result = await _postJson(parentAddApi, {
                                'name': nameCtrl.text.trim(),
                                'email': emailCtrl.text.trim(),
                                'password': password,
                                'phone': phoneCtrl.text.trim(),
                                'identity_number': idCtrl.text.trim(),
                                'assigned_staff_user_id': selectedStaffId ?? '',
                              });
                              if (result['status'] == 'success') {
                                _snack('Parent added');
                                await Future.wait(
                                    [fetchParents(), fetchChildren()]);
                              } else {
                                _snack('Server said: ${result['message']}');
                              }
                            } catch (e) {
                              _snack('Server error: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Add Parent'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openEditParentSheet(Map<String, dynamic> parent) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: '${parent['name'] ?? ''}');
    final emailCtrl = TextEditingController(text: '${parent['email'] ?? ''}');
    final phoneCtrl = TextEditingController(text: '${parent['phone'] ?? ''}');
    final idCtrl =
        TextEditingController(text: '${parent['identity_number'] ?? ''}');
    final passCtrl = TextEditingController();

    String? selectedStaffId =
        (parent['staff_user_id'] ?? parent['assigned_staff_user_id'])
            ?.toString();
    if (selectedStaffId != null &&
        !staffList.any((s) => '${s['id']}' == selectedStaffId)) {
      selectedStaffId = null;
    }
    if (staffList.isEmpty) {
      _snack('No staff available. Fetching...');
      fetchStaff();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        final safeBottom = MediaQuery.of(ctx).padding.bottom;
        return StatefulBuilder(
          builder: (ctx, setM) => SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 20,
                  bottom: viewInsets + safeBottom + 16),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _SheetHeader(title: 'Edit Parent'),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Phone Number'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: idCtrl,
                        decoration:
                            const InputDecoration(labelText: 'ID Number'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedStaffId,
                        isExpanded: true,
                        items: staffList
                            .map((s) => DropdownMenuItem(
                                  value: '${s['id']}',
                                  child: Text(
                                    '${s['name'] ?? s['email'] ?? ''}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setM(() => selectedStaffId = v),
                        decoration: const InputDecoration(
                            labelText: 'Assign Staff (required)'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please select a staff'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passCtrl,
                        decoration: const InputDecoration(
                            labelText: 'New Password (optional)'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            Navigator.pop(ctx);
                            try {
                              final payload = <String, String>{
                                'user_id':
                                    '${parent['id'] ?? parent['user_id'] ?? ''}',
                                'name': nameCtrl.text.trim(),
                                'new_email': emailCtrl.text.trim(),
                                'phone': phoneCtrl.text.trim(),
                                'identity_number': idCtrl.text.trim(),
                                'assigned_staff_user_id': selectedStaffId ?? '',
                              };
                              if (passCtrl.text.trim().isNotEmpty) {
                                payload['password'] = passCtrl.text.trim();
                              }
                              final result =
                                  await _postJson(parentUpdateApi, payload);
                              if (result['status'] == 'success') {
                                _snack('Parent updated');
                                await Future.wait(
                                    [fetchParents(), fetchChildren()]);
                              } else {
                                _snack('Server said: ${result['message']}');
                              }
                            } catch (e) {
                              _snack('Server error: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteParent(Map<String, dynamic> parent) async {
    final ok = await _confirmDelete('Delete Parent',
        'Are you sure you want to delete ${parent['name'] ?? 'this parent'}?');
    if (!ok) return;
    try {
      final res = await http.post(Uri.parse(parentDeleteApi), body: {
        'user_id': '${parent['id'] ?? parent['user_id'] ?? ''}'
      }).timeout(const Duration(seconds: 20));
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        _snack('Parent deleted');
        await Future.wait([fetchParents(), fetchChildren()]);
      } else {
        _snack('Server said: ${data['message']}');
      }
    } catch (e) {
      _snack('Server error: $e');
    }
  }

  // ===== Children add/edit/delete =====
  void _openAddChildSheet() {
    if (parentList.isEmpty) {
      _snack('Add a parent first.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    String? selectedParentId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom + 16;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, bottom),
          child: StatefulBuilder(
            builder: (ctx, setM) => Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SheetTitle('Add Child'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedParentId,
                    items: parentList.map((p) {
                      return DropdownMenuItem(
                        value: '${p['id']}',
                        child: Text('${p['name'] ?? '-'}',
                            overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) => setM(() => selectedParentId = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Select a parent' : null,
                    decoration:
                        const InputDecoration(labelText: 'Parent (required)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Child Name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: classCtrl,
                    decoration: const InputDecoration(labelText: 'Class'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          final res = await _postJson(childAddApi, {
                            'parent_id': selectedParentId!,
                            'name': nameCtrl.text.trim(),
                            'class': classCtrl.text.trim(),
                          });
                          if (res['status'] == 'success') {
                            _snack('Child added');
                            await fetchChildren();
                          } else {
                            _snack('Server said: ${res['message']}');
                          }
                        } catch (e) {
                          _snack('Server error: $e');
                        }
                      },
                      child: const Text('Add Child'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openEditChildSheet(Map<String, dynamic> child) async {
    if (parentList.isEmpty) {
      await fetchParents();
    }

    final formKey = GlobalKey<FormState>();
    final nameCtrl =
        TextEditingController(text: (child['child_name'] ?? '').toString());
    final classCtrl =
        TextEditingController(text: (child['class'] ?? '').toString());
    String? selectedParentId =
        (child['parent_user_id'] ?? '').toString().isEmpty
            ? null
            : (child['parent_user_id']).toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final inset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, inset + 16),
          child: StatefulBuilder(
            builder: (ctx, setM) => Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SheetTitle('Edit Child'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedParentId,
                    isExpanded: true,
                    items: parentList.map((p) {
                      return DropdownMenuItem(
                        value: '${p['id']}',
                        child: Text('${p['name'] ?? '-'}',
                            overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) => setM(() => selectedParentId = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Select a parent' : null,
                    decoration: const InputDecoration(labelText: 'Parent'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Child Name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: classCtrl,
                    decoration: const InputDecoration(labelText: 'Class'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          final data = await _postJson(
                            '$baseUrl/update_child.php',
                            {
                              'child_id': '${child['id']}',
                              'parent_id': selectedParentId!,
                              'name': nameCtrl.text.trim(),
                              'class': classCtrl.text.trim(),
                            },
                          );
                          if (data['status'] == 'success') {
                            _snack('Child updated');
                            await fetchChildren();
                          } else {
                            _snack('Server: ${data['message']}');
                          }
                        } catch (e) {
                          _snack('Server error: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteChild(Map<String, dynamic> child) async {
    final ok = await _confirmDelete('Delete Child',
        'Are you sure you want to delete ${child['child_name'] ?? child['name'] ?? 'this child'}?');
    if (!ok) return;

    try {
      final res = await _postJson(childDeleteApi, {
        'child_id': '${child['id']}',
      });
      if (res['status'] == 'success') {
        _snack('Child deleted');
        await fetchChildren();
      } else {
        _snack('Server said: ${res['message']}');
      }
    } catch (e) {
      _snack('Server error: $e');
    }
  }

  // ===== utils =====

  String _generatePassword([int length = 10]) {
    // لازم يكون الطول كافي للأجزاء المطلوبة
    if (length < 8) length = 8;

    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const digits = '0123456789';
    const symbols = r'!@#$%^&*()_-+=<>?{}~';

    final rnd = Random.secure();
    final buf = <String>[];

    // 4 أحرف على الأقل (نمزج كبار/صغار)
    for (int i = 0; i < 2; i++) {
      buf.add(upper[rnd.nextInt(upper.length)]);
      buf.add(lower[rnd.nextInt(lower.length)]);
    }

    // 3 أرقام
    for (int i = 0; i < 3; i++) {
      buf.add(digits[rnd.nextInt(digits.length)]);
    }

    // 1 رمز على الأقل
    buf.add(symbols[rnd.nextInt(symbols.length)]);

    // لو الطول المطلوب أكبر، نكمل من كل المجموعات
    final all = upper + lower + digits + symbols;
    while (buf.length < length) {
      buf.add(all[rnd.nextInt(all.length)]);
    }

    // نخلط الترتيب عشان ما يكون متوقع
    _shuffle(buf, rnd);

    return buf.join();
  }

  void _shuffle(List<String> list, Random rnd) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = rnd.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= 2 ? 2 : p.length).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<bool> _confirmDelete(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen, foregroundColor: Colors.white),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
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
                    backgroundColor: kGreen, foregroundColor: Colors.white),
                child: const Text('Log out'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok && mounted) Navigator.pop(context);
  }
}

// ===== small widgets =====
class _Avatar extends StatelessWidget {
  final String initials;
  final bool big;
  const _Avatar({required this.initials, this.big = false});
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: big ? 24 : 18,
      backgroundColor: _AdminDashboardState.kPanelLight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          initials,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            color: _AdminDashboardState.kGreen,
            fontWeight: FontWeight.w700,
            fontSize: big ? 16 : 12,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _AdminDashboardState.kPanelLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 42, color: _AdminDashboardState.kGreen),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ]),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final String text;
  const _SheetTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18));
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SheetHeader({required this.title, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SheetTitle(title)),
        if (trailing != null) trailing!,
      ],
    );
  }
}
