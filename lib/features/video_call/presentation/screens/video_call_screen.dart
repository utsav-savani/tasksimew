import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../users/domain/entities/user_list_entity.dart';
import '../providers/video_call_provider.dart';
import '../widgets/call_control_button.dart';

class VideoCallScreen extends StatefulWidget {
  final UserListEntity user;

  const VideoCallScreen({
    super.key,
    required this.user,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    final provider = context.read<VideoCallProvider>();

    // Initialize Agora engine
    await provider.initializeAgora();

    // Wait a bit for engine to be fully ready
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Start call
    // In TEST_MODE, use a fixed channel name so multiple devices can join the same channel
    final testMode = dotenv.env['TEST_MODE'] == 'true';
    final channelName = testMode
        ? 'test_channel_${widget.user.id}' // Fixed channel for testing
        : 'channel_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}'; // Unique channel for production

    await provider.startCall(
      receiverId: widget.user.id,
      receiverName: widget.user.name,
      channelName: channelName,
      userId: '123', // Should come from current user
    );
  }

  Future<void> _endCall() async {
    final provider = context.read<VideoCallProvider>();
    await provider.endCall();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<VideoCallProvider>(
          builder: (context, provider, child) {
            if (provider.status == VideoCallStatus.error) {
              return _buildErrorView(provider.errorMessage);
            }

            if (provider.status == VideoCallStatus.connecting) {
              return _buildConnectingView();
            }

            return Stack(
              children: [
                // Remote video (full screen)
                if (provider.remoteUid != null && provider.engine != null)
                  AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: provider.engine!,
                      canvas: VideoCanvas(uid: provider.remoteUid),
                      connection: RtcConnection(
                        channelId: provider.currentCall?.channelName ?? '',
                      ),
                    ),
                  )
                else
                  _buildWaitingView(),

                // Screen share view (when remote user is sharing - use their UID with screen source)
                if (provider.remoteUid != null && provider.engine != null)
                  Positioned(
                    top: 220,
                    left: 16,
                    right: 16,
                    height: 250,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            AgoraVideoView(
                              controller: VideoViewController.remote(
                                rtcEngine: provider.engine!,
                                canvas: VideoCanvas(
                                  uid: provider.remoteUid, // Same UID as camera!
                                  sourceType: VideoSourceType.videoSourceScreen, // But SCREEN source!
                                ),
                                connection: RtcConnection(
                                  channelId: provider.currentCall?.channelName ?? '',
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.screen_share,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Screen Share',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Local video (small preview)
                Positioned(
                  top: 40,
                  right: 16,
                  child: Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: provider.engine != null
                          ? AgoraVideoView(
                              controller: VideoViewController(
                                rtcEngine: provider.engine!,
                                canvas: const VideoCanvas(uid: 0),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                    ),
                  ),
                ),

                // User info overlay
                Positioned(
                  top: 40,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(provider.status),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Call controls
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: _buildCallControls(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              widget.user.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connecting...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildWaitingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              widget.user.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Calling...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            error ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls(VideoCallProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Toggle microphone
            CallControlButton(
              icon: provider.isMuted ? Icons.mic_off : Icons.mic,
              label: provider.isMuted ? 'Unmute' : 'Mute',
              backgroundColor: provider.isMuted ? Colors.red : Colors.white24,
              onTap: provider.toggleMicrophone,
            ),

            // Switch camera
            CallControlButton(
              icon: Icons.switch_camera,
              label: 'Switch',
              backgroundColor: Colors.white24,
              onTap: provider.switchCamera,
            ),

            // Toggle camera
            CallControlButton(
              icon: provider.isCameraOff ? Icons.videocam_off : Icons.videocam,
              label: provider.isCameraOff ? 'Camera On' : 'Camera Off',
              backgroundColor: provider.isCameraOff ? Colors.red : Colors.white24,
              onTap: provider.toggleCamera,
            ),

            // End call
            CallControlButton(
              icon: Icons.call_end,
              label: 'End',
              backgroundColor: AppColors.endCallRed,
              onTap: _endCall,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Secondary controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Screen share button
            CallControlButton(
              icon: provider.isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
              label: provider.isScreenSharing ? 'Stop Share' : 'Share Screen',
              backgroundColor: provider.isScreenSharing ? AppColors.primary : Colors.white24,
              onTap: provider.toggleScreenShare,
            ),
          ],
        ),
      ],
    );
  }

  String _getStatusText(VideoCallStatus status) {
    switch (status) {
      case VideoCallStatus.connecting:
        return 'Connecting...';
      case VideoCallStatus.connected:
        return 'Connected';
      case VideoCallStatus.disconnected:
        return 'Disconnected';
      case VideoCallStatus.error:
        return 'Error';
      default:
        return 'Calling...';
    }
  }
}
