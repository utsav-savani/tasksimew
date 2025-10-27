class ApiConstants {
  // Base URLs
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://your-api-url.com/api/v1',
  );

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String getUsers = '/users';
  static const String getUserById = '/users/';
  static const String updateProfile = '/users/profile';

  // Video Call Endpoints
  static const String generateToken = '/video/token';
  static const String callHistory = '/video/history';
  static const String initiateCall = '/video/initiate';
  static const String endCall = '/video/end';

  // Push Notification Endpoints
  static const String updateFCMToken = '/users/fcm-token';
  static const String sendCallNotification = '/video/send-notification';

  // Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
}
