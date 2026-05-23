import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _counter = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter > 1) {
        setState(() {
          _counter--;
        });
      } else {
        _timer?.cancel();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        }
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo azul oscuro principal con redondeado inferior derecho
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 60, // Espacio justo para el área blanca inferior
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF052D4F),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(180), // Curva idéntica a la del login y web
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top-left SENA Logo (Green)
                        Image.asset(
                          'assets/images/logo-Sena.png',
                          height: 60,
                          width: 60,
                          fit: BoxFit.contain,
                          color: const Color(0xFF39A900), // verde SENA
                          colorBlendMode: BlendMode.srcIn,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'SENA',
                                  style: TextStyle(
                                    color: const Color(0xFF39A900),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24), 

                        // Welcome text (Light Blue)
                        const Text(
                          'Bienvenido a SIMA',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00A4E4), // Azul claro / celeste
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Title
                        const Text(
                          'Sistema Integral\nde Monitoreo del\nAprendiz',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtitle
                        const Text(
                          'Herramienta diseñada para el\nseguimiento academico de los\naprendices.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        
                        // Spacer to push image down a bit if needed
                        const SizedBox(height: 20),

                        // Image of Apprentices
                        Expanded(
                          child: Center(
                            child: Image.asset(
                              'assets/images/aprendices_sena.png',
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        color: Colors.white70,
                                        size: 64,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        '[Imagen de Aprendices SENA]',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom part with the countdown in the white area
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0, top: 16.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF39A900)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Redirigiendo en $_counter...',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF052D4F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
