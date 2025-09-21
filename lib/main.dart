import 'package:flutter/material.dart';

void main() {
  runApp(const WethaqApp());
}

class WethaqApp extends StatelessWidget {
  const WethaqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wethaq',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: const WethaqHome(),
    );
  }
}

class WethaqHome extends StatelessWidget {
  const WethaqHome({super.key});

  static const Color darkGreen = Color(0xFF3F6F56);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // الشعار
                SizedBox(
                  height: 140,
                  width: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.account_circle,
                        size: 120,
                        color: darkGreen.withOpacity(0.9),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 12,
                        child: Container(
                          height: 58,
                          width: 58,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(2, 2),
                              ),
                            ],
                            border: Border.all(color: darkGreen, width: 5.0),
                          ),
                          child: Icon(
                            Icons.access_time_filled,
                            size: 28,
                            color: darkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Wethaq',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  'Choose your role to continue',
                  style: TextStyle(fontSize: 16, color: Color(0xFFB44F4F)),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 25),

                _RoleButton(
                  label: 'Parent',
                  color: darkGreen,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ParentLoginPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _RoleButton(label: 'Members', onTap: () {}, color: darkGreen),
                const SizedBox(height: 18),
                _RoleButton(label: 'Admin', onTap: () {}, color: darkGreen),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _RoleButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(.95), color],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Color(0x22FFFFFF),
                blurRadius: 6,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// صفحة تسجيل دخول Parent
class ParentLoginPage extends StatefulWidget {
  const ParentLoginPage({super.key});
  @override
  State<ParentLoginPage> createState() => _ParentLoginPageState();
}

class _ParentLoginPageState extends State<ParentLoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;

  final Color darkGreen = const Color(0xFF3F6F56);
  final Color panelGreen = const Color(0xFF6F9E82);
  final Color fieldFill = const Color(0xFFBFD2C6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Wethaq',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black.withOpacity(.7),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
                decoration: BoxDecoration(
                  color: panelGreen,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Label('Email', color: Colors.white.withOpacity(.9)),
                    _Field(
                      controller: _email,
                      fill: fieldFill,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),

                    _Label('Password', color: Colors.white.withOpacity(.9)),
                    _Field(
                      controller: _pass,
                      fill: fieldFill,
                      hint: 'Password',
                      obscure: _obscure,
                      icon: _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      onIconTap: () => setState(() => _obscure = !_obscure),
                    ),
                    const SizedBox(height: 22),

                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: Text(
                          'Log in',
                          style: TextStyle(
                            color: darkGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Forgot your password?',
                  style: TextStyle(color: Color(0xFFD5443D)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6, bottom: 6),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.fill,
    required this.hint,
    this.obscure = false,
    this.icon,
    this.onIconTap,
  });

  final TextEditingController controller;
  final Color fill;
  final String hint;
  final bool obscure;
  final IconData? icon;
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: icon != null
              ? IconButton(
                  icon: Icon(icon, color: Colors.black54),
                  onPressed: onIconTap,
                )
              : null,
          filled: true,
          fillColor: fill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
