import 'package:flutter/material.dart';
import 'package:sima_movil_froned/features/access.dart';
import 'widgets/custom_input.dart';
import 'widgets/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _documentController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _documentController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      // Show success SnackBar message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicio de sesión exitoso'),
          backgroundColor: Color(0xFF39A900), // Verde SENA
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to main application page (AccessPage) after a short delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AccessPage(),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Background light blue-gray
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row with Logo and Help Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/images/logo-Sena.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // Help action
                        },
                        icon: const Icon(
                          Icons.help_outline,
                          size: 18,
                          color: Color(0xFF092444),
                        ),
                        label: const Text(
                          '¿Necesitas ayuda?',
                          style: TextStyle(
                            color: Color(0xFF092444),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Login Card Container (Mimics the card in web)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDFE5EC)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF092444).withOpacity(0.06),
                          offset: const Offset(0, 10),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Iniciar sesion',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF092444), // --sima-text
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ingresa tus credenciales para continuar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF596879),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Documento field
                        CustomInput(
                          controller: _documentController,
                          labelText: 'Documento de Identidad',
                          hintText: 'Ingresa tu numero de documento',
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(
                            Icons.mail_outline,
                            color: Color(0xFF566577),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa tu número de documento';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Contraseña field
                        CustomInput(
                          controller: _passwordController,
                          labelText: 'Contraseña',
                          hintText: 'Ingresa tu contraseña',
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF566577),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF566577),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu contraseña';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Olvidaste tu contraseña link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Forgot password placeholder
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: const Color(0xFF00649B),
                            ),
                            child: const Text(
                              'Olvidaste tu contraseña?',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF00649B)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Button "Iniciar sesion" with Gradient
                        CustomButton(
                          text: 'Iniciar sesion',
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF39A900), // --sima-green
                              Color(0xFF238500), // --sima-green-dark
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          onPressed: _handleLogin,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Secure Footer
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xFF238500),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tu informacion esta protegida con los mas altos estandares de seguridad.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF5F6B79),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Politicas de privacidad',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF00649B),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('|', style: TextStyle(color: Color(0xFF5F6B79))),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Terminos y condiciones',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF00649B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '(c) 2024 SENA. Todos los derechos reservados.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5F6B79),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
