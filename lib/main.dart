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
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: null,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF507C5C), // الأخضر الداكن
          primary: const Color(0xFF507C5C),
          onPrimary: Colors.white,
          surface: const Color(0xFFEFF6F1), // الخلفية الفاتحة
          onSurface: const Color(0xFF2F4A39),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // ألوان قريبة من التصميم
  static const Color kBgLight = Color(0xFFEFF6F1); // الخلفية العامة
  static const Color kPanelLight = Color(0xFFE6F0EA); // بانِل خفيف
  static const Color kGreen = Color(0xFF507C5C); // نص/أيقونة
  static const Color kHintRed = Color(0xFFB46363); // نص الإرشاد
  static const Color kButtonBg = Color(0xFFE4EFE7); // خلفية الأزرار

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: kBgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              width: width.clamp(320, 440), // يثبت الشكل على الشاشات العريضة
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                color: kPanelLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _PersonClockIcon(color: kGreen, size: 120),
                  const SizedBox(height: 18),
                  const Text(
                    'Wethaq System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: kGreen,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Choose your role to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kHintRed,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _RoleButton(
                    label: 'Parent',
                    onPressed: () {
                      // TODO: انتقلي لواجهة ولي الأمر
                    },
                  ),
                  const SizedBox(height: 14),
                  _RoleButton(
                    label: 'Members',
                    onPressed: () {
                      // TODO: انتقلي لواجهة الموظفين/الأعضاء
                    },
                  ),
                  const SizedBox(height: 14),
                  _RoleButton(
                    label: 'Admin',
                    onPressed: () {
                      // TODO: انتقلي لواجهة المشرف/المدير
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// زر ستايله مطابق (كبس دائري، خلفية فاتحة، نص أخضر)
class _RoleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _RoleButton({required this.label, required this.onPressed});

  static const Color kGreen = WelcomeScreen.kGreen;
  static const Color kButtonBg = WelcomeScreen.kButtonBg;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kButtonBg,
          foregroundColor: kGreen,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

/// أيقونة شخص + ساعة بطريقة Stack حتى تكون قريبة من التصميم
class _PersonClockIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _PersonClockIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final double personSize = size;
    final double clockSize = size * 0.48;

    return SizedBox(
      width: size + clockSize * 0.6,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // شخص
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(
              Icons.account_circle,
              size: personSize,
              color: color.withOpacity(0.95),
            ),
          ),
          // ساعة متداخلة يمين
          Positioned(
            right: -clockSize * 0.12,
            top: size * 0.26,
            child: Container(
              width: clockSize,
              height: clockSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 10),
              ),
              child: FittedBox(
                child: Icon(
                  Icons.schedule,
                  color: color,
                  size: clockSize * 0.7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
