import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasksimew/firebase_options.dart';
import '../utils/logger_service.dart';

/// Firebase service for managing Firebase Cloud Messaging (FCM)
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseMessaging? _messaging;
  String? _fcmToken;

  FirebaseMessaging? get messaging => _messaging;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase and FCM
  Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      LoggerService.i('Firebase initialized');

      // Get FCM instance
      _messaging = FirebaseMessaging.instance;

      // Request permission for iOS
      await _requestPermission();

      // Get FCM token
      await _getFCMToken();

      // Listen to token refresh
      _messaging!.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveFCMToken(newToken);
        LoggerService.i('FCM token refreshed: $newToken');
      });

      LoggerService.i('Firebase service initialized successfully');
    } catch (e) {
      LoggerService.e('Failed to initialize Firebase', e);
      rethrow;
    }
  }

  /// Request notification permission (iOS)
  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      LoggerService.i(
        'Notification permission status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        LoggerService.i('User granted permission for notifications');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        LoggerService.i('User granted provisional permission');
      } else {
        LoggerService.w('User declined or has not accepted permission');
      }
    } catch (e) {
      LoggerService.e('Failed to request notification permission', e);
    }
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _messaging!.getToken();

      if (_fcmToken != null) {
        LoggerService.i('FCM Token obtained: $_fcmToken');
        await _saveFCMToken(_fcmToken!);
      }

      return _fcmToken;
    } catch (e) {
      LoggerService.e('Failed to get FCM token', e);
      return null;
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    if (_fcmToken != null) {
      return _fcmToken;
    }
    return await _getFCMToken();
  }

  /// Save FCM token to local storage
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      LoggerService.i('FCM token saved to local storage');
    } catch (e) {
      LoggerService.e('Failed to save FCM token', e);
    }
  }

  /// Get saved FCM token from local storage
  Future<String?> getSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      LoggerService.e('Failed to get saved FCM token', e);
      return null;
    }
  }

  /// Delete FCM token (on logout)
  Future<void> deleteToken() async {
    try {
      await _messaging?.deleteToken();
      _fcmToken = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');

      LoggerService.i('FCM token deleted');
    } catch (e) {
      LoggerService.e('Failed to delete FCM token', e);
    }
  }

  /// Setup message handlers
  void setupMessageHandlers({
    required Function(RemoteMessage) onMessageReceived,
    required Function(RemoteMessage) onMessageOpened,
  }) {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LoggerService.i('Foreground message received: ${message.messageId}');
      LoggerService.i('Title: ${message.notification?.title}');
      LoggerService.i('Body: ${message.notification?.body}');
      LoggerService.i('Data: ${message.data}');

      onMessageReceived(message);
    });

    // Handle background message tap (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      LoggerService.i('Message opened from background: ${message.messageId}');
      onMessageOpened(message);
    });

    // Check for initial message (when app is opened from terminated state)
    _checkInitialMessage(onMessageOpened);
  }

  /// Check if app was opened from a notification
  Future<void> _checkInitialMessage(
    Function(RemoteMessage) onMessageOpened,
  ) async {
    try {
      final initialMessage = await _messaging?.getInitialMessage();

      if (initialMessage != null) {
        LoggerService.i(
          'App opened from notification: ${initialMessage.messageId}',
        );
        onMessageOpened(initialMessage);
      }
    } catch (e) {
      LoggerService.e('Failed to get initial message', e);
    }
  }

  /// Dispose
  void dispose() {
    LoggerService.i('Firebase service disposed');
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background handler
  await Firebase.initializeApp();

  LoggerService.i('Background message received: ${message.messageId}');
  LoggerService.i('Title: ${message.notification?.title}');
  LoggerService.i('Body: ${message.notification?.body}');
  LoggerService.i('Data: ${message.data}');

  // Handle the message (you can show notification, save to DB, etc.)
}
