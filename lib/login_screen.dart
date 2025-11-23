import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wethaq/utils/save_token.dart';

import 'admin_dashboard.dart';
import 'staff_dashboard.dart';
import 'parent_dashboard.dart';
import 'package:wethaq/utils/save_token.dart';

//const String baseUrl = 'http://192.168.1.28:8080/wethaq';

const String baseUrl = 'http://10.0.2.2/wethaq';

class LoginScreen extends StatefulWidget {
  final String role; // 'Admin' | 'Staff' | 'Parent' (من شاشة اختيار الدور)
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  // ألوان واجهة تسجيل الدخول
  static const Color kPanelGreen = Color(0xFF5E8B62);
  static const Color kFieldFill = Color(0xFFA3B8A6);
  static const Color kBtnFill = Color(0xFFE4EFE7);
  static const Color kForgot = Color(0xFFCC8F93);

  late final AnimationController _panelCtrl;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideUp = Tween(begin: const Offset(0, .20), end: Offset.zero).animate(
        CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOutCubic));
    _fadeIn = CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) => _panelCtrl.forward());
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _panelCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    final u = _username.text.trim();
    final p = _password.text.trim();
    if (u.isEmpty || p.isEmpty) {
      _snack('Please enter username and password');
      return;
    }

    setState(() => _busy = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login.php'),
        body: {'username': u, 'password': p},
      );
      if (res.statusCode != 200) {
        _snack('Server error: ${res.statusCode}');
        return;
      }
      final data = jsonDecode(res.body);
      if (data is! Map || data['status'] != 'success') {
        _snack('${data['message'] ?? 'Login failed'}');
        return;
      }

      final user = data['user'] as Map;
      final role = (user['role'] ?? '').toString();
      // 🟢    لحفظ توكن الإشعارات بعد نجاح تسجيل الدخول
      String userId = user['id'].toString();
      await saveFcmTokenToServer(userId: userId);

      if (role == 'Admin') {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else if (role == 'Staff') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StaffDashboard(
              staffUserId: int.parse(user['id'].toString()),
              staffName: user['name'] ?? '',
              staffEmail: user['email'] ?? '',
            ),
          ),
        );
      } else if (role == 'Parent') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParentDashboard(
              parentUserId: int.parse(user['id'].toString()),
              parentName: user['name'] ?? '',
              parentEmail: user['email'] ?? '',
            ),
          ),
        );
      } else {
        _snack('Unknown role: $role');
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // العنوان
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Wethaq',
                    style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 42,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Welcome ${widget.role}',
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // البانل
          Expanded(
            flex: 7,
            child: SlideTransition(
              position: _slideUp,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: kPanelGreen,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(36),
                      topRight: Radius.circular(36),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding:
                            EdgeInsets.fromLTRB(28, 32, 28, 24 + bottomInset),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                bottomInset == 0 ? c.maxHeight - (32 + 24) : 0,
                          ),
                          child: Column(
                            mainAxisAlignment: bottomInset == 0
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('User name',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _username,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.person, color: Colors.white70),
                                  filled: true,
                                  fillColor: kFieldFill,
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30)),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('Password',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _password,
                                obscureText: _obscure,
                                onSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock,
                                      color: Colors.white70),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey[800],
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                  filled: true,
                                  fillColor: kFieldFill,
                                  border: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30)),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Center(
                                child: SizedBox(
                                  width: 140,
                                  height: 42,
                                  child: ElevatedButton(
                                    onPressed: _busy ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: kBtnFill,
                                        shape: const StadiumBorder(),
                                        elevation: 0),
                                    child: _busy
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Text('Log in',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: kPanelGreen)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Center(
                                child: Text(
                                  'Forgot your password?',
                                  style: const TextStyle(
                                      fontSize: 15, color: kForgot),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
