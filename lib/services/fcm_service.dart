import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize FCM
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted notification permission');

      // Get FCM token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveFCMToken);

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } else {
      debugPrint('User declined notification permission');
    }
  }

  // Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap from local notification
        debugPrint('Local notification tapped: ${response.payload}');
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'congestion_free_channel',
      'Avahanaa Notifications',
      description: 'Notifications for vehicle alerts',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token saved: $token');
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Display notification when app is in foreground
    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'congestion_free_channel',
            'Avahanaa Notifications',
            channelDescription: 'Notifications for vehicle alerts',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['notificationId'],
      );
    }
  }

  // Handle notification tap (when app is in background)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');

    // Navigate to notifications screen
    // You can implement navigation logic here
    // For example: navigatorKey.currentState?.pushNamed('/notifications');
  }

  // Get FCM token
  Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }

  // Refresh and persist current FCM token
  Future<void> refreshFcmToken() async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }
  }

  // Delete FCM token
  Future<void> deleteFCMToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
        await _fcm.deleteToken();
      } catch (e) {
        debugPrint('Error deleting FCM token: $e');
      }
    }
  }

  // Subscribe to topic (optional for future features)
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }
}
