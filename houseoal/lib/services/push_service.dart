import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:housepal/services/auth_service.dart';
import 'firestore_service.dart';

class PushService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNoti =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'housepal_notifications',
    'HousePal Notifications',
    description: 'Thông báo HousePal',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    // Local notification init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNoti.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
      await _localNoti.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveFcmToken(token);
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
        if (msg.notification != null) {
          _showLocalNotification(msg);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
        // TODO: điều hướng khi click notification (nếu cần)
      });

      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        // app mở từ notification
      }
    }
  }

  static Future<void> _saveFcmToken(String token) async {
    final currentUserId = await AuthService.getFirebaseUserId();
    if (currentUserId != null && currentUserId.isNotEmpty) {
      await FirestoreService.updateUser(currentUserId, {
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> showNotificationFromData({
    required String title,
    required String body,
  }) async {
    await _localNoti.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'HousePal';
    final body = message.notification?.body ?? '';
    await showNotificationFromData(title: title, body: body);
  }

  static Future<void> updateTokenIfNeeded() async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveFcmToken(token);
    }
  }
}
