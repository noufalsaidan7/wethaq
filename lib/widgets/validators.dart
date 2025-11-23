import 'package:flutter/material.dart';

/// Returns `null` if strong, otherwise an English message.
String? validateStrongPassword(String? v) {
  final p = (v ?? '');
  if (p.length < 8) return 'Password must be at least 8 characters.';
  final letters = RegExp(r'[A-Za-z]').allMatches(p).length;
  final digits = RegExp(r'\d').allMatches(p).length;
  final symbols = RegExp(r'[^A-Za-z0-9]').allMatches(p).length;
  if (letters < 4 || digits < 3 || symbols < 1) {
    return 'Use ≥4 letters, ≥3 digits, and ≥1 symbol.';
  }
  return null;
}

/// Quick boolean check (for live UI like a checklist).
bool isPasswordStrong(String p) => validateStrongPassword(p) == null;

/// Username (optional):
/// - English only (A–Z a–z 0–9 . _ -)
/// - No spaces
/// - Must NOT contain Arabic letters
/// - Must not contain the password (when provided)
String? validateUsernameOptional(String? username, {String? againstPassword}) {
  final u = (username ?? '').trim();
  if (u.isEmpty) return null; // optional
  // Arabic letters
  if (RegExp(r'[اأإآء-ي]').hasMatch(u)) {
    return 'Username must be English only.';
  }
  if (RegExp(r'\s').hasMatch(u)) {
    return 'Username cannot contain spaces.';
  }
  if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(u)) {
    return 'Allowed characters: letters, digits, dot, underscore, hyphen.';
  }
  if ((againstPassword ?? '').isNotEmpty) {
    final uLow = u.toLowerCase();
    final pLow = againstPassword!.toLowerCase();
    if (uLow.length >= 4 && pLow.contains(uLow)) {
      return 'Password must not contain the username.';
    }
    if (pLow.length >= 4 && uLow.contains(pLow)) {
      return 'Username must not contain the password.';
    }
  }
  return null;
}
