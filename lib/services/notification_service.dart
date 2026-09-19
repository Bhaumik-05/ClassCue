import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  print('========== BACKGROUND FCM MESSAGE ==========');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
  print('============================================');
}

class NotificationService {
  static final NotificationService _instance =
  NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  static final ValueNotifier<Map<String, String>?> pendingNotification =
  ValueNotifier(null);

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'classcue_notifications';

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    _channelId,
    'ClassCue Notifications',
    description: 'Notifications for ClassCue reminders',
    importance: Importance.high,
  );

  bool _initialized = false;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    print('========== NOTIFICATION SERVICE ==========');
    print('NotificationService initialized');

    // Initialize timezone database.
    tz.initializeTimeZones();

    // Set device timezone.
    await _initializeTimezone();

    // Initialize local notifications.
    await _initializeLocalNotifications();

    // Request notification permission.
    await _requestPermission();

    // Request exact alarm permission.
    await _requestExactAlarmPermission();

    // Get FCM token.
    await _getToken();

    // Listen for token refresh.
    _listenForTokenRefresh();

    // Listen for foreground FCM messages.
    _listenForForegroundMessages();

    // Listen for FCM notification taps.
    _listenForNotificationTap();

    _initialized = true;

    print('========== NOTIFICATION SERVICE READY ==========');
  }

  // ============================================================
  // TIMEZONE
  // ============================================================

  Future<void> _initializeTimezone() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();

      print('Device timezone: ${timezoneInfo.identifier}');

      tz.setLocalLocation(
        tz.getLocation(timezoneInfo.identifier),
      );

      print('Timezone initialized successfully');
    } catch (e) {
      print('ERROR initializing timezone: $e');

      // Safe fallback for India.
      tz.setLocalLocation(
        tz.getLocation('Asia/Kolkata'),
      );

      print('Timezone fallback: Asia/Kolkata');
    }
  }

  // ============================================================
  // LOCAL NOTIFICATION INITIALIZATION
  // ============================================================

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        print('========== LOCAL NOTIFICATION TAP ==========');
        print('Payload: ${response.payload}');
        print('============================================');
      },
    );

    final androidPlugin =
    _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);

    print('Local notifications initialized');
  }

  // ============================================================
  // NOTIFICATION PERMISSION
  // ============================================================

  Future<void> _requestPermission() async {
    print('Requesting notification permission...');

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print(
        'Notification permission status: '
            '${settings.authorizationStatus}',
      );

      final androidPlugin =
      _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.requestNotificationsPermission();
    } catch (e) {
      print('ERROR requesting notification permission: $e');
    }
  }

  // ============================================================
  // EXACT ALARM PERMISSION
  // ============================================================

  Future<void> _requestExactAlarmPermission() async {
    try {
      final androidPlugin =
      _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.requestExactAlarmsPermission();

      print('Exact alarm permission requested');
    } catch (e) {
      print('ERROR requesting exact alarm permission: $e');
    }
  }

  // ============================================================
  // FCM TOKEN
  // ============================================================

  Future<void> _getToken() async {
    print('Getting FCM token...');

    try {
      final token = await _messaging.getToken();

      if (token != null) {
        print('==========================================');
        print('FCM TOKEN:');
        print(token);
        print('==========================================');
      } else {
        print('FCM token is NULL');
      }
    } catch (e) {
      print('ERROR getting FCM token: $e');
    }
  }

  void _listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen(
          (newToken) {
        print('========== FCM TOKEN REFRESHED ==========');
        print(newToken);
        print('=========================================');

        _saveRefreshedToken(newToken);
      },
      onError: (error) {
        print('ERROR refreshing FCM token: $error');
      },
    );
  }

  Future<void> _saveRefreshedToken(String newToken) async {
    print('New FCM token received.');
    print('Refreshed token: $newToken');

    // Firestore token update already handled by AuthService.
  }

  // ============================================================
  // FOREGROUND FCM
  // ============================================================

  void _listenForForegroundMessages() {
    print('🔥 FOREGROUND LISTENER REGISTERED 🔥');

    FirebaseMessaging.onMessage.listen(
          (RemoteMessage message) async {
        print('🚨🚨🚨 FOREGROUND NOTIFICATION RECEIVED 🚨🚨🚨');
        print('========== FCM MESSAGE ==========');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');
        print('=================================');

        await _showLocalNotification(message);
      },
      onError: (error) {
        print('ERROR receiving FCM message: $error');
      },
    );
  }

  // ============================================================
  // FCM NOTIFICATION TAP
  // ============================================================

  void _listenForNotificationTap() {
    FirebaseMessaging.onMessageOpenedApp.listen(
          (RemoteMessage message) {
        print('========== NOTIFICATION TAPPED ==========');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');

        final type = message.data['type'];

        print('Notification Type: $type');

        pendingNotification.value = message.data.map(
              (key, value) => MapEntry(
            key,
            value.toString(),
          ),
        );

        if (type == 'assignment') {
          print('➡️ Assignment notification tapped');
        } else if (type == 'class') {
          print('➡️ Class notification tapped');
        } else {
          print('➡️ General notification tapped');
        }

        print('==========================================');
      },
      onError: (error) {
        print('ERROR handling notification tap: $error');
      },
    );
  }

  // ============================================================
  // APP OPENED FROM FCM NOTIFICATION
  // ============================================================

  Future<void> checkInitialMessage() async {
    final message = await _messaging.getInitialMessage();

    if (message != null) {
      print('========== APP OPENED BY NOTIFICATION ==========');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');

      final type = message.data['type'];

      print('Notification Type: $type');

      pendingNotification.value = message.data.map(
            (key, value) => MapEntry(
          key,
          value.toString(),
        ),
      );

      if (type == 'assignment') {
        print('➡️ Assignment notification tapped');
      } else if (type == 'class') {
        print('➡️ Class notification tapped');
      } else {
        print('➡️ General notification tapped');
      }

      print('================================================');
    }
  }

  // ============================================================
  // SHOW FOREGROUND FCM NOTIFICATION
  // ============================================================

  Future<void> _showLocalNotification(
      RemoteMessage message,
      ) async {
    final notification = message.notification;

    if (notification == null) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'ClassCue Notifications',
      channelDescription: 'Notifications for ClassCue reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? 'ClassCue',
      body: notification.body ?? '',
      notificationDetails: notificationDetails,
    );
  }

  // ============================================================
  // CREATE STABLE NOTIFICATION ID
  // ============================================================

  int _notificationId(String assignmentId) {
    // FNV-1a hash.
    // This gives the same notification ID for the same assignment ID
    // across app launches.

    const int offsetBasis = 2166136261;
    const int prime = 16777619;

    int hash = offsetBasis;

    for (final byte in utf8.encode(assignmentId)) {
      hash ^= byte;
      hash = (hash * prime) & 0xFFFFFFFF;
    }

    // Keep it positive and within Android notification ID range.
    return hash & 0x7FFFFFFF;
  }

  // ============================================================
  // SCHEDULE ASSIGNMENT DEADLINE REMINDER
  // ============================================================

  Future<void> scheduleAssignmentReminder({
    required String assignmentId,
    required String title,
    required String subject,
    required DateTime deadline,
  }) async {
    try {
      final notificationId = _notificationId(assignmentId);

      // First cancel any previous reminder for this assignment.
      await _localNotifications.cancel(
        id: notificationId,
      );

      final now = DateTime.now();

      // Deadline already passed.
      if (!deadline.isAfter(now)) {
        print(
          'Assignment "$title" deadline has already passed. '
              'No notification scheduled.',
        );
        return;
      }

      final reminderTime = deadline.subtract(
        const Duration(hours: 24),
      );

      print('==========================================');
      print('SCHEDULING ASSIGNMENT REMINDER');
      print('Assignment: $title');
      print('Subject: $subject');
      print('Deadline: $deadline');
      print('Current time: $now');
      print('24-hour reminder time: $reminderTime');
      print('Notification ID: $notificationId');
      print('==========================================');

      // ----------------------------------------------------------
      // CASE 1:
      // Deadline is LESS THAN 24 HOURS away.
      // Show notification immediately.
      // ----------------------------------------------------------

      if (!reminderTime.isAfter(now)) {
        print(
          'Deadline is within 24 hours. '
              'Showing notification immediately.',
        );

        await _showAssignmentReminderNow(
          notificationId: notificationId,
          title: title,
          subject: subject,
        );

        return;
      }

      // ----------------------------------------------------------
      // CASE 2:
      // Deadline is MORE THAN 24 HOURS away.
      // Schedule for deadline - 24 hours.
      // ----------------------------------------------------------

      final scheduledDate = tz.TZDateTime.from(
        reminderTime,
        tz.local,
      );

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        'ClassCue Notifications',
        channelDescription: 'Notifications for ClassCue reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.zonedSchedule(
        id: notificationId,
        title: 'Assignment Due Tomorrow',
        body: '$title${subject.isNotEmpty ? ' • $subject' : ''}',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'assignment:$assignmentId',
      );

      print(
        '✅ Assignment reminder scheduled successfully '
            'for $scheduledDate',
      );
    } catch (e) {
      print('❌ ERROR scheduling assignment reminder: $e');
    }
  }

  // ============================================================
  // SHOW ASSIGNMENT REMINDER IMMEDIATELY
  // ============================================================

  Future<void> _showAssignmentReminderNow({
    required int notificationId,
    required String title,
    required String subject,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'ClassCue Notifications',
      channelDescription: 'Notifications for ClassCue reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: notificationId,
      title: 'Assignment Due Within 24 Hours',
      body: '$title${subject.isNotEmpty ? ' • $subject' : ''}',
      notificationDetails: notificationDetails,
      payload: 'assignment',
    );

    print('✅ Assignment reminder shown immediately');
  }

  // ============================================================
  // CANCEL ASSIGNMENT REMINDER
  // ============================================================

  Future<void> cancelAssignmentReminder(
      String assignmentId,
      ) async {
    try {
      final notificationId = _notificationId(assignmentId);

      await _localNotifications.cancel(
        id: notificationId,
      );

      print(
        '✅ Assignment reminder cancelled: $assignmentId',
      );
    } catch (e) {
      print(
        '❌ ERROR cancelling assignment reminder: $e',
      );
    }
  }
}