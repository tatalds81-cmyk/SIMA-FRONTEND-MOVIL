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
    final mq = MediaQuery.of(context);
    final double width = mq.size.width;
    final double height = mq.size.height;

    // --- Responsive breakpoints ---
    final bool isSmallPhone = height < 700;
    final bool isNarrow = width < 360;

    // --- Proportional values (same design, adaptive sizes) ---
    final double horizontalPad = (width * 0.06).clamp(16.0, 24.0);
    final double verticalPad = isSmallPhone ? 10.0 : 16.0;
    final double bottomBlueSpace = height * (isSmallPhone ? 0.06 : 0.08);
    final double bottomRadius = isNarrow ? 120.0 : 180.0;

    // Card
    final double cardPadding = isSmallPhone || isNarrow ? 18.0 : 24.0;

    // Font sizes
    final double titleFontSize = isNarrow ? 24.0 : 28.0;
    final double subtitleFontSize = isNarrow ? 12.0 : 14.0;
    final double bodyFontSize = isNarrow ? 12.0 : 14.0;
    final double footerFontSize = isNarrow ? 11.0 : 12.0;
    final double logoSize = isSmallPhone ? 42.0 : 50.0;
    final double helpFontSize = isNarrow ? 12.0 : 14.0;

    // Spacing
    final double logoToCard = isSmallPhone ? height * 0.03 : height * 0.05;
    final double fieldSpacing = isSmallPhone ? 14.0 : 20.0;
    final double sectionSpacing = isSmallPhone ? 16.0 : 24.0;
    final double forgotSpacing = isSmallPhone ? 10.0 : 16.0;
    final double cardToFooter = isSmallPhone ? height * 0.03 : height * 0.05;

    return Scaffold(
      backgroundColor: Colors.white, // Mismo fondo que la vista de bienvenida
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Fondo azul oscuro con redondeado (100% como la web, pero en versión top/mobile)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: bottomBlueSpace,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(bottomRadius),
                ),
                image: DecorationImage(
                  image: const AssetImage('assets/images/fondoSima.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  colorFilter: ColorFilter.mode(
                    const Color(0xFF052D4F).withOpacity(0.7),
                    BlendMode.srcOver,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPad,
                        vertical: verticalPad,
                      ),
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
                                  height: logoSize,
                                  width: logoSize,
                                  fit: BoxFit.contain,
                                  color: const Color(0xFF39A900), // verde SENA
                                  colorBlendMode: BlendMode.srcIn,
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    // Help action
                                  },
                                  icon: Icon(
                                    Icons.help_outline,
                                    size: helpFontSize + 4,
                                    color: Colors.white, // Texto blanco sobre fondo azul oscuro
                                  ),
                                  label: Text(
                                    '¿Necesitas ayuda?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: helpFontSize,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: logoToCard), // Reducido para que suba la tarjeta y quede como en tu foto

                            // Login Card Container (Mimics the card in web)
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 520),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(cardPadding),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18), // Mismo redondeado de tarjeta
                                    border: Border.all(color: const Color(0xFFDFE5EC)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromRGBO(9, 36, 68, 0.12),
                                        offset: const Offset(0, 10),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Iniciar sesion',
                                        style: TextStyle(
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF092444), // --sima-text
                                        ),
                                      ),
                                      SizedBox(height: isSmallPhone ? 4.0 : 8.0),
                                      Text(
                                        'Ingresa tus credenciales para continuar',
                                        style: TextStyle(
                                          fontSize: subtitleFontSize,
                                          color: const Color(0xFF596879),
                                        ),
                                      ),
                                      SizedBox(height: sectionSpacing),

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
                                      SizedBox(height: fieldSpacing),

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
                                      SizedBox(height: forgotSpacing),

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
                                            foregroundColor: const Color(0xFF00649B), // Azul claro enlace
                                          ),
                                          child: Text(
                                            'Olvidaste tu contraseña?',
                                            style: TextStyle(
                                                fontSize: bodyFontSize,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF00649B)),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: sectionSpacing),

                                      // Button "Iniciar sesion" - Color sólido igual a la web
                                      CustomButton(
                                        text: 'Iniciar sesion',
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF39A900), Color(0xFF238500)],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        textColor: Colors.white,
                                        onPressed: _handleLogin,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: cardToFooter),

                            // Secure Footer
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 520),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.verified_user_outlined,
                                          color: const Color(0xFF39A900),
                                          size: isSmallPhone ? 16.0 : 20.0,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Tu informacion esta protegida con los mas altos estandares de seguridad.',
                                            style: TextStyle(
                                              fontSize: footerFontSize,
                                              color: const Color(0xFF596879),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isSmallPhone ? 14.0 : 24.0),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () {},
                                          child: Text(
                                            'Politicas de privacidad',
                                            style: TextStyle(
                                              fontSize: footerFontSize,
                                              color: const Color(0xFF00649B),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text('|', style: TextStyle(color: const Color(0xFF596879))),
                                        ),
                                        GestureDetector(
                                          onTap: () {},
                                          child: Text(
                                            'Terminos y condiciones',
                                            style: TextStyle(
                                              fontSize: footerFontSize,
                                              color: const Color(0xFF00649B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isSmallPhone ? 4.0 : 8.0),
                                    Text(
                                      '(c) 2024 SENA. Todos los derechos reservados.',
                                      style: TextStyle(
                                        fontSize: footerFontSize,
                                        color: const Color(0xFF596879),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: verticalPad),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
