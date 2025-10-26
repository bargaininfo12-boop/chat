import 'package:bargain/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

/// Instance for local notifications.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Background message handler.
/// This function must be a top-level function.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Process the message as required.
  print('Background message received: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  NotificationService() {
    _initFCM();
    _configureForegroundListener();
  }

  Future<void> _initFCM() async {
    // Request notification permissions (for iOS and Android)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Check if permission is granted.
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Optionally get and print the FCM token.
      String? token = await _messaging.getToken();
      print('FCM Token: $token');
    } else {
      print('Notification permissions not granted.');
    }
  }

  void _configureForegroundListener() {
    // Listen for messages while the app is in the foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.messageId}');
      _showLocalNotification(message);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // If both notification and android details are available, display the local notification.
    if (notification != null && android != null) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'channel_id', // Channel ID
        'channel_name', // Channel name
        channelDescription: 'channel description',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );
      const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
      );
    }
  }
}
