import 'package:flutter/material.dart';

import '../constants/theme.dart';

/// Shown while persisted state (onboarding flag, calibration data) is being
/// read. The router holds here until both are known, then sends the user to
/// onboarding or home — so a returning user never sees onboarding flash by.
///
/// Deliberately text-free apart from the app name: this renders before the
/// user's locale has been loaded, so there is nothing safe to localize yet.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.retroSky,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MojiLearner',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.retroDark,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.retroDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
