import 'package:flutter/material.dart';

import 'screens/onboarding/welcome_screen.dart';
import 'theme/app_theme.dart';

class CometApp extends StatelessWidget {
  const CometApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Comet',
      theme: AppTheme.darkTheme,
      home: const WelcomeScreen(),
    );
  }
}