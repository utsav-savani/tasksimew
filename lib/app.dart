import 'package:flutter/material.dart';

import 'core/constants/route_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/users/presentation/screens/users_list_screen.dart';
import 'features/video_call/presentation/screens/video_call_screen.dart';
import 'features/video_call/presentation/screens/meeting_join_screen.dart';
import 'features/video_call/presentation/screens/direct_video_call_screen.dart';
import 'features/video_call/presentation/screens/incoming_call_screen.dart';
import 'features/users/domain/entities/user_list_entity.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Call App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: RouteConstants.splash,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case RouteConstants.splash:
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            );
          case RouteConstants.login:
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );
          case RouteConstants.register:
            return MaterialPageRoute(
              builder: (_) => const RegisterScreen(),
            );
          case RouteConstants.home:
          case RouteConstants.usersList:
            return MaterialPageRoute(
              builder: (_) => const UsersListScreen(),
            );
          case RouteConstants.videoCall:
            final user = settings.arguments as UserListEntity?;
            if (user == null) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Invalid user')),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => VideoCallScreen(user: user),
            );
          case RouteConstants.meetingJoin:
            return MaterialPageRoute(
              builder: (_) => const MeetingJoinScreen(),
            );
          case RouteConstants.directVideoCall:
            final args = settings.arguments as Map<String, dynamic>?;
            if (args == null || !args.containsKey('meetingId')) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Invalid meeting parameters')),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => DirectVideoCallScreen(
                meetingId: args['meetingId'] as String,
                userId: args['userId'] as String? ?? '123',
              ),
            );
          case RouteConstants.incomingCall:
            final args = settings.arguments as Map<String, dynamic>?;
            if (args == null) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Invalid call parameters')),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => IncomingCallScreen(
                callerId: args['callerId'] as String? ?? '',
                callerName: args['callerName'] as String? ?? 'Unknown',
                channelName: args['channelName'] as String? ?? '',
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Page not found')),
              ),
            );
        }
      },
    );
  }
}
