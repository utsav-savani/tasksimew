import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/logger_service.dart';

class AgoraService {
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isScreenSharing = false;

  RtcEngine? get engine => _engine;
  bool get isInitialized => _isInitialized;
  bool get isScreenSharing => _isScreenSharing;

  // Initialize Agora Engine
  Future<void> initialize() async {
    if (_isInitialized && _engine != null) {
      LoggerService.i('Agora engine already initialized');
      return;
    }

    try {
      // Request permissions
      await _requestPermissions();

      // Create RTC engine
      _engine = createAgoraRtcEngine();

      // Initialize with proper context
      await _engine!.initialize(
        RtcEngineContext(
          appId: AppConstants.agoraAppId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // Enable video module
      await _engine!.enableVideo();

      // Enable audio module
      await _engine!.enableAudio();

      // Set video encoding configuration for better quality
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 0,
        ),
      );

      _isInitialized = true;
      LoggerService.i('Agora engine initialized successfully');
    } catch (e) {
      _isInitialized = false;
      _engine = null;
      LoggerService.e('Failed to initialize Agora engine', e);
      throw AgoraException(message: 'Failed to initialize Agora: ${e.toString()}');
    }
  }

  // Request camera and microphone permissions
  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final cameraStatus = statuses[Permission.camera];
    final micStatus = statuses[Permission.microphone];

