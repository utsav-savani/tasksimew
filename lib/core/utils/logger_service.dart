import 'package:logger/logger.dart';

class LoggerService {
  static Logger? _instance;

  static Logger get instance {
    _instance ??= Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: Level.debug,
    );
    return _instance!;
  }

  // Debug log
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.d(message, error: error, stackTrace: stackTrace);
  }

  // Info log
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.i(message, error: error, stackTrace: stackTrace);
  }

  // Warning log
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.w(message, error: error, stackTrace: stackTrace);
  }

  // Error log
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.e(message, error: error, stackTrace: stackTrace);
  }

  // Fatal log
  static void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.f(message, error: error, stackTrace: stackTrace);
  }
}
