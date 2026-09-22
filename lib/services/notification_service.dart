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

  Future<void>? _initFuture;

  /// Safe to call many times / concurrently.
  Future<void> initialize() => _initFuture ??= _doInitialize().whenComplete(() {
        // Allow a retry if initialisation failed.
        if (!_initialized) _initFuture = null;
      });

  Future<void> _doInitialize() async {
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

    // Get FCM token.
    await _getToken().timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );

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

  int _notificationId(String value) {
    // FNV-1a hash.
    // Same input always produces the same notification ID.

    const int offsetBasis = 2166136261;
    const int prime = 16777619;

    int hash = offsetBasis;

    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * prime) & 0xFFFFFFFF;
    }

    return hash & 0x7FFFFFFF;
  }

  // ============================================================
  // ASSIGNMENT NOTIFICATION ID
  // ============================================================

  int _assignmentNotificationId(String assignmentId) {
    return _notificationId('assignment:$assignmentId');
  }

  // ============================================================
  // CLASS NOTIFICATION ID
  // ============================================================

  int _classNotificationId(String classId) {
    return _notificationId('class:$classId');
  }

  // ============================================================
  // SCHEDULE ASSIGNMENT DEADLINE REMINDER
  // ============================================================

  /// Exact alarms need a permission that Android can deny. Without this
  /// fallback the reminder was silently never scheduled.
  Future<AndroidScheduleMode> _scheduleMode() async {
    try {
      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final canExact = await android?.canScheduleExactNotifications() ?? false;
      return canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  /// Removes every scheduled reminder (used on logout).
  Future<void> cancelAllReminders() async {
    try {
      await initialize();
      await _localNotifications.cancelAll();
    } catch (e) {
      print('ERROR cancelling all reminders: $e');
    }
  }

  Future<void> scheduleAssignmentReminder({
    required String assignmentId,
    required String title,
    required String subject,
    required DateTime deadline,
    bool notifyIfDue = true,
  }) async {
    try {
      await initialize();
      final notificationId =
      _assignmentNotificationId(assignmentId);

      // Cancel any previous reminder for this assignment.
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
      // Deadline is less than 24 hours away.
      // ----------------------------------------------------------

      if (!reminderTime.isAfter(now)) {
        print(
          'Deadline is within 24 hours. '
              'Showing notification immediately.',
        );

        if (notifyIfDue) {
          await _showAssignmentReminderNow(
            notificationId: notificationId,
            title: title,
            subject: subject,
          );
        }

        return;
      }

      // ----------------------------------------------------------
      // Deadline is more than 24 hours away.
      // ----------------------------------------------------------

      final scheduledDate = tz.TZDateTime.from(
        reminderTime,
        tz.local,
      );

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

      await _localNotifications.zonedSchedule(
        id: notificationId,
        title: 'Assignment Due Tomorrow',
        body: '$title${subject.isNotEmpty ? ' • $subject' : ''}',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: await _scheduleMode(),
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
      await initialize();
      final notificationId =
      _assignmentNotificationId(assignmentId);

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

  // ============================================================
  // PARSE CLASS TIME
  // ============================================================

  List<int>? _parseTime(String time) {
    try {
      final parts = time.split(':');

      if (parts.length != 2) {
        return null;
      }

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59) {
        return null;
      }

      return [hour, minute];
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // CONVERT DAY NAME TO WEEKDAY
  // ============================================================

  int? _weekdayFromString(String dayOfWeek) {
    switch (dayOfWeek.trim().toUpperCase()) {
      case 'MONDAY':
        return DateTime.monday;

      case 'TUESDAY':
        return DateTime.tuesday;

      case 'WEDNESDAY':
        return DateTime.wednesday;

      case 'THURSDAY':
        return DateTime.thursday;

      case 'FRIDAY':
        return DateTime.friday;

      case 'SATURDAY':
        return DateTime.saturday;

      case 'SUNDAY':
        return DateTime.sunday;

      default:
        return null;
    }
  }

  // ============================================================
  // GET NEXT CLASS START
  // ============================================================

  tz.TZDateTime? _getNextClassStart({
    required String dayOfWeek,
    required String startTime,
  }) {
    final weekday = _weekdayFromString(dayOfWeek);
    final time = _parseTime(startTime);

    if (weekday == null || time == null) {
      return null;
    }

    final now = tz.TZDateTime.now(tz.local);

    // Create today's class time.
    var classStart = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time[0],
      time[1],
    );

    // Calculate days until requested weekday.
    var daysUntilClass = weekday - now.weekday;

    if (daysUntilClass < 0) {
      daysUntilClass += 7;
    }

    // Move to the requested weekday.
    classStart = classStart.add(
      Duration(days: daysUntilClass),
    );

    // IMPORTANT:
    //
    // We only move the class to next week when the CLASS itself
    // has already started.
    //
    // Example:
    //
    // Current = 8:02
    // Class   = 8:08
    //
    // classStart = 8:08
    //
    // Since 8:08 is still in the future, we keep today's class.
    if (!classStart.isAfter(now)) {
      classStart = classStart.add(
        const Duration(days: 7),
      );
    }

    return classStart;
  }

  // ============================================================
  // SCHEDULE CLASS REMINDER
  //
  // Reminder is 10 minutes before class.
  // The notification repeats every week.
  // ============================================================

  Future<void> scheduleClassReminder({
    required String classId,
    required String subjectName,
    required String startTime,
    required String dayOfWeek,
  }) async {
    try {
      await initialize();
      final notificationId =
      _classNotificationId(classId);

      // Cancel an existing reminder for this class.
      await _localNotifications.cancel(
        id: notificationId,
      );

      // Find the next class occurrence.
      final classStart = _getNextClassStart(
        dayOfWeek: dayOfWeek,
        startTime: startTime,
      );

      if (classStart == null) {
        print(
          '❌ Invalid class day/time. '
              'Class reminder was not scheduled.',
        );
        return;
      }

      // Calculate reminder time.
      final reminderTime = classStart.subtract(
        const Duration(minutes: 10),
      );

      final now = tz.TZDateTime.now(tz.local);

      print('==========================================');
      print('SCHEDULING CLASS REMINDER');
      print('Class ID: $classId');
      print('Subject: $subjectName');
      print('Day: $dayOfWeek');
      print('Start Time: $startTime');
      print('Current Time: $now');
      print('Class Start: $classStart');
      print('Reminder Time: $reminderTime');
      print('Notification ID: $notificationId');
      print('==========================================');

      // ----------------------------------------------------------
      // IMPORTANT:
      //
      // If the reminder time is still in the future,
      // schedule it for THIS week's class.
      //
      // Example:
      //
      // Current = 8:02
      // Class   = 8:08
      // Reminder = 8:03
      //
      // 8:03 is still in the future.
      // Therefore notification will be scheduled for 8:03 TODAY.
      // ----------------------------------------------------------

      tz.TZDateTime scheduledReminder = reminderTime;

      // ----------------------------------------------------------
      // If the 10-minute reminder has already passed,
      // schedule next week's reminder.
      //
      // Example:
      //
      // Current = 8:02
      // Class   = 8:04
      // Reminder = 7:59
      //
      // 7:59 already passed.
      // Therefore schedule next week's reminder.
      // ----------------------------------------------------------

      if (!scheduledReminder.isAfter(now)) {
        scheduledReminder = scheduledReminder.add(
          const Duration(days: 7),
        );

        print(
          'Reminder time already passed. '
              'Scheduling next week.',
        );
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

      // Schedule the notification.
      //
      // dayOfWeekAndTime makes it repeat every week
      // on the same weekday and time.
      await _localNotifications.zonedSchedule(
        id: notificationId,
        title: 'Class Starting Soon',
        body: '$subjectName starts in 10 minutes. Turn on Silent/DND mode.',
        scheduledDate: scheduledReminder,
        notificationDetails: notificationDetails,
        androidScheduleMode: await _scheduleMode(),
        matchDateTimeComponents:
        DateTimeComponents.dayOfWeekAndTime,
        payload: 'class:$classId',
      );

      print(
        '✅ Class reminder scheduled successfully '
            'for $scheduledReminder',
      );
    } catch (e) {
      print(
        '❌ ERROR scheduling class reminder: $e',
      );
    }
  }

  // ============================================================
  // CANCEL CLASS REMINDER
  // ============================================================

  Future<void> cancelClassReminder(
      String classId,
      ) async {
    try {
      await initialize();
      final notificationId =
      _classNotificationId(classId);

      await _localNotifications.cancel(
        id: notificationId,
      );

      print(
        '✅ Class reminder cancelled: $classId',
      );
    } catch (e) {
      print(
        '❌ ERROR cancelling class reminder: $e',
      );
    }
  }
}