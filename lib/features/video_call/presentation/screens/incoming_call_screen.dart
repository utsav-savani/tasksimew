import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../providers/video_call_provider.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callerId;
  final String callerName;
  final String channelName;

  const IncomingCallScreen({
    super.key,
    required this.callerId,
    required this.callerName,
    required this.channelName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80),

            // Caller avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
                border: Border.all(
                  color: AppColors.primary,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  callerName.isNotEmpty ? callerName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Caller name
            Text(
              callerName,
              style: AppTextStyles.h1.copyWith(
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Call status
            Text(
              'Incoming Video Call...',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const Spacer(),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _handleDecline(context),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Decline',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Accept button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _handleAccept(context),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          child: const Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Accept',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _handleAccept(BuildContext context) async {
    final provider = context.read<VideoCallProvider>();

    // Initialize Agora
    await provider.initializeAgora();

    // Wait for engine to be ready
    await Future.delayed(const Duration(milliseconds: 500));

    if (!context.mounted) return;

    // Start call
    await provider.startCall(
      receiverId: callerId,
      receiverName: callerName,
      channelName: channelName,
      userId: '123', // TODO: Get from auth provider
    );

    if (!context.mounted) return;

    // Navigate to video call screen
    Navigator.pushReplacementNamed(
      context,
      '/direct-video-call',
      arguments: {
        'meetingId': channelName,
        'userId': '123',
      },
    );
  }

  void _handleDecline(BuildContext context) {
    // Just close the screen
    Navigator.pop(context);
  }
}
