// notification_service.dart
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// بلجن الإشعارات المحلية (Android)
final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

/// قناة أندرويد للإشعارات ذات الأهمية العالية
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Default channel for FCM',
  importance: Importance.high,
);

/// مهم: الهاندلر الخاص بإشعارات الخلفية لازم يكون top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // مثلاً: print أو حفظ في قاعدة بيانات محلية
  debugPrint('💤 [BG] message data = ${message.data}');
}

/// تهيئة الإشعارات المحلية (FlutterLocalNotifications)
Future<void> initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  const initSettings = InitializationSettings(
    android: androidInit,
  );

  // تهيئة البلجن
  await _fln.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint('🔔 Local notification tapped. payload=${response.payload}');
      // ممكن هنا مستقبلاً تستدعين handleNotificationTap مع data من الـ payload
    },
  );

  // إنشاء قناة أندرويد (مرة واحدة)
  await _fln
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);
}

/// تهيئة FCM (طلب صلاحيات + listeners)
Future<void> initFCM() async {
  // طلب صلاحية الإشعارات (Android 13+ و iOS)
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  debugPrint('🔔 Notification permission = ${settings.authorizationStatus}');

  // طباعة التوكن (للتأكد من التسجيل)
  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('✅ FCM TOKEN: $token');

  // تسجيل الهاندلر للباكجراوند
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ========================  إشعارات الـ Foreground  ========================
  FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
    final notification = msg.notification;

    // نأخذ العنوان والنص من notification أو من data (لو جايين من PHP فقط كـ data)
    final String title =
        notification?.title ?? msg.data['title']?.toString() ?? '';
    final String body =
        notification?.body ?? msg.data['body']?.toString() ?? '';

    debugPrint('📩 [FG] onMessage data=${msg.data} title=$title body=$body');

    // لو ما فيه أي نص، ما نعرض إشعار
    if (title.isEmpty && body.isEmpty) return;

    // نعرض إشعار محلي فقط على أندرويد (وما يكون Web)
    if (!kIsWeb && Platform.isAndroid) {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      );

      /// لازم الـ id يكون ضمن 32-bit int
      final int notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff);

      await _fln.show(
        notificationId, // ✅ id آمن
        title,
        body,
        details,
        payload: msg.data.toString(), // ممكن نستعمله لاحقاً لفتح شاشة معيّنة
      );
    }
  });

  // ========================  عند فتح الإشعار من tray  ========================
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
    debugPrint('📲 onMessageOpenedApp data: ${msg.data}');
    // هنا تقدرين تستدعين handleNotificationTap(msg.data)
    // لو حابة تفتحين شاشة معيّنة حسب type
  });
}
