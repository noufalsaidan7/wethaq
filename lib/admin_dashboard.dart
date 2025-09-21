import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

const String baseUrl = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://192.168.1.13/wethaq',
);

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  // ألوان
  static const Color kGreen = Color(0xFF507C5C);
  static const Color kPanelLight = Color(0xFFE6F0EA);
  static const Color kButtonBg = Color(0xFFE4EFE7);

  // تبويبات
  int _selectedIndex = 0;

  // بروفايل الأدمن
  String adminName = 'System Admin';
  String adminEmail = 'admin@wethaq.com';

  // بيانات داخلية (تظهر فورًا ثم تتزامن مع الخادم)
  // ملاحظة: سنخزن user_id عندما يرجع من السيرفر ليدعم التعديل/الحذف.
  final Map<String, Map<String, dynamic>> staffData = {};
  final Map<String, Map<String, dynamic>> parentData = {};

  // نهايات الـ API
  static const String staffAddApi = '$baseUrl/add_staff.php';
  static const String parentAddApi = '$baseUrl/add_parent.php';
  static const String staffUpdateApi = '$baseUrl/update_staff.php';
  static const String parentUpdateApi = '$baseUrl/update_parent.php';
  static const String staffDeleteApi = '$baseUrl/delete_staff.php';
  static const String parentDeleteApi = '$baseUrl/delete_parent.php';
  static const String getUserApi = '$baseUrl/get_user_detail.php'; // GET ?email=...

  // ===== Helpers =====
  String _generatePassword([int length = 8]) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random.secure();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<Map<String, dynamic>> _postJson(String url, Map<String, String> body,
      {Duration timeout = const Duration(seconds: 20)}) async {
    debugPrint('POST $url BODY=$body');
    final res =
        await http.post(Uri.parse(url), body: body).timeout(timeout);
    debugPrint('RES ${res.statusCode} ${res.body}');
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid JSON: ${res.body}');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _getJson(String url,
      {Duration timeout = const Duration(seconds: 20)}) async {
    debugPrint('GET $url');
    final res = await http.get(Uri.parse(url)).timeout(timeout);
    debugPrint('RES ${res.statusCode} ${res.body}');
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

  Future<int?> _ensureUserIdByEmail(String email) async {
    try {
      final data =
          await _getJson('$getUserApi?email=${Uri.encodeComponent(email)}');
      if (data['status'] == 'success') {
        final user = data['user'] as Map<String, dynamic>?;
        return user?['id'] is int
            ? user!['id'] as int
            : int.tryParse('${user?['id']}');
      }
    } catch (e) {
      debugPrint('ensureUserId error: $e');
    }
    return null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildOverviewTab(),
          _buildStaffTab(),
          _buildParentsTab(),
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
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      titleSpacing: 0,
      title: const Row(
        children: [
          SizedBox(width: 12),
          Text(
            'Wethaq',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'serif',
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: kGreen,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Admin',
            style: TextStyle(
                color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
          ),
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
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // ============ TAB 1: OVERVIEW ============
  Widget _buildOverviewTab() {
    final staffCount = staffData.length;
    final parentCount = parentData.length;
    final childrenCount = parentData.values.fold<int>(
      0,
      (sum, p) =>
          sum +
          (((p['children'] as List<Map<String, String>>?)?.length) ?? 0),
    );

    return SingleChildScrollView(
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
                    backgroundColor: kButtonBg, foregroundColor: kGreen),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const _GlassCard(
            child: ListTile(
              leading: Icon(Icons.badge, color: kGreen),
              title: Text('Staff', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -56),
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('$staffCount',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          const _GlassCard(
            child: ListTile(
              leading: Icon(Icons.family_restroom, color: kGreen),
              title:
                  Text('Parents', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -56),
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('$parentCount',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          const _GlassCard(
            child: ListTile(
              leading: Icon(Icons.school, color: kGreen),
              title: Text('Children',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -56),
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('$childrenCount',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ),

          // ملاحظة: تم إزالة "Recent activity" حسب طلبك
        ],
      ),
    );
  }

  // ============ TAB 2: STAFF ============
  Widget _buildStaffTab() {
    return Padding(
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
            child: staffData.isEmpty
                ? const _EmptyState(
                    icon: Icons.badge,
                    title: 'No staff yet',
                    subtitle: 'Tap “Add Staff” to create the first member.')
                : ListView.separated(
                    itemCount: staffData.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final name = staffData.keys.elementAt(i);
                      final s = staffData[name]!;
                      return _GlassCard(
                        child: ListTile(
                          leading: _Avatar(initials: _initials(name)),
                          title: Text(name,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            'Email: ${s['email']}\nPhone: ${s['phone']}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit, color: Colors.black87),
                                onPressed: () => _openEditStaffSheet(name),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteStaff(name),
                              ),
                              _CopyablePasswordChip(password: s['password']),
                              _SyncIcon(synced: s['synced'] == true),
                            ],
                          ),
                          onTap: () => _openEditStaffSheet(name),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============ TAB 3: PARENTS ============
  Widget _buildParentsTab() {
    return Padding(
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
            child: parentData.isEmpty
                ? const _EmptyState(
                    icon: Icons.family_restroom,
                    title: 'No parents yet',
                    subtitle:
                        'Tap “Add Parent” to create the first parent.')
                : ListView.separated(
                    itemCount: parentData.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final name = parentData.keys.elementAt(i);
                      final p = parentData[name]!;
                      final children =
                          (p['children'] as List<Map<String, String>>?) ?? [];
                      final staff = p['staff']?.toString() ?? '-';

                      return _GlassCard(
                        child: ListTile(
                          leading: _Avatar(initials: _initials(name)),
                          title: Text(name,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            'Email: ${p['email']}\nPhone: ${p['phone']}\nStaff: $staff\nChildren: ${children.map((c) => c['name']).join(', ')}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit, color: Colors.black87),
                                onPressed: () => _openEditParentSheet(name),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteParent(name),
                              ),
                              _CopyablePasswordChip(password: p['password']),
                              _SyncIcon(synced: p['synced'] == true),
                            ],
                          ),
                          onTap: () => _openEditParentSheet(name),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ======== BottomSheets ========
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
                      decoration: const InputDecoration(labelText: 'Name')),
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
                          backgroundColor: kGreen, foregroundColor: Colors.white),
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
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name required';
                          }
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v)) {
                            return 'Only letters allowed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email required';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Phone Number'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Phone required';
                          }
                          if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                            return 'Phone must be 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: empCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Employee Number'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Employee Number required';
                          }
                          if (!RegExp(r'^\d{5}$').hasMatch(v)) {
                            return 'Must be 5 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _CopyablePasswordChip(password: password),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            final key = nameCtrl.text.trim();
                            final payload = {
                              'name': key,
                              'email': emailCtrl.text.trim(),
                              'password': password,
                              'phone': phoneCtrl.text.trim(),
                              'employee_number': empCtrl.text.trim(),
                            };

                            // أضف محليًا فورًا
                            if (mounted) {
                              setState(() {
                                staffData[key] = {
                                  'email': payload['email'],
                                  'phone': payload['phone'],
                                  'empNumber': payload['employee_number'],
                                  'password': password,
                                  'parents': <String>[],
                                  'synced': false,
                                  // سيُملأ user_id لاحقًا إذا توفر من السيرفر
                                };
                              });
                            }
                            if (mounted) Navigator.pop(ctx);

                            // شبكة
                            try {
                              final result =
                                  await _postJson(staffAddApi, payload);
                              final ok = result['status'] == 'success';
                              final userId = result['user_id'];
                              if (mounted && staffData.containsKey(key)) {
                                setState(() {
                                  staffData[key]!['synced'] = ok;
                                  if (userId != null) {
                                    staffData[key]!['user_id'] = userId;
                                  }
                                });
                              }
                              _snack(ok
                                  ? 'Staff added (synced)'
                                  : 'Added locally but server said: ${result['message']}');
                            } catch (e) {
                              _snack(
                                  'Added locally (offline). Server error: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              foregroundColor: Colors.white),
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

  void _openEditStaffSheet(String originalKey) async {
    final data = staffData[originalKey]!;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: originalKey);
    final emailCtrl = TextEditingController(text: '${data['email'] ?? ''}');
    final phoneCtrl = TextEditingController(text: '${data['phone'] ?? ''}');
    final empCtrl = TextEditingController(text: '${data['empNumber'] ?? ''}');
    final passCtrl = TextEditingController(); // فارغ = لا تغيير

    // تأكد من user_id (إن لم يكن موجود)
    int? userId = data['user_id'] is int ? data['user_id'] as int : null;
    userId ??= await _ensureUserIdByEmail(emailCtrl.text.trim());

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
                      const _SheetHeader(title: 'Edit Staff'),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name required';
                          }
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v)) {
                            return 'Only letters allowed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email required';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Phone Number'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Phone required';
                          }
                          if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                            return 'Phone must be 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: empCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Employee Number'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Employee Number required';
                          }
                          if (!RegExp(r'^\d{5}$').hasMatch(v)) {
                            return 'Must be 5 digits';
                          }
                          return null;
                        },
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
                            final newKey = nameCtrl.text.trim();

                            final payload = <String, String>{
                              if (userId != null)
                                'user_id': '$userId'
                              else
                                'email': emailCtrl.text.trim(),
                              'name': newKey,
                              'new_email': emailCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'employee_number': empCtrl.text.trim(),
                            };
                            if (passCtrl.text.trim().isNotEmpty) {
                              payload['password'] = passCtrl.text.trim();
                            }

                            // محليًا
                            setState(() {
                              // لو تغير الاسم (المفتاح)
                              if (newKey != originalKey) {
                                staffData[newKey] = Map<String, dynamic>.from(
                                    staffData[originalKey]!);
                                staffData.remove(originalKey);
                              }
                              staffData[newKey]!.addAll({
                                'email': payload['new_email'],
                                'phone': payload['phone'],
                                'empNumber': payload['employee_number'],
                                'synced': false,
                              });
                              if (userId != null) {
                                staffData[newKey]!['user_id'] = userId;
                              }
                            });

                            if (mounted) Navigator.pop(ctx);

                            try {
                              final result =
                                  await _postJson(staffUpdateApi, payload);
                              final ok = result['status'] == 'success';
                              if (mounted && staffData.containsKey(newKey)) {
                                setState(
                                    () => staffData[newKey]!['synced'] = ok);
                              }
                              _snack(ok
                                  ? 'Staff updated (synced)'
                                  : 'Updated locally but server said: ${result['message']}');
                            } catch (e) {
                              _snack(
                                  'Updated locally (offline). Server error: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              foregroundColor: Colors.white),
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

  Future<void> _deleteStaff(String key) async {
    final data = staffData[key]!;
    final email = data['email']?.toString() ?? '';
    int? userId = data['user_id'] is int ? data['user_id'] as int : null;
    userId ??= await _ensureUserIdByEmail(email);

    final confirmed = await _confirmDelete(
        'Delete Staff', 'Are you sure you want to delete $key?');
    if (!confirmed) return;

    // احفظ نسخة محلية للتراجع لو فشل السيرفر
    final backup = Map<String, dynamic>.from(data);

    // احذف محليًا
    setState(() {
      staffData.remove(key);
      // أزل ربطه بأولياء الأمور (لو كنت تستخدم هذا الربط في الواجهة فقط)
      for (final p in parentData.values) {
        if (p['staff'] == key) p['staff'] = null;
      }
    });

    // شبكة
    try {
      final payload = <String, String>{
        if (userId != null) 'user_id': '$userId' else 'email': email,
      };
      final result = await _postJson(staffDeleteApi, payload);
      final ok = result['status'] == 'success';
      if (!ok) {
        // أعد الإدراج محليًا
        setState(() => staffData[key] = backup);
        _snack('Server refused delete: ${result['message']}');
      } else {
        _snack('Staff deleted');
      }
    } catch (e) {
      // أعد الإدراج محليًا
      setState(() => staffData[key] = backup);
      _snack('Delete failed: $e');
    }
  }

  void _openAddParentSheet() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    String? selectedStaff; // بالاسم المعروض
    final List<Map<String, String>> children = [];
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
                      const _SheetHeader(title: 'Add Parent'),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name required';
                          }
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v)) {
                            return 'Only letters allowed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email required';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Phone Number'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Phone required';
                          }
                          if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                            return 'Phone must be 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: idCtrl,
                        decoration: const InputDecoration(labelText: 'ID Number'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'ID required';
                          }
                          if (!RegExp(r'^\d{10,12}$').hasMatch(v)) {
                            return 'Invalid ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                      value: selectedStaff, 
                     items: staffData.keys
      .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
      .toList(),
  onChanged: (val) => setM(() => selectedStaff = val),
  decoration: const InputDecoration(labelText: 'Assign Staff (optional)'),
),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              final childName = TextEditingController();
                              final childClass = TextEditingController();
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Add Child'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                          controller: childName,
                                          decoration: const InputDecoration(
                                              labelText: 'Child Name')),
                                      TextField(
                                          controller: childClass,
                                          decoration: const InputDecoration(
                                              labelText: 'Class')),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (childName.text.trim().isEmpty) {
                                          return;
                                        }
                                        children.add({
                                          'name': childName.text.trim(),
                                          'class': childClass.text.trim()
                                        });
                                        Navigator.pop(context);
                                        _snack('Child added');
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: kGreen,
                                          foregroundColor: Colors.white),
                                      child: const Text('Add'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Child'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kButtonBg,
                                foregroundColor: kGreen),
                          ),
                          const SizedBox(width: 8),
                          if (children.isNotEmpty)
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                children: children
                                    .map((c) => Chip(
                                          label: Text(c['name'] ?? '-',
                                              overflow:
                                                  TextOverflow.ellipsis),
                                          avatar:
                                              const Icon(Icons.school, size: 16),
                                        ))
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _CopyablePasswordChip(password: password),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            final key = nameCtrl.text.trim();
                            final staffEmail =
                                (selectedStaff != null &&
                                        staffData.containsKey(selectedStaff))
                                    ? (staffData[selectedStaff]!['email']
                                        as String)
                                    : '';

                            final payload = {
                              'name': key,
                              'email': emailCtrl.text.trim(),
                              'password': password,
                              'phone': phoneCtrl.text.trim(),
                              'identity_number': idCtrl.text.trim(),
                              'assigned_staff_email': staffEmail,
                              'children': jsonEncode(children),
                            };

                            // محليًا
                            if (mounted) {
                              setState(() {
                                parentData[key] = {
                                  'email': payload['email'],
                                  'phone': payload['phone'],
                                  'id': payload['identity_number'],
                                  'password': password,
                                  'children':
                                      List<Map<String, String>>.from(children),
                                  'staff': selectedStaff,
                                  'synced': false,
                                };
                                if (selectedStaff != null &&
                                    staffData.containsKey(selectedStaff)) {
                                  (staffData[selectedStaff]!['parents']
                                              as List<String>? ??
                                          <String>[])
                                      .add(key);
                                }
                              });
                            }
                            if (mounted) Navigator.pop(ctx);

                            // شبكة
                            try {
                              final result =
                                  await _postJson(parentAddApi, payload);
                              final ok = result['status'] == 'success';
                              final userId = result['user_id'];
                              if (mounted && parentData.containsKey(key)) {
                                setState(() {
                                  parentData[key]!['synced'] = ok;
                                  if (userId != null) {
                                    parentData[key]!['user_id'] = userId;
                                  }
                                });
                              }
                              _snack(ok
                                  ? 'Parent added (synced)'
                                  : 'Added locally but server said: ${result['message']}');
                            } catch (e) {
                              _snack(
                                  'Added locally (offline). Server error: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              foregroundColor: Colors.white),
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

  void _openEditParentSheet(String originalKey) async {
    final data = parentData[originalKey]!;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: originalKey);
    final emailCtrl = TextEditingController(text: '${data['email'] ?? ''}');
    final phoneCtrl = TextEditingController(text: '${data['phone'] ?? ''}');
    final idCtrl = TextEditingController(text: '${data['id'] ?? ''}');
    String? selectedStaff = data['staff']?.toString();
    final List<Map<String, String>> children =
        List<Map<String, String>>.from(
      (data['children'] as List?)
              ?.map((e) => Map<String, String>.from(e as Map)) ??
          const [],
    );
    final passCtrl = TextEditingController(); // فارغ = لا تغيير

    // تأكد من user_id (إن لم يكن موجود)
    int? userId = data['user_id'] is int ? data['user_id'] as int : null;
    userId ??= await _ensureUserIdByEmail(emailCtrl.text.trim());

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
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name required';
                          }
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v)) {
                            return 'Only letters allowed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email required';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Phone Number'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Phone required';
                          }
                          if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                            return 'Phone must be 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: idCtrl,
                        decoration: const InputDecoration(labelText: 'ID Number'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'ID required';
                          }
                          if (!RegExp(r'^\d{10,12}$').hasMatch(v)) {
                            return 'Invalid ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedStaff,
                        items: staffData.keys
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child:
                                    Text(s, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) => setM(() => selectedStaff = val),
                        decoration: const InputDecoration(
                            labelText: 'Assign Staff (optional)'),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: -4,
                          children: [
                            ...children.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final c = entry.value;
                              return Chip(
                                avatar: const Icon(Icons.school, size: 16),
                                label: Text(c['name'] ?? '-',
                                    overflow: TextOverflow.ellipsis),
                                onDeleted: () {
                                  setM(() => children.removeAt(idx));
                                },
                              );
                            }),
                            ActionChip(
                              avatar: const Icon(Icons.add, size: 18),
                              label: const Text('Add Child'),
                              onPressed: () {
                                final childName = TextEditingController();
                                final childClass = TextEditingController();
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Add Child'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                            controller: childName,
                                            decoration: const InputDecoration(
                                                labelText: 'Child Name')),
                                        TextField(
                                            controller: childClass,
                                            decoration: const InputDecoration(
                                                labelText: 'Class')),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel')),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (childName.text.trim().isEmpty) {
                                            return;
                                          }
                                          setM(() => children.add({
                                                'name': childName.text.trim(),
                                                'class':
                                                    childClass.text.trim()
                                              }));
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: kGreen,
                                            foregroundColor: Colors.white),
                                        child: const Text('Add'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
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
                            final newKey = nameCtrl.text.trim();
                            final oldStaff = data['staff']?.toString();
                            final staffEmail =
                                (selectedStaff != null &&
                                        staffData.containsKey(selectedStaff))
                                    ? (staffData[selectedStaff]!['email']
                                        as String)
                                    : '';

                            final payload = <String, String>{
                              if (userId != null)
                                'user_id': '$userId'
                              else
                                'email': emailCtrl.text.trim(),
                              'name': newKey,
                              'new_email': emailCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'identity_number': idCtrl.text.trim(),
                              'assigned_staff_email': staffEmail,
                              'children': jsonEncode(children),
                            };
                            if (passCtrl.text.trim().isNotEmpty) {
                              payload['password'] = passCtrl.text.trim();
                            }

                            // محليًا
                            setState(() {
                              if (newKey != originalKey) {
                                parentData[newKey] = Map<String, dynamic>.from(
                                    parentData[originalKey]!);
                                parentData.remove(originalKey);
                              }
                              parentData[newKey]!.addAll({
                                'email': payload['new_email'],
                                'phone': payload['phone'],
                                'id': payload['identity_number'],
                                'children':
                                    List<Map<String, String>>.from(children),
                                'staff': selectedStaff,
                                'synced': false,
                              });
                              if (userId != null) {
                                parentData[newKey]!['user_id'] = userId;
                              }

                              // حدّث الربط في staffData لو تغيّر الموظف المعيّن
                              if (oldStaff != selectedStaff) {
                                if (oldStaff != null &&
                                    staffData.containsKey(oldStaff)) {
                                  (staffData[oldStaff]!['parents']
                                          as List<String>?)
                                      ?.remove(newKey);
                                }
                                if (selectedStaff != null &&
                                    staffData.containsKey(selectedStaff)) {
                                  (staffData[selectedStaff]!['parents']
                                              as List<String>? ??
                                          <String>[])
                                      .add(newKey);
                                }
                              }
                            });

                            if (mounted) Navigator.pop(ctx);

                            try {
                              final result =
                                  await _postJson(parentUpdateApi, payload);
                              final ok = result['status'] == 'success';
                              if (mounted && parentData.containsKey(newKey)) {
                                setState(
                                    () => parentData[newKey]!['synced'] = ok);
                              }
                              _snack(ok
                                  ? 'Parent updated (synced)'
                                  : 'Updated locally but server said: ${result['message']}');
                            } catch (e) {
                              _snack(
                                  'Updated locally (offline). Server error: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              foregroundColor: Colors.white),
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

  Future<void> _deleteParent(String key) async {
    final data = parentData[key]!;
    final email = data['email']?.toString() ?? '';
    int? userId = data['user_id'] is int ? data['user_id'] as int : null;
    userId ??= await _ensureUserIdByEmail(email);

    final confirmed = await _confirmDelete(
        'Delete Parent', 'Are you sure you want to delete $key?');
    if (!confirmed) return;

    final backup = Map<String, dynamic>.from(data);
    final oldStaff = data['staff']?.toString();

    // احذف محليًا
    setState(() {
      parentData.remove(key);
      if (oldStaff != null && staffData.containsKey(oldStaff)) {
        (staffData[oldStaff]!['parents'] as List<String>?)?.remove(key);
      }
    });

    // شبكة
    try {
      final payload = <String, String>{
        if (userId != null) 'user_id': '$userId' else 'email': email,
      };
      final result = await _postJson(parentDeleteApi, payload);
      final ok = result['status'] == 'success';
      if (!ok) {
        setState(() => parentData[key] = backup);
        if (oldStaff != null && staffData.containsKey(oldStaff)) {
          (staffData[oldStaff]!['parents'] as List<String>? ?? <String>[])
              .add(key);
        }
        _snack('Server refused delete: ${result['message']}');
      } else {
        _snack('Parent deleted');
      }
    } catch (e) {
      setState(() => parentData[key] = backup);
      if (oldStaff != null && staffData.containsKey(oldStaff)) {
        (staffData[oldStaff]!['parents'] as List<String>? ?? <String>[])
            .add(key);
      }
      _snack('Delete failed: $e');
    }
  }

  // ===== Utils =====
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
}

// ======== Small widgets ========

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
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54)),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 18,
        color: Colors.black87,
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final String text;
  const _SheetTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18));
  }
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

class _CopyablePasswordChip extends StatelessWidget {
  final String password;
  const _CopyablePasswordChip({required this.password});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.key, size: 18),
      label:
          Text('Password: $password', overflow: TextOverflow.ellipsis),
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: password));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Password copied')));
      },
      backgroundColor: _AdminDashboardState.kButtonBg,
      labelStyle: const TextStyle(
          color: _AdminDashboardState.kGreen, fontWeight: FontWeight.w600),
    );
  }
}

class _SyncIcon extends StatelessWidget {
  final bool synced;
  const _SyncIcon({required this.synced});

  @override
  Widget build(BuildContext context) {
    return Icon(
      synced ? Icons.cloud_done : Icons.cloud_off,
      size: 18,
      color: synced ? Colors.green : Colors.orange,
    );
  }
}
