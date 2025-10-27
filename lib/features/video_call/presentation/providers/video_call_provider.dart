import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/utils/logger_service.dart';
import '../../data/datasources/agora_service.dart';
import '../../domain/entities/call_entity.dart';
import '../../domain/repositories/video_call_repository.dart';

enum VideoCallStatus { idle, connecting, connected, disconnected, error }

class VideoCallProvider extends ChangeNotifier {
  final VideoCallRepository _videoCallRepository;
  final AgoraService _agoraService;

  VideoCallProvider({
    required VideoCallRepository videoCallRepository,
    required AgoraService agoraService,
  }) : _videoCallRepository = videoCallRepository,
       _agoraService = agoraService;

  VideoCallStatus _status = VideoCallStatus.idle;
  CallEntity? _currentCall;
  String? _errorMessage;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isScreenSharing = false; // Local screen sharing state
  final bool _isRemoteScreenSharing = false; // Remote screen sharing state
  int? _screenShareUid;
  DateTime? _callStartTime;
  int _callDuration = 0;

  VideoCallStatus get status => _status;
  CallEntity? get currentCall => _currentCall;
  String? get errorMessage => _errorMessage;
  int? get remoteUid => _remoteUid;
  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isScreenSharing => _isScreenSharing;
  bool get isRemoteScreenSharing =>
      _isRemoteScreenSharing; // Expose remote screen share state
  int? get screenShareUid => _screenShareUid;
  int get callDuration => _callDuration;
  RtcEngine? get engine => _agoraService.engine;

  // Initialize Agora
  Future<void> initializeAgora() async {
    try {
      // Initialize Agora engine
      await _agoraService.initialize();

      // Setup event handlers immediately after initialization
      _setupEventHandlers();

      // Verify engine is ready
      if (_agoraService.engine == null || !_agoraService.isInitialized) {
        throw Exception('Agora engine failed to initialize properly');
      }

      LoggerService.i('Agora initialized and ready');
    } catch (e) {
      _errorMessage = e.toString();
      _status = VideoCallStatus.error;
      LoggerService.e('Failed to initialize Agora', e);
      notifyListeners();
      rethrow;
    }
  }

  // Setup Agora event handlers
  void _setupEventHandlers() {
    _agoraService.registerEventHandlers(
      onUserJoined: (connection, remoteUid, elapsed) {
        LoggerService.i('Remote user joined: $remoteUid');
        _remoteUid = remoteUid;
        _status = VideoCallStatus.connected;
        _callStartTime = DateTime.now();
        notifyListeners();
      },
      onUserOffline: (connection, remoteUid, reason) {
        LoggerService.i('Remote user offline: $remoteUid');
        _remoteUid = null;
        notifyListeners();
      },
      onLeaveChannel: (connection, stats) {
        LoggerService.i('Left channel');
        _status = VideoCallStatus.disconnected;
        notifyListeners();
      },
      onError: (err, msg) {
        LoggerService.e('Agora error: $msg');
        LoggerService.e('Agora error: $err');
        _errorMessage = msg;
        _status = VideoCallStatus.error;
        notifyListeners();
      },
      onScreenShareStarted: (uid) {
        LoggerService.i('Screen share started from uid: $uid');
        _screenShareUid = uid;
        notifyListeners();
      },
      onScreenShareStopped: (uid) {
        LoggerService.i('Screen share stopped from uid: $uid');
        _screenShareUid = null;
        notifyListeners();
      },
    );
  }

