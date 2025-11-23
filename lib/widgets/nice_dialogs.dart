import 'package:flutter/material.dart';

Future<void> showNiceErrorDialog(
  BuildContext context, {
  required String message,
  String title = 'Oops!',
  String buttonText = 'Got it',
}) async {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFFE8E8),
            child: Icon(Icons.error_outline, color: Colors.red),
          ),
          const SizedBox(width: 10),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    ),
  );
}

Future<void> showNiceSuccessDialog(
  BuildContext context, {
  required String message,
  String title = 'Done',
  String buttonText = 'OK',
}) async {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE8FFF1),
            child: Icon(Icons.check, color: Colors.green),
          ),
          const SizedBox(width: 10),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    ),
  );
}
