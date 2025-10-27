class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (Status Code: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

class AuthenticationException implements Exception {
  final String message;

  AuthenticationException({required this.message});

  @override
  String toString() => 'AuthenticationException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? errors;

  ValidationException({
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ValidationException: $message';
}

class PermissionException implements Exception {
  final String message;

  PermissionException({required this.message});

  @override
  String toString() => 'PermissionException: $message';
}

class AgoraException implements Exception {
  final String message;
  final int? errorCode;

  AgoraException({
    required this.message,
    this.errorCode,
  });

  @override
  String toString() => 'AgoraException: $message (Error Code: $errorCode)';
}