    if (cameraStatus != PermissionStatus.granted ||
        micStatus != PermissionStatus.granted) {
      throw PermissionException(
        message: 'Camera and microphone permissions are required',
      );
    }
  }

  // Join channel
  Future<void> joinChannel({
    String? token, // Made nullable for TEST_MODE
    required String channelName,
    required int uid,
  }) async {
    if (!_isInitialized || _engine == null) {
      throw AgoraException(message: 'Agora engine not initialized');
    }

    try {
      // Use empty string if token is null (for testing without App Certificate)
      final effectiveToken = token ?? '';

      await _engine!.joinChannel(
        token: effectiveToken,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      LoggerService.i('Joined channel: $channelName with ${token == null ? "no token (TEST_MODE)" : "token"}');
    } catch (e) {
      LoggerService.e('Failed to join channel', e);
      throw AgoraException(message: 'Failed to join channel: ${e.toString()}');
    }
  }

  // Leave channel
  Future<void> leaveChannel() async {
    if (!_isInitialized || _engine == null) return;

    try {
      await _engine!.leaveChannel();
      LoggerService.i('Left channel');
    } catch (e) {
      LoggerService.e('Failed to leave channel', e);
      throw AgoraException(message: 'Failed to leave channel: ${e.toString()}');
    }
  }

  // Switch camera
  Future<void> switchCamera() async {
    if (!_isInitialized || _engine == null) return;

    try {
      await _engine!.switchCamera();
      LoggerService.i('Camera switched');
    } catch (e) {
      LoggerService.e('Failed to switch camera', e);
    }
  }

  // Toggle microphone
  Future<void> toggleMicrophone(bool mute) async {
    if (!_isInitialized || _engine == null) return;

    try {
      await _engine!.muteLocalAudioStream(mute);
      LoggerService.i('Microphone ${mute ? 'muted' : 'unmuted'}');
    } catch (e) {
      LoggerService.e('Failed to toggle microphone', e);
    }
  }

  // Toggle camera
  Future<void> toggleCamera(bool disable) async {
    if (!_isInitialized || _engine == null) return;

    try {
      // Use enableLocalVideo to actually turn the camera on/off
      await _engine!.enableLocalVideo(!disable);

      // Also mute the stream to stop sending video
      await _engine!.muteLocalVideoStream(disable);

      LoggerService.i('Camera ${disable ? 'disabled' : 'enabled'}');
    } catch (e) {
      LoggerService.e('Failed to toggle camera', e);
    }
  }

  // Start screen sharing
  Future<void> startScreenShare() async {
    if (!_isInitialized || _engine == null) {
      throw AgoraException(message: 'Agora engine not initialized');
    }

    if (_isScreenSharing) {
      LoggerService.w('Screen sharing already active');
      return;
    }

    try {
      await _engine!.startScreenCapture(
        const ScreenCaptureParameters2(
          captureAudio: true,
          captureVideo: true,
        ),
      );

      // Update channel media options to publish screen share
      await _engine!.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishScreenTrack: true,
          publishCameraTrack: true,
          publishScreenCaptureAudio: true,
          publishScreenCaptureVideo: true,
        ),
      );

      _isScreenSharing = true;
      LoggerService.i('Screen sharing started');
    } catch (e) {
      LoggerService.e('Failed to start screen sharing', e);
      throw AgoraException(message: 'Failed to start screen sharing: ${e.toString()}');
    }
  }

  // Stop screen sharing
  Future<void> stopScreenShare() async {
    if (!_isInitialized || _engine == null) return;

    if (!_isScreenSharing) {
      return;
    }

    try {
      await _engine!.stopScreenCapture();

      // Update channel media options to stop publishing screen share
      await _engine!.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishScreenTrack: false,
          publishScreenCaptureAudio: false,
          publishScreenCaptureVideo: false,
        ),
      );

      _isScreenSharing = false;
      LoggerService.i('Screen sharing stopped');
    } catch (e) {
      LoggerService.e('Failed to stop screen sharing', e);
      throw AgoraException(message: 'Failed to stop screen sharing: ${e.toString()}');
    }
  }

  // Toggle screen sharing
  Future<void> toggleScreenShare() async {
    if (_isScreenSharing) {
      await stopScreenShare();
    } else {
      await startScreenShare();
    }
  }

  // Set up event handlers
  void registerEventHandlers({
    Function(RtcConnection connection, int remoteUid, int elapsed)? onUserJoined,
    Function(RtcConnection connection, int remoteUid, UserOfflineReasonType reason)? onUserOffline,
    Function(RtcConnection connection, RtcStats stats)? onLeaveChannel,
    Function(ErrorCodeType err, String msg)? onError,
    Function(int uid)? onScreenShareStarted,
    Function(int uid)? onScreenShareStopped,
  }) {
    if (!_isInitialized || _engine == null) return;

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          LoggerService.i('Join channel success: ${connection.channelId}');
        },
        onUserJoined: onUserJoined,
        onUserOffline: onUserOffline,
        onLeaveChannel: onLeaveChannel,
        onError: onError,
        // Detect when remote user's video state changes
        onRemoteVideoStateChanged: (connection, remoteUid, state, reason, elapsed) {
          LoggerService.i('Remote video state changed - UID: $remoteUid, State: $state, Reason: $reason');

          if (state == RemoteVideoState.remoteVideoStateStarting) {
            LoggerService.i('Remote video started: $remoteUid');
          } else if (state == RemoteVideoState.remoteVideoStateStopped) {
            LoggerService.i('Remote video stopped: $remoteUid');
          }
        },
        // NEW: Detect screen share specifically
        onVideoPublishStateChanged: (source, channel, oldState, newState, elapseSinceLastState) {
          LoggerService.i('Video publish state changed - Source: $source, Channel: $channel, Old: $oldState, New: $newState');

          if (source == VideoSourceType.videoSourceScreen) {
            if (newState == StreamPublishState.pubStatePublished) {
              LoggerService.i('Screen share publishing started');
            } else if (newState == StreamPublishState.pubStateNoPublished ||
                       newState == StreamPublishState.pubStateIdle) {
              LoggerService.i('Screen share publishing stopped/changed');
            }
          }
        },
      ),
    );
  }

  // Dispose Agora engine
  Future<void> dispose() async {
    if (_engine != null) {
      try {
        await _engine!.leaveChannel();
        await _engine!.release();
        _engine = null;
        _isInitialized = false;
        LoggerService.i('Agora engine disposed');
      } catch (e) {
        LoggerService.e('Failed to dispose Agora engine', e);
      }
    }
  }
}
