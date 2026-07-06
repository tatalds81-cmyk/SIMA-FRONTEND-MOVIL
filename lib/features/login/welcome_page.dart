import 'dart:async';

import 'package:flutter/material.dart';

import 'login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _counter = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter > 1) {
        setState(() => _counter--);
        return;
      }
      timer.cancel();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF092444),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: compact ? 22 : 38),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  (size.width * .07).clamp(20.0, 30.0),
                  compact ? 20 : 28,
                  (size.width * .07).clamp(20.0, 30.0),
                  0,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/images/logo-Sena.png',
                        width: compact ? 62 : 72,
                        height: compact ? 62 : 72,
                        fit: BoxFit.contain,
                        color: const Color(0xFF39A900),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 15),
                    Text(
                      'Bienvenido a SIMA',
                      style: TextStyle(
                        color: const Color(0xFF00A4E4),
                        fontSize: compact ? 16 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sistema Integral\nde Monitoreo del\nAprendiz',
                      style: TextStyle(
                        color: const Color(0xFF052D4F),
                        fontSize: compact ? 27 : 32,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: compact ? 9 : 14),
                    const Text(
                      'Herramienta dise\u00f1ada para el seguimiento acad\u00e9mico de los aprendices.',
                      style: TextStyle(
                        color: Color(0xFF596879),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          'assets/images/aprendices_sena.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: 10,
                        bottom: MediaQuery.paddingOf(context).bottom + 18,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF39A900),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Redirigiendo en $_counter...',
                              style: const TextStyle(
                                color: Color(0xFF052D4F),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
