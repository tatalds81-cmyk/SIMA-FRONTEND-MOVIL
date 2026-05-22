import 'package:flutter/material.dart';
import 'widgets/custom_button.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // Forma superior azul oscuro
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: _TopWaveClipper(),
                child: Container(
                  height: 160,
                  color: const Color(0xFF052D4F),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top-left SENA Logo (White)
                Image.asset(
                  'assets/images/logo-Sena.png',
                  height: 60,
                  width: 60,
                  fit: BoxFit.contain,
                  color: const Color(0xFF39A900), // verde SENA
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if logo is missing
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
                const SizedBox(height: 8), // Reducido para subir el texto

                // Welcome text
                const Text(
                  'Bienvenido a SIMA',
                  style: TextStyle(
                    fontSize: 24, // Un poco más grande
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // Color blanco
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sistema Integral\nde Monitoreo del\nAprendiz',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF052D4F),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 20),

                // Subtitle
                const Text(
                  'Gestiona tus asistencias, monitorea tu progreso y alcanza tu máximo potencial académico.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),

                // Image of Apprentices
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/aprendices_sena.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback illustration if image is missing
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
                const SizedBox(height: 24),

                // Button "Iniciar" (Green Gradient)
                CustomButton(
                  text: 'Iniciar',
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF39A900), // --sima-green
                      Color(0xFF238500), // --sima-green-dark
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
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

class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 3.25), size.height - 65);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
