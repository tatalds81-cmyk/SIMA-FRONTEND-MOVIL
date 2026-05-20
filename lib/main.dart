import 'package:flutter/material.dart';
import 'package:sima_movil_froned/features/access.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF44C21E),
          primary: const Color(0xFF44C21E),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        useMaterial3: true,
      ),
      home: const AccessPage(),
    );
  }
}
