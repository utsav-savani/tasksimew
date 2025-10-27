import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/route_constants.dart';

class MeetingJoinScreen extends StatefulWidget {
  const MeetingJoinScreen({super.key});

  @override
  State<MeetingJoinScreen> createState() => _MeetingJoinScreenState();
}

class _MeetingJoinScreenState extends State<MeetingJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _meetingIdController = TextEditingController();
  final _userIdController = TextEditingController(text: '123'); // Default user ID

  @override
  void dispose() {
    _meetingIdController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  void _joinMeeting() {
    if (_formKey.currentState?.validate() ?? false) {
      final meetingId = _meetingIdController.text.trim();
      final userId = _userIdController.text.trim();

      // Navigate to video call screen with meeting ID
      Navigator.pushNamed(
        context,
        RouteConstants.directVideoCall,
        arguments: {
          'meetingId': meetingId,
          'userId': userId,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Join Meeting'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Icon(
                  Icons.video_call,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Join a Video Meeting',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Enter the same Meeting ID on both devices to connect',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Meeting ID Input
                TextFormField(
                  controller: _meetingIdController,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Meeting ID',
                    hintText: 'e.g., meeting123',
                    prefixIcon: Icon(Icons.meeting_room, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a meeting ID';
                    }
                    if (value.trim().length < 3) {
                      return 'Meeting ID must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // User ID Input
                TextFormField(
                  controller: _userIdController,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Your User ID (Optional)',
                    hintText: 'e.g., 123',
                    prefixIcon: Icon(Icons.person, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _joinMeeting(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a user ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Join Button
                ElevatedButton(
                  onPressed: _joinMeeting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.video_call, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Join Meeting',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How to test with 2 devices:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Choose a Meeting ID (e.g., "test123")\n'
                        '2. Enter the SAME Meeting ID on both devices\n'
                        '3. Tap "Join Meeting" on both devices\n'
                        '4. You\'ll see each other\'s video!',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
