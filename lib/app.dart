import 'package:flutter/material.dart';

import 'screens/main/main_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'storage/profile_storage.dart';
import 'theme/app_theme.dart';

class CometApp extends StatelessWidget {
  const CometApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Comet',
      theme: AppTheme.darkTheme,
      home: const _StartupScreen(),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ProfileStorage.hasProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF0C0F0F),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF75EEFD),
              ),
            ),
          );
        }

        final hasProfile = snapshot.data ?? false;

        if (hasProfile) {
          return const MainScreen();
        }

        return const WelcomeScreen();
      },
    );
  }
}