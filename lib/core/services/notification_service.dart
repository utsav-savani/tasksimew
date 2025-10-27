import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  LoggerService.i('Background message received: ${message.messageId}');
}

/// Service for handling local and push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  // Stream controller for incoming call notifications
  final StreamController<Map<String, dynamic>> _incomingCallController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get incomingCallStream =>
      _incomingCallController.stream;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Check if TEST_MODE - skip Firebase initialization
      final testMode = dotenv.env['TEST_MODE'] == 'true';

      // Initialize Firebase Cloud Messaging (skip in TEST_MODE)
      if (!testMode) {
        try {
          await Firebase.initializeApp();
          LoggerService.i('Firebase initialized successfully');

          // Request notification permissions
          final settings = await _firebaseMessaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            LoggerService.i('User granted notification permission');
          } else {
            LoggerService.w('User declined notification permission');
          }

          // Get FCM token
          _fcmToken = await _firebaseMessaging.getToken();
          LoggerService.i('FCM Token: $_fcmToken');

          // Listen for token refresh
          _firebaseMessaging.onTokenRefresh.listen((newToken) {
            _fcmToken = newToken;
            LoggerService.i('FCM Token refreshed: $newToken');
            // TODO: Send token to backend
          });

          // Handle foreground messages
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

          // Handle notification tap when app is in background/terminated
          FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

          // Check if app was opened from a notification
          final initialMessage = await _firebaseMessaging.getInitialMessage();
          if (initialMessage != null) {
            _handleNotificationTap(initialMessage);
          }

          // Register background message handler
          FirebaseMessaging.onBackgroundMessage(
              firebaseMessagingBackgroundHandler);
        } catch (e) {
          LoggerService.e('Firebase initialization failed', e);
          // Continue without Firebase
        }
      } else {
        LoggerService.i('TEST_MODE: Skipping Firebase initialization');
      }

      // Initialize local notifications (always needed)
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Create Android notification channels
      await _createNotificationChannels();

      _initialized = true;
      LoggerService.i('Notification service initialized');
    } catch (e) {
      LoggerService.e('Failed to initialize notification service', e);
      rethrow;
    }
  }

  /// Handle foreground FCM messages
  void _handleForegroundMessage(RemoteMessage message) {
    LoggerService.i('Foreground FCM message received: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    // Show local notification when app is in foreground
    if (notification != null) {
      showNotificationFromMessage(message);
    }

    // Handle incoming call
    if (data['type'] == 'incoming_call') {
      _incomingCallController.add({
        'callerId': data['caller_id'] ?? '',
        'callerName': data['caller_name'] ?? 'Unknown',
        'channelName': data['channel_name'] ?? '',
      });
    }
  }

  /// Handle FCM notification tap
  void _handleNotificationTap(RemoteMessage message) {
    LoggerService.i('FCM notification tapped: ${message.messageId}');

    final data = message.data;

    // Handle incoming call
    if (data['type'] == 'incoming_call') {
      _incomingCallController.add({
        'callerId': data['caller_id'] ?? '',
        'callerName': data['caller_name'] ?? 'Unknown',
        'channelName': data['channel_name'] ?? '',
      });
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    // Video call notification channel
    const callChannel = AndroidNotificationChannel(
      'video_calls',
      'Video Calls',
      description: 'Notifications for incoming video calls',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('call_ringtone'),
    );

    // General notification channel
    const generalChannel = AndroidNotificationChannel(
      'general',
      'General',
      description: 'General notifications',
      importance: Importance.defaultImportance,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(callChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    LoggerService.i('Notification channels created');
  }

  /// Handle local notification tap
  void _onNotificationResponse(NotificationResponse response) {
    LoggerService.i('Local notification tapped: ${response.id}');
    LoggerService.i('Payload: ${response.payload}');

    // Handle notification tap based on payload
    if (response.payload != null) {
      _handleNotificationAction(response.payload!);
    }
  }

  /// Handle notification action
  void _handleNotificationAction(String payload) {
    // Parse payload and navigate accordingly
    // Payload format: "incoming_call|callerId|callerName|channelName"
    LoggerService.i('Handling notification action: $payload');

    final parts = payload.split('|');
    if (parts.isNotEmpty && parts[0] == 'incoming_call' && parts.length >= 4) {
      _incomingCallController.add({
        'callerId': parts[1],
        'callerName': parts[2],
        'channelName': parts[3],
      });
    }
  }

  /// Show incoming call notification
  Future<void> showCallNotification({
    required String callerId,
    required String callerName,
    required String channelName,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'video_calls',
        'Video Calls',
        channelDescription: 'Notifications for incoming video calls',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        ongoing: true,
        autoCancel: false,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call,
        actions: [
          AndroidNotificationAction(
            'answer',
            'Answer',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'decline',
            'Decline',
            cancelNotification: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'call_ringtone.aiff',
        categoryIdentifier: 'video_call',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Create payload with call info
      final payload = 'incoming_call|$callerId|$callerName|$channelName';

      await _localNotifications.show(
        callerId.hashCode, // Use caller ID as notification ID
        'Incoming Video Call',
        '$callerName is calling...',
        notificationDetails,
        payload: payload,
      );

      LoggerService.i('Call notification shown for: $callerName');
    } catch (e) {
      LoggerService.e('Failed to show call notification', e);
    }
  }

  /// Show general notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'general',
        'General',
        channelDescription: 'General notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const iosDetails = DarwinNotificationDetails();

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      LoggerService.i('Notification shown: $title');
    } catch (e) {
      LoggerService.e('Failed to show notification', e);
    }
  }

  /// Show notification from FCM message
  Future<void> showNotificationFromMessage(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;

      if (notification == null) {
        LoggerService.w('Message has no notification payload');
        return;
      }

      // Check if it's a call notification
      if (data['type'] == 'incoming_call') {
        await showCallNotification(
          callerId: data['caller_id'] ?? '',
          callerName: data['caller_name'] ?? notification.title ?? 'Unknown',
          channelName: data['channel_name'] ?? '',
        );
      } else {
        // Show general notification
        await showNotification(
          id: message.hashCode,
          title: notification.title ?? 'Notification',
          body: notification.body ?? '',
          payload: data.toString(),
        );
      }
    } catch (e) {
      LoggerService.e('Failed to show notification from message', e);
    }
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      LoggerService.i('Notification cancelled: $id');
    } catch (e) {
      LoggerService.e('Failed to cancel notification', e);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      LoggerService.i('All notifications cancelled');
    } catch (e) {
      LoggerService.e('Failed to cancel all notifications', e);
    }
  }

  /// Simulate incoming call notification (for TEST_MODE)
  Future<void> simulateIncomingCall({
    required String callerId,
    required String callerName,
    required String channelName,
  }) async {
    LoggerService.i('Simulating incoming call from $callerName');

    await showCallNotification(
      callerId: callerId,
      callerName: callerName,
      channelName: channelName,
    );

    // Emit to stream
    _incomingCallController.add({
      'callerId': callerId,
      'callerName': callerName,
      'channelName': channelName,
    });
  }

  /// Dispose
  void dispose() {
    _incomingCallController.close();
    LoggerService.i('Notification service disposed');
  }
}
