class AppConstants {
  // App Info
  static const String appName = 'Video Call App';
  static const String appVersion = '1.0.0';

  // Agora Configuration
  static const String agoraAppId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: 'aefeac890fad4f76863877b0817c5feb',
  );

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';
  static const String themeKey = 'theme_mode';

  // Hive Boxes
  static const String usersBox = 'users_box';
  static const String settingsBox = 'settings_box';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 20;
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\+?[1-9]\d{1,14}$';

  // Pagination
  static const int itemsPerPage = 20;
  static const int maxRetries = 3;

  // Cache Duration
  static const Duration cacheValidDuration = Duration(hours: 24);
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
}
