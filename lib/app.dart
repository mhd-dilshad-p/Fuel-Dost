import 'package:flutter/material.dart';
import 'core/constants/app_theme.dart';
import 'shared/presentation/screens/splash_screen.dart';

class FuelDostApp extends StatelessWidget {
  const FuelDostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FuelDost',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
