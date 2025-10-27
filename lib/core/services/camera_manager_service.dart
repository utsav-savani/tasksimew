import '../utils/logger_service.dart';

/// Camera types available on mobile devices
enum CameraType {
  front,
  back,
}

/// Represents a camera device
class CameraDevice {
  final String id;
  final String name;
  final CameraType type;

  const CameraDevice({
    required this.id,
    required this.name,
    required this.type,
  });

  @override
  String toString() => 'CameraDevice(id: $id, name: $name, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CameraDevice &&
        other.id == id &&
        other.name == name &&
        other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ type.hashCode;
}

/// Service to manage camera devices
///
/// Note: Agora Flutter SDK has limited camera enumeration APIs on mobile.
/// This service provides a simplified interface for camera management.
/// For mobile devices, cameras are typically limited to front/back.
/// External camera support requires platform-specific implementation.
class CameraManagerService {
  CameraType _currentCameraType = CameraType.back;

  CameraType get currentCameraType => _currentCameraType;

  /// Get available cameras (front and back for mobile)
  List<CameraDevice> getAvailableCameras() {
    // On mobile devices, we typically have front and back cameras
    final cameras = [
      const CameraDevice(
        id: 'back',
        name: 'Back Camera',
        type: CameraType.back,
      ),
      const CameraDevice(
        id: 'front',
        name: 'Front Camera',
        type: CameraType.front,
      ),
    ];

    LoggerService.i('Available cameras: ${cameras.length}');
    return cameras;
  }

  /// Get current camera device
  CameraDevice getCurrentCamera() {
    return _currentCameraType == CameraType.back
        ? const CameraDevice(id: 'back', name: 'Back Camera', type: CameraType.back)
        : const CameraDevice(id: 'front', name: 'Front Camera', type: CameraType.front);
  }

  /// Switch to the other camera (front <-> back)
  /// This is called after using Agora's switchCamera()
  void toggleCameraType() {
    _currentCameraType = _currentCameraType == CameraType.back
        ? CameraType.front
        : CameraType.back;
    LoggerService.i('Camera type toggled to: $_currentCameraType');
  }

  /// Set current camera type manually
  void setCameraType(CameraType type) {
    _currentCameraType = type;
    LoggerService.i('Camera type set to: $type');
  }

  /// Check if a specific camera type is available
  bool isCameraAvailable(CameraType type) {
    // On mobile, both cameras are typically available
    return true;
  }

  /// Reset to default (back camera)
  void reset() {
    _currentCameraType = CameraType.back;
    LoggerService.i('Camera manager reset to back camera');
  }

  /// Dispose
  void dispose() {
    LoggerService.i('CameraManagerService disposed');
  }
}
