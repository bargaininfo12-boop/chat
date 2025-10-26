import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  // Notification channel for chat messages
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'chat_messages', // Must match server channelId
    'Chat Messages',
    description: 'Incoming chat notifications',
    importance: Importance.high,
    playSound: true,
  );

  // Initialize notification service
  static Future<void> initialize() async {
    try {
      // Initialize Firebase (only if not already initialized)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Initialize Local Notifications Plugin
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_stat_notification'); // Use proper notification icon

      const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔔 Permission status: ${settings.authorizationStatus}');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap (when the app is in background or terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle initial message (when app is launched via notification)
      _handleInitialMessage();

      print('✅ Firebase Notification Service initialized successfully');

    } catch (e) {
      print('❌ Error initializing Firebase Notification Service: $e');
    }
  }

  // Register FCM token for current user
  static Future<void> registerFcmToken(String uid) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null) {
        print('❌ Failed to get FCM token');
        return;
      }

      print('📱 FCM Token: ${token.substring(0, 20)}...');

      // Store token in Firestore subcollection
      final tokenRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token);

      await tokenRef.set({
        'token': token,
        'platform': 'android', // or 'ios' based on platform
        'updatedAt': FieldValue.serverTimestamp(),
        'deviceInfo': 'Flutter App', // You can add more device info if needed
      }, SetOptions(merge: true));

      print('✅ FCM token registered successfully');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('🔄 Token refreshed: ${newToken.substring(0, 20)}...');

        final newTokenRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('fcmTokens')
            .doc(newToken);

        await newTokenRef.set({
          'token': newToken,
          'platform': 'android',
          'updatedAt': FieldValue.serverTimestamp(),
          'deviceInfo': 'Flutter App',
        }, SetOptions(merge: true));
      });

    } catch (e) {
      print('❌ Error registering FCM token: $e');
    }
  }

  // Unregister current FCM token (call on logout)
  static Future<void> unregisterCurrentToken(String uid) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token)
          .delete();

      print('✅ FCM token unregistered successfully');
    } catch (e) {
      print('❌ Error unregistering FCM token: $e');
    }
  }

  // Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground message received:');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');

    if (message.notification != null) {
      _showLocalNotification(message);
    }
  }

  // Handle message when app is opened from notification
  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('🎯 App opened from notification:');
    print('   Data: ${message.data}');

    _handleNotificationNavigation(message.data);
  }

  // Handle initial message (when app is launched from terminated state)
  static Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      print('🚀 App launched from notification:');
      print('   Data: ${initialMessage.data}');

      // Add a delay to ensure the app is fully initialized
      Future.delayed(const Duration(seconds: 1), () {
        _handleNotificationNavigation(initialMessage.data);
      });
    }
  }

  // Show local notification for foreground messages
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      // Create unique notification ID based on timestamp
      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'chat_messages', // Must match channel ID
        'Chat Messages',
        channelDescription: 'Incoming chat notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_notification',
        color: Color(0xFF2196F3), // Blue color
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Create payload with conversation data
      final String payload = message.data['conversationId'] ?? '';

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        message.notification?.title,
        message.notification?.body,
        details,
        payload: payload,
      );

      print('✅ Local notification shown');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('🎯 Notification tapped:');
    print('   Payload: ${response.payload}');

    if (response.payload != null && response.payload!.isNotEmpty) {
      // Navigate to conversation screen
      final Map<String, dynamic> data = {'conversationId': response.payload};
      _handleNotificationNavigation(data);
    }
  }

  // Handle navigation based on notification data
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final String? conversationId = data['conversationId'];

    if (conversationId != null && conversationId.isNotEmpty) {
      print('🧭 Navigating to conversation: $conversationId');

      // TODO: Add your navigation logic here
      // Example:
      // Get.toNamed('/conversation', arguments: conversationId);
      // or
      // Navigator.pushNamed(context, '/conversation', arguments: conversationId);

      // For now, just print
      print('📍 Should navigate to conversation screen with ID: $conversationId');
    }
  }

  // Background message handler (must be top-level function)
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    print('📨 Background message received: ${message.notification?.title}');
    // Background messages are automatically handled by the system
    // You can add additional logic here if needed
  }
}
