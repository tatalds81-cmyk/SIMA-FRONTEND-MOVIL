import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _counter = 3; // Solicitado: 3 segundos
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
    final mq = MediaQuery.of(context);
    final double height = mq.size.height;
    final double width = mq.size.width;

    // Responsive breakpoints
    final bool isSmallPhone = height < 700;
    final bool isNarrow = width < 360;

    // Proportional values
    final double horizontalPad = (width * 0.06).clamp(16.0, 24.0);
    final double verticalPad = isSmallPhone ? 16.0 : 24.0;
    final double logoSize = isSmallPhone ? 44.0 : 60.0;
    final double welcomeFontSize = isNarrow ? 15.0 : 18.0;
    final double titleFontSize = isSmallPhone ? 26.0 : 32.0;
    final double subtitleFontSize = isNarrow ? 12.0 : 14.0;
    final double countdownFontSize = isNarrow ? 12.0 : 14.0;

    // Spacing
    final double logoToWelcome = isSmallPhone ? 16.0 : 24.0;
    final double welcomeToTitle = isSmallPhone ? 8.0 : 12.0;
    final double titleToSubtitle = isSmallPhone ? 10.0 : 16.0;
    final double subtitleToImage = isSmallPhone ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFF092444), // Azul oscuro institucional homologado con el login
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // El espacio azul que queda visible 
            SizedBox(height: isSmallPhone ? 35.0 : 50.0),
            
            // Tarjeta blanca principal interna con bordes redondeados
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: horizontalPad,
                    right: horizontalPad,
                    top: verticalPad,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top-left SENA Logo (Green)
                      Image.asset(
                        'assets/images/logo-Sena.png',
                        height: logoSize,
                        width: logoSize,
                        fit: BoxFit.contain,
                        color: const Color(0xFF39A900), // verde SENA
                        colorBlendMode: BlendMode.srcIn,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE0E0E0),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'SENA',
                                style: TextStyle(
                                  color: Color(0xFF39A900),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: logoToWelcome),

                      // Welcome text (Light Blue)
                      Text(
                        'Bienvenido a SIMA',
                        style: TextStyle(
                          fontSize: welcomeFontSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00A4E4),
                        ),
                      ),
                      SizedBox(height: welcomeToTitle),
                      
                      // Title (Azul Oscuro sobre fondo blanco)
                      Text(
                        'Sistema Integral\nde Monitoreo del\nAprendiz',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF052D4F), // Color ajustado para fondo blanco
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: titleToSubtitle),

                      // Subtitle (Gris oscuro sobre fondo blanco)
                      Text(
                        'Herramienta diseñada para el\nseguimiento academico de los\naprendices.',
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: const Color(0xFF596879), // Color ajustado para fondo blanco
                          height: 1.5,
                        ),
                      ),

                      // Spacer to push image down a bit if needed
                      SizedBox(height: subtitleToImage),

                      // Image of Apprentices
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            'assets/images/aprendices_sena.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: height * 0.2,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF052D4F).withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      color: Color(0xFF052D4F),
                                      size: 64,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      '[Imagen de Aprendices SENA]',
                                      style: TextStyle(
                                        color: Color(0xFF596879),
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
                      
                      // Bottom part with the countdown in the white area
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: isSmallPhone ? 20.0 : 32.0,
                          top: isSmallPhone ? 10.0 : 16.0,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: isSmallPhone ? 20.0 : 24.0,
                                width: isSmallPhone ? 20.0 : 24.0,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF39A900)),
                                ),
                              ),
                              SizedBox(height: isSmallPhone ? 8.0 : 12.0),
                              Text(
                                'Redirigiendo en $_counter...',
                                style: TextStyle(
                                  fontSize: countdownFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF052D4F),
                                ),
                              ),
                              // Agregado un poco de padding bottom extra debido al safearea bottom=false
                              SizedBox(height: mq.padding.bottom),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
