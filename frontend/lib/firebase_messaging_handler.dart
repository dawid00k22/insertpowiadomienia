import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 🔔 Funkcja globalna dla powiadomień w tle (wymagana przez AOT)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseMessagingHandler._showNotification(message);
}

class FirebaseMessagingHandler {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await _notificationsPlugin.initialize(
    const InitializationSettings(
      android: initializationSettingsAndroid,
    ),
  );

  await _firebaseMessaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  String? token = await _firebaseMessaging.getToken();
  print("FCM Token: $token");

  // 📡 Subskrybuj temat "all"
  await _firebaseMessaging.subscribeToTopic('all');
  print("📡 Subskrybowano temat: all");

  FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}


  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showNotification(message);
  }

  /// 👇 Zmieniamy na `public static` dla użycia z zewnątrz
  static Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    await _notificationsPlugin.show(
      0,
      message.notification?.title ?? 'Nowa wiadomość',
      message.notification?.body ?? 'Masz nowe powiadomienie',
      const NotificationDetails(android: androidPlatformChannelSpecifics),
    );
  }
}
