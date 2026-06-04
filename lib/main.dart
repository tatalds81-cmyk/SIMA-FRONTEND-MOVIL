import 'package:flutter/material.dart';
import 'package:sima_movil_froned/features/login/welcome_page.dart';
import 'package:sima_movil_froned/theme/app_theme.dart';

void main() {
  runApp(const SimaApp());
}

class SimaApp extends StatelessWidget {
  const SimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIMA',
      theme: AppTheme.lightTheme,
      home: const WelcomePage(),
    );
  }
}
