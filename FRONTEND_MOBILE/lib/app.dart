import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/splash/splash_screen.dart';

/// Root widget: configures theming and launches into the splash flow.
class ForthPortsApp extends StatelessWidget {
  const ForthPortsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SplashScreen(
        onComplete: (_) => AuthRepository.instance.isLoggedIn
            ? const MainShell()
            : const LoginScreen(),
      ),
      // Clamp text scaling so the carefully tuned splash/brand layout never
      // breaks on devices with very large accessibility font settings.
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            textScaler: data.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
