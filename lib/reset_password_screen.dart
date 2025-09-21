import 'package:flutter/material.dart';
import 'dart:math';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  String? generatedOtp;
  bool otpSent = false;

  // قائمة تجريبية للبريد المسجل
  final List<String> registeredEmails = [
    'parent@example.com',
    'admin@example.com',
    'member@example.com'
  ];

  String _generateOtp() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF507C5C);

    return Scaffold(
      appBar: AppBar(
          title: const Text('Reset Password'), backgroundColor: primaryColor),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Enter your email to reset password',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String email = emailController.text.trim();
                if (!registeredEmails.contains(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email not registered')),
                  );
                  return;
                }
                generatedOtp = _generateOtp();
                otpSent = true;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('OTP sent to $email (demo: $generatedOtp)')),
                );
                setState(() {});
              },
              child: const Text('Send OTP'),
            ),
            if (otpSent) ...[
              const SizedBox(height: 20),
              TextField(
                controller: otpController,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (otpController.text.trim() != generatedOtp) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid OTP')),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password reset successfully!')),
                  );
                  // إعادة تعيين الحقول
                  emailController.clear();
                  otpController.clear();
                  newPasswordController.clear();
                  otpSent = false;
                  generatedOtp = null;
                  setState(() {});
                },
                child: const Text('Reset Password'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
