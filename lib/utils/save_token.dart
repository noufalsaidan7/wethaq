import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> saveFcmTokenToServer({
  required String userId,
}) async {
  final fcm = FirebaseMessaging.instance;

  // نتأكد من الصلاحية ثم نجيب التوكن
  final perm = await fcm.requestPermission();
  final token = await fcm.getToken();

  if (token == null) {
    print('⚠️ FCM token is null');
    return;
  }

  print('✅ FCM TOKEN: $token');

  final uri = Uri.parse('http://10.0.2.2/wethaq/save_fcm_token.php');

  final res = await http.post(
    uri,
    body: {
      'user_id': userId,
      'token': token,
      'platform': 'android',
    },
  );

  print('📡 save_fcm_token response: ${res.statusCode} ${res.body}');
}
