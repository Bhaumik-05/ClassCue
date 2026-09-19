import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// =========================================================
// BACKGROUND FCM HANDLER
// =========================================================

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

// =========================================================
// NOTIFICATION SERVICE
// =========================================================

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // =========================================================
  // ANDROID NOTIFICATION CHANNEL
  // =========================================================

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    'classcue_notifications',
    'ClassCue Notifications',
    description: 'Notifications for ClassCue reminders',
    importance: Importance.high,
  );

  // =========================================================
  // INITIALIZE NOTIFICATION SERVICE
  // =========================================================

  Future<void> initialize() async {
    print('========== NOTIFICATION SERVICE ==========');
    print('NotificationService initialized');

    await _initializeLocalNotifications();
    await _requestPermission();
    await _getToken();

    _listenForTokenRefresh();
    _listenForForegroundMessages();
    _listenForNotificationTap();

    print('========== NOTIFICATION SERVICE READY ==========');
  }

  // =========================================================
  // INITIALIZE LOCAL NOTIFICATIONS
  // =========================================================

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

  // =========================================================
  // REQUEST PERMISSION
  // =========================================================

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

  // =========================================================
  // GET FCM TOKEN
  // =========================================================

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

  // =========================================================
  // TOKEN REFRESH
  // =========================================================

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

  // =========================================================
  // SAVE REFRESHED TOKEN
  // =========================================================

  Future<void> _saveRefreshedToken(String newToken) async {
    print('New FCM token received.');
    print('Refreshed token: $newToken');

    // Firestore token update is already handled
    // by AuthService during signup/login.
    //
    // We can connect automatic token refresh
    // to Firestore later.
  }

  // =========================================================
  // FOREGROUND FCM MESSAGE
  // =========================================================

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

  // =========================================================
  // NOTIFICATION TAP
  // =========================================================

  void _listenForNotificationTap() {
    FirebaseMessaging.onMessageOpenedApp.listen(
          (RemoteMessage message) {
        print('========== NOTIFICATION TAPPED ==========');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');
        print('==========================================');
      },
      onError: (error) {
        print('ERROR handling notification tap: $error');
      },
    );
  }

  // =========================================================
  // CHECK NOTIFICATION THAT OPENED APP
  // =========================================================

  Future<void> checkInitialMessage() async {
    final message = await _messaging.getInitialMessage();

    if (message != null) {
      print('========== APP OPENED BY NOTIFICATION ==========');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
      print('================================================');
    }
  }

  // =========================================================
  // SHOW LOCAL NOTIFICATION
  // =========================================================

  Future<void> _showLocalNotification(
      RemoteMessage message,
      ) async {
    final notification = message.notification;

    if (notification == null) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'classcue_notifications',
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
}