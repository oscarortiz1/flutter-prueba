import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Android initialization
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS initialization
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final settings = InitializationSettings(android: android, iOS: ios);

    // Initialize plugin. In test environments the platform implementation
    // may not be available; catch initialization errors and continue.
    try {
      await _plugin.initialize(settings, onDidReceiveNotificationResponse: (response) {
        if (kDebugMode) {
          debugPrint('Notification tapped: ${response.payload}');
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService.init ignored error: $e');
    }

    // Create Android notification channel (required on Android 8.0+)
    const androidChannel = AndroidNotificationChannel(
      'otp_channel',
      'OTP Notifications',
      description: 'Channel for OTP verification codes',
      importance: Importance.max,
    );

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to create notification channel: $e');
    }

    // Request runtime permissions: Android 13+ requires POST_NOTIFICATIONS; iOS requires alert/badge/sound
    if (Platform.isAndroid) {
      // POST_NOTIFICATIONS permission (Android 13+)
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> showOtpNotification(String code, String email) async {
    const androidDetails = AndroidNotificationDetails(
      'otp_channel',
      'OTP',
      channelDescription: 'Channel for OTP codes',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Use a unique id or hash if you want multiple notifications; using 0 will replace previous
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Código OTP',
        'Tu código es: $code',
        details,
        payload: email,
      );
      if (kDebugMode) debugPrint('OTP notification shown for $email with code $code');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to show notification: $e');
    }
  }
}
