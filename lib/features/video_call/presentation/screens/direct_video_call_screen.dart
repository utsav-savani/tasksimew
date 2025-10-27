import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/video_call_provider.dart';
import '../widgets/call_control_button.dart';

class DirectVideoCallScreen extends StatefulWidget {
  final String meetingId;
  final String userId;

  const DirectVideoCallScreen({
    super.key,
    required this.meetingId,
    required this.userId,
  });

  @override
  State<DirectVideoCallScreen> createState() => _DirectVideoCallScreenState();
}

class _DirectVideoCallScreenState extends State<DirectVideoCallScreen> {
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

    // Start call with meeting ID as channel name
    await provider.startCall(
      receiverId: widget.meetingId, // Use meeting ID
      receiverName: 'Meeting: ${widget.meetingId}',
      channelName: widget.meetingId, // Direct channel name
      userId: widget.userId,
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
                        channelId: widget.meetingId,
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
                                  channelId: widget.meetingId,
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
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Screen Share',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Local video (small preview)
                if (provider.engine != null)
                  Positioned(
                    top: 50,
                    right: 16,
                    width: 120,
                    height: 160,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: provider.engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Meeting ID display
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.meeting_room,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Meeting: ${widget.meetingId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Controls at bottom
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: _buildControls(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls(VideoCallProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CallControlButton(
            icon: provider.isMuted ? Icons.mic_off : Icons.mic,
            label: provider.isMuted ? 'Unmute' : 'Mute',
            onTap: provider.toggleMicrophone,
            backgroundColor: provider.isMuted ? Colors.red : Colors.white24,
          ),
          CallControlButton(
            icon: provider.isCameraOff ? Icons.videocam_off : Icons.videocam,
            label: provider.isCameraOff ? 'Camera On' : 'Camera Off',
            onTap: provider.toggleCamera,
            backgroundColor: provider.isCameraOff ? Colors.red : Colors.white24,
          ),
          CallControlButton(
            icon: Icons.cameraswitch,
            label: 'Switch',
            onTap: provider.switchCamera,
            backgroundColor: Colors.white24,
          ),
          CallControlButton(
            icon: provider.isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
            label: provider.isScreenSharing ? 'Stop Share' : 'Share',
            onTap: provider.toggleScreenShare,
            backgroundColor: provider.isScreenSharing ? AppColors.primary : Colors.white24,
          ),
          CallControlButton(
            icon: Icons.call_end,
            label: 'End',
            onTap: _endCall,
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            'Connecting to meeting...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Meeting ID: ${widget.meetingId}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 24),
          Text(
            'Waiting for others to join...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share this Meeting ID: ${widget.meetingId}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String? errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to join meeting',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Unknown error occurred',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
