import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

/// لازم تكون خارج main كـ top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // تقدر تسوي أي لوجيك هنا للخلفية
}

/// قناة اندرويد
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Default channel for FCM',
  importance: Importance.high,
);

Future<void> initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await _fln.initialize(initSettings);
  // إنشاء القناة
  await _fln
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);
}

Future<void> initFCM() async {
  // طلب صلاحية الاشعارات (اندرويد 13+ / iOS)
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );
  debugPrint('Notification permission: ${settings.authorizationStatus}');

  // توكن الجهاز – انسخيه من الـ log
  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('FCM TOKEN: $token');

  // هندل للخلفية
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // فورجراوند: نعرض اشعار محلي
  FirebaseMessaging.onMessage.listen((msg) async {
    final n = msg.notification;
    if (n != null && !kIsWeb && Platform.isAndroid) {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          priority: Priority.high,
          importance: Importance.high,
        ),
      );
      await _fln.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        n.title,
        n.body,
        details,
        payload: msg.data.toString(),
      );
    }
  });

  // لما يضغط على الاشعار ويفتح التطبيق
  FirebaseMessaging.onMessageOpenedApp.listen((msg) {
    debugPrint('onMessageOpenedApp data: ${msg.data}');
  });
}
