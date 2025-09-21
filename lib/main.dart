import 'package:flutter/material.dart';
import 'login_screen.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF507C5C),
          primary: const Color(0xFF507C5C),
          onPrimary: Colors.white,
          surface: const Color(0xFFEFF6F1),
          onSurface: const Color(0xFF2F4A39),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(seconds: 1), () {
      _controller.forward().whenComplete(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
            'assets/images/wethaq_logo.png',
              width: 250,
              height: 250,
           ),
          ),
        ),
      ),
    );
  }
}

/// Welcome Screen
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color kPanelLight = Color(0xFFE6F0EA);
  static const Color kGreen = Color(0xFF507C5C);
  static const Color kGreenLight = Color(0xFFE4EFE7);
  static const Color kAccent = Color(0xFF2E6DB0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: kPanelLight,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bigger logo
            Image.asset(
            'assets/images/wethaq_logo.png',
             width: 250,
             height: 250,
             ),

            const SizedBox(height: 22),
            const Text(
              'Wethaq System',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: kGreen,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Choose your role to continue',
              style: TextStyle(
                fontSize: 16,
                color: kAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Role Buttons
            _RoleCard(
              icon: Icons.family_restroom,
              label: 'Parent',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen(role: 'Parent')),
                );
              },
            ),
            const SizedBox(height: 16),
            _RoleCard(
              icon: Icons.groups_2,
              label: 'Members',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen(role: 'Members')),
                );
              },
            ),
            const SizedBox(height: 16),
            _RoleCard(
              icon: Icons.admin_panel_settings,
              label: 'Admin',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen(role: 'Admin')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// New styled role button
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: WelcomeScreen.kGreen, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: WelcomeScreen.kGreenLight,
          foregroundColor: WelcomeScreen.kGreen,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
