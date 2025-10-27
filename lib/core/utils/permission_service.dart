import 'package:permission_handler/permission_handler.dart';
import '../error/exceptions.dart';
import 'logger_service.dart';

class PermissionService {
  // Request Camera Permission
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();

      if (status.isGranted) {
        LoggerService.i('Camera permission granted');
        return true;
      } else if (status.isDenied) {
        LoggerService.w('Camera permission denied');
        throw PermissionException(
          message: 'Camera permission is required for video calls',
        );
      } else if (status.isPermanentlyDenied) {
        LoggerService.e('Camera permission permanently denied');
        throw PermissionException(
          message: 'Camera permission is permanently denied. Please enable it in settings.',
        );
      }

      return false;
    } catch (e) {
      LoggerService.e('Error requesting camera permission', e);
      rethrow;
    }
  }

  // Request Microphone Permission
  static Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();

      if (status.isGranted) {
        LoggerService.i('Microphone permission granted');
        return true;
      } else if (status.isDenied) {
        LoggerService.w('Microphone permission denied');
        throw PermissionException(
          message: 'Microphone permission is required for video calls',
        );
      } else if (status.isPermanentlyDenied) {
        LoggerService.e('Microphone permission permanently denied');
        throw PermissionException(
          message: 'Microphone permission is permanently denied. Please enable it in settings.',
        );
      }

      return false;
    } catch (e) {
      LoggerService.e('Error requesting microphone permission', e);
      rethrow;
    }
  }

  // Request Both Camera and Microphone Permissions
  static Future<bool> requestVideoCallPermissions() async {
    try {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final cameraStatus = statuses[Permission.camera];
      final micStatus = statuses[Permission.microphone];

      if (cameraStatus!.isGranted && micStatus!.isGranted) {
        LoggerService.i('All video call permissions granted');
        return true;
      }

      if (cameraStatus.isPermanentlyDenied || micStatus!.isPermanentlyDenied) {
        LoggerService.e('Video call permissions permanently denied');
        throw PermissionException(
          message: 'Camera and microphone permissions are permanently denied. Please enable them in settings.',
        );
      }

      if (cameraStatus.isDenied || micStatus.isDenied) {
        LoggerService.w('Video call permissions denied');
        throw PermissionException(
          message: 'Camera and microphone permissions are required for video calls',
        );
      }

      return false;
    } catch (e) {
      LoggerService.e('Error requesting video call permissions', e);
      rethrow;
    }
  }

  // Check if Camera Permission is Granted
  static Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  // Check if Microphone Permission is Granted
  static Future<bool> isMicrophonePermissionGranted() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  // Check if All Video Call Permissions are Granted
  static Future<bool> areVideoCallPermissionsGranted() async {
    final cameraGranted = await isCameraPermissionGranted();
    final micGranted = await isMicrophonePermissionGranted();
    return cameraGranted && micGranted;
  }

  // Open App Settings
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}