  // Start call
  Future<void> startCall({
    required String receiverId,
    required String receiverName,
    required String channelName,
    required String userId,
  }) async {
    _status = VideoCallStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      final testMode = dotenv.env['TEST_MODE'] == 'true';

      if (testMode) {
        // TEST MODE: Skip backend API calls and join directly with null token
        LoggerService.i(
          'TEST_MODE: Skipping backend API, joining channel directly',
        );

        // Create a mock call entity
        _currentCall = CallEntity(
          callId: 'test_${DateTime.now().millisecondsSinceEpoch}',
          callerId: userId,
          callerName: 'Test User',
          receiverId: receiverId,
          receiverName: receiverName,
          channelName: channelName,
          status: CallStatus.connected,
          startTime: DateTime.now(),
        );

        try {
          // Join Agora channel with null token (for testing without token authentication)
          // Note: This requires the Agora project to have "App Certificate" disabled
          await _agoraService.joinChannel(
            token: null, // Null token for TEST_MODE
            channelName: channelName,
            uid: int.parse(userId),
          );

          // In TEST_MODE, mark as connected immediately since we might be testing alone
          _status = VideoCallStatus.connected;
          _callStartTime = DateTime.now();
          notifyListeners();

          LoggerService.i('Call started successfully in TEST_MODE');
        } catch (e) {
          LoggerService.e('Failed to join channel in TEST_MODE', e);
          LoggerService.w(
            'Make sure your Agora project has "App Certificate" disabled for testing',
          );
          rethrow;
        }
      } else {
        // PRODUCTION MODE: Use backend API
        // Initiate call on backend
        final callResult = await _videoCallRepository.initiateCall(
          receiverId: receiverId,
          channelName: channelName,
        );

        await callResult.fold(
          (failure) {
            _status = VideoCallStatus.error;
            _errorMessage = failure.message;
            notifyListeners();
            throw Exception(failure.message);
          },
          (call) async {
            _currentCall = call;

            // Generate Agora token
            final tokenResult = await _videoCallRepository.generateAgoraToken(
              channelName: channelName,
              userId: userId,
            );

            await tokenResult.fold(
              (failure) {
                _status = VideoCallStatus.error;
                _errorMessage = failure.message;
                notifyListeners();
                throw Exception(failure.message);
              },
              (token) async {
                // Join Agora channel
                await _agoraService.joinChannel(
                  token: token,
                  channelName: channelName,
                  uid: int.parse(userId),
                );

                LoggerService.i('Call started successfully');
              },
            );
          },
        );
      }
    } catch (e) {
      _status = VideoCallStatus.error;
      _errorMessage = e.toString();
      LoggerService.e('Failed to start call', e);
      notifyListeners();
    }
  }

  // End call
  Future<void> endCall() async {
    try {
      final testMode = dotenv.env['TEST_MODE'] == 'true';

      if (_callStartTime != null) {
        _callDuration = DateTime.now().difference(_callStartTime!).inSeconds;
      }

      // Leave Agora channel
      await _agoraService.leaveChannel();

      // End call on backend (skip in TEST_MODE)
      if (_currentCall != null && !testMode) {
        await _videoCallRepository.endCall(
          callId: _currentCall!.callId,
          duration: _callDuration,
        );
      } else if (testMode) {
        LoggerService.i('TEST_MODE: Skipping backend API for ending call');
      }

      _status = VideoCallStatus.disconnected;
      _remoteUid = null;
      _callStartTime = null;
      LoggerService.i('Call ended. Duration: $_callDuration seconds');
      notifyListeners();
    } catch (e) {
      LoggerService.e('Failed to end call', e);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Toggle microphone
  Future<void> toggleMicrophone() async {
    _isMuted = !_isMuted;
    await _agoraService.toggleMicrophone(_isMuted);
    notifyListeners();
  }

  // Toggle camera
  Future<void> toggleCamera() async {
    _isCameraOff = !_isCameraOff;
    await _agoraService.toggleCamera(_isCameraOff);
    notifyListeners();
  }

  // Switch camera
  Future<void> switchCamera() async {
    await _agoraService.switchCamera();
  }

  // Toggle screen sharing
  Future<void> toggleScreenShare() async {
    try {
      if (_isScreenSharing) {
        await _agoraService.stopScreenShare();
        _isScreenSharing = false;
        LoggerService.i('Screen sharing stopped');
      } else {
        await _agoraService.startScreenShare();
        _isScreenSharing = true;
        LoggerService.i('Screen sharing started');
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      LoggerService.e('Failed to toggle screen share', e);
      notifyListeners();
    }
  }

  // Cleanup
  @override
  void dispose() {
    _agoraService.dispose();
    super.dispose();
  }
}
