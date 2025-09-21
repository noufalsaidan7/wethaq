import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'reset_password_screen.dart';
import 'admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({required this.role, super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

const String baseUrl = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://192.168.1.13/wethaq',
);

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  // ط£ظ„ظˆط§ظ†
  static const Color kPanelGreen = Color(0xFF5E8B62);
  static const Color kFieldFill = Color(0xFFA3B8A6);
  static const Color kBtnFill = Color(0xFFE4EFE7);
  static const Color kForgot = Color(0xFFCC8F93);

  // ط£ظ†ظٹظ…ظٹط´ظ† ط§ظ„ط¨ط§ظ†ظ„
  late final AnimationController _panelCtrl;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // ط§ط¨ط·ط£ ط´ظˆظٹ
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.20), // ظٹط¨ط¯ط£ طھط­طھ ط´ظˆظٹ
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _panelCtrl,
      curve: Curves.easeOutCubic,
    ));
    _fadeIn = CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _panelCtrl.forward();
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    _panelCtrl.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    setState(() => isLoading = true);
    try {
      var url = Uri.parse("$baseUrl/login.php");
      final response = await http.post(url, body: {
        "email": usernameController.text,
        "password": passwordController.text,
        "role": widget.role,
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == "success") {
          if (widget.role == "Admin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Logged in as ${widget.role}")),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("â‌Œ ${data["message"]}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("â‌Œ Server error (${response.statusCode})")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("âڑ ï¸ڈ Connection error: $e")),
      );
    }
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.of(context).viewInsets.bottom; // ط§ط±طھظپط§ط¹ ط§ظ„ظƒظٹط¨ظˆط±ط¯

    return Scaffold(
      resizeToAvoidBottomInset: true, // ظٹط®ظ„ظٹ ط§ظ„ط¨ظˆط¯ظٹ ظٹط·ظ„ط¹ ظپظˆظ‚ ط§ظ„ظƒظٹط¨ظˆط±ط¯
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // ط³ظ‡ظ… ط§ظ„ط±ط¬ظˆط¹
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ===== ط§ظ„ط¬ط²ط، ط§ظ„ط£ط¨ظٹط¶ ط§ظ„ط¹ظ„ظˆظٹ =====
          Expanded(
            flex: 3, // 30%
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Wethaq',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
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

          // ===== ط§ظ„ط¬ط²ط، ط§ظ„ط£ط®ط¶ط± ط§ظ„ط³ظپظ„ظٹ ظ…ط¹ ط§ظ„ط£ظ†ظٹظ…ظٹط´ظ† + ط­ظ„ظˆظ„ ط§ظ„ظƒظٹط¨ظˆط±ط¯ =====
          Expanded(
            flex: 7, // 70%
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
                    builder: (context, constraints) {
                      // ظ†ط³طھط®ط¯ظ… ScrollView + padding ط³ظپظ„ظٹ ط¨ط§ط±طھظپط§ط¹ ط§ظ„ظƒظٹط¨ظˆط±ط¯
                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding:
                            EdgeInsets.fromLTRB(28, 32, 28, 24 + bottomInset),
                        child: ConstrainedBox(
                          // ظ„ظ…ط§ ط§ظ„ظƒظٹط¨ظˆط±ط¯ ظ…ظ‚ظپظˆظ„: ظˆط³ظ‘ط· ط¹ظ…ظˆط¯ظٹظ‹ط§ (minHeight = ط§ط±طھظپط§ط¹ ط§ظ„ط¨ط§ظ†ظ„ ظ†ط§ظ‚طµ ط§ظ„ظ‡ظˆط§ظ…ط´)
                          constraints: BoxConstraints(
                            minHeight: bottomInset == 0
                                ? constraints.maxHeight - (32 + 24)
                                : 0,
                          ),
                          child: Column(
                            mainAxisAlignment: bottomInset == 0
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'User name',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: usernameController,
                                keyboardType: TextInputType.emailAddress,
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
                                style: const TextStyle(color: Colors.black),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Password',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock,
                                      color: Colors.white70),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey[800],
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: kFieldFill,
                                  border: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30)),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: const TextStyle(color: Colors.black),
                              ),
                              const SizedBox(height: 28),
                              Center(
                                child: SizedBox(
                                  width: 140,
                                  height: 42,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : loginUser,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kBtnFill,
                                      shape: const StadiumBorder(),
                                      elevation: 0,
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Text(
                                            'Log in',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: kPanelGreen,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ResetPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot your password?',
                                    style:
                                        TextStyle(fontSize: 15, color: kForgot),
                                  ),
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


