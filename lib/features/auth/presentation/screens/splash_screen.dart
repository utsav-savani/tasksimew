import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/constants/route_constants.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Check if in test mode
    final testMode = dotenv.env['TEST_MODE'] == 'true';

    // Wait for a minimum duration for splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (testMode) {
      // In test mode, skip authentication and go directly to home
      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteConstants.home);
      }
    } else {
      // Normal mode: check authentication
      final authProvider = context.read<AuthProvider>();
      await authProvider.checkAuthStatus();

      if (!mounted) return;

      if (authProvider.isAuthenticated) {
        Navigator.pushReplacementNamed(context, RouteConstants.home);
      } else {
        Navigator.pushReplacementNamed(context, RouteConstants.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Icon(
              Icons.video_call,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),

            // App Name
            Text(
              'Video Call App',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Test Mode Indicator
            if (dotenv.env['TEST_MODE'] == 'true')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'TEST MODE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 40),

            // Loading Indicator
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
