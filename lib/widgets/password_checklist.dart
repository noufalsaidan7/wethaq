import 'package:flutter/material.dart';

class PasswordChecklist extends StatelessWidget {
  final String password;
  const PasswordChecklist({super.key, required this.password});

  bool get _lenOK => password.length >= 8;
  int get _letters => RegExp(r'[A-Za-z]').allMatches(password).length;
  int get _digits => RegExp(r'\d').allMatches(password).length;
  int get _symbols => RegExp(r'[^A-Za-z0-9]').allMatches(password).length;

  Widget _row(BuildContext ctx, bool ok, String text) {
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel,
            size: 18, color: ok ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lettersOK = _letters >= 4;
    final digitsOK = _digits >= 3;
    final symbolsOK = _symbols >= 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(context, _lenOK, 'At least 8 characters'),
          const SizedBox(height: 6),
          _row(context, lettersOK, 'At least 4 letters (A–Z)'),
          const SizedBox(height: 6),
          _row(context, digitsOK, 'At least 3 digits (0–9)'),
          const SizedBox(height: 6),
          _row(context, symbolsOK, 'At least 1 symbol'),
        ],
      ),
    );
  }
}
