import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> setupLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const init = InitializationSettings(android: android);
  await _flutterLocalNotificationsPlugin.initialize(init);

  // قناة افتراضية
  const channel = AndroidNotificationChannel(
    'wethaq_default',
    'Wethaq Notifications',
    description: 'Default channel',
    importance: Importance.high,
  );
  await _flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

// لازم تكون top-level (خارج أي class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

Future<void> setupFcmListeners() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final notif = message.notification;
    if (notif != null) {
      // نظهر إشعار محلي في الـforeground
      await _flutterLocalNotificationsPlugin.show(
        notif.hashCode,
        notif.title,
        notif.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'wethaq_default',
            'Wethaq Notifications',
            channelDescription: 'Default channel',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // هنا لو ضغط المستخدم على الإشعار وافتح التطبيق
    //  لصفحة معيّنة مثلاً
  });
}
