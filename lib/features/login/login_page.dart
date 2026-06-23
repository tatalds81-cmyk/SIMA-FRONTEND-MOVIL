import 'package:flutter/material.dart';
import 'package:sima_movil_froned/features/access.dart';
import 'package:sima_movil_froned/services/auth_service.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _documentController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.login(
      documento: _documentController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: const Color(0xFF39A900), // Verde SENA
          duration: const Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AccessPage()),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: const Color(0xFFD32F2F), // Rojo error
          duration: const Duration(seconds: 3),
        ),
      );
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

    // Card
    final double cardPadding = isSmallPhone || isNarrow ? 24.0 : 32.0;

    // Font sizes (aumentados ligeramente)
    final double titleFontSize = isNarrow ? 24.0 : 28.0;
    final double subtitleFontSize = isNarrow ? 13.0 : 14.0;
    final double bodyFontSize = isNarrow ? 14.0 : 15.0;
    final double footerFontSize = isNarrow ? 11.0 : 12.0;
    final double logoSize = isSmallPhone ? 40.0 : 45.0;
    final double welcomeFontSize = isNarrow ? 14.0 : 16.0;

    // Spacing (más ajustado en la parte superior)
    final double fieldSpacing = isSmallPhone ? 14.0 : 18.0;
    final double sectionSpacing = isSmallPhone ? 18.0 : 24.0;

    return Scaffold(
      // Se mantiene movible para que el teclado no dañe la vista,
      // pero el diseño luce estático visualmente.
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF092444), // Azul oscuro SENA (#092444)
      body: Stack(
        children: [
          // ── Imagen de fondo limpia proporcionada por el usuario ──
          // ── Fondo azul sólido (Scaffold backgroundColor ya lo provee) ──

          // ── Contenido sobre la imagen ──
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Zona superior (Textos y Logo) ──
                          Padding(
                            padding: EdgeInsets.only(
                              left: horizontalPad,
                              right: horizontalPad,
                              top: isSmallPhone ? 16.0 : 24.0,
                              // Reducido para subir la tarjeta blanca
                              bottom: isSmallPhone ? 12.0 : 20.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Logo SENA alineado a la izquierda
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Image.asset(
                                    'assets/images/logo-Sena.png',
                                    height: logoSize,
                                    width: logoSize,
                                    fit: BoxFit.contain,
                                    color: const Color(
                                      0xFF39A900,
                                    ), // verde SENA
                                    colorBlendMode: BlendMode.srcIn,
                                  ),
                                ),
                                SizedBox(height: isSmallPhone ? 12.0 : 18.0),

                                // Welcome Text Section
                                Text(
                                  'Bienvenido a SIMA',
                                  style: TextStyle(
                                    fontSize: welcomeFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF00A4E4),
                                  ),
                                ),
                                const SizedBox(height: 6.0),

                                // Title
                                Text(
                                  'Sistema Integral\nde Monitoreo del\nAprendiz',
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 10.0),

                                // Subtitle
                                Text(
                                  'Herramienta diseñada para el\nseguimiento académico de los\naprendices.',
                                  style: TextStyle(
                                    fontSize: subtitleFontSize,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Tarjeta blanca de Login ──
                          const Spacer(),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPad * 0.55,
                              0,
                              horizontalPad * 0.55,
                              mq.padding.bottom + 18,
                            ),
                            child: Container(
                              width: double.infinity,
                              // Padding interno ajustado (menos espacio vacío abajo)
                              padding: EdgeInsets.fromLTRB(
                                horizontalPad,
                                cardPadding * 0.82,
                                horizontalPad,
                                18.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 28,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Iniciar sesión',
                                      style: TextStyle(
                                        fontSize: titleFontSize * 0.9,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF092444),
                                      ),
                                    ),
                                    const SizedBox(height: 6.0),
                                    Text(
                                      'Ingresa tus credenciales para continuar',
                                      style: TextStyle(
                                        fontSize: subtitleFontSize,
                                        color: const Color(0xFF596879),
                                      ),
                                    ),
                                    SizedBox(height: sectionSpacing),

                                    // Documento field Label
                                    Text(
                                      'Documento de Identidad',
                                      style: TextStyle(
                                        fontSize: bodyFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF092444),
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    // Documento field
                                    CustomInput(
                                      controller: _documentController,
                                      hintText:
                                          'Ingresa tu numero de documento',
                                      keyboardType: TextInputType.number,
                                      prefixIcon: const Icon(
                                        Icons.mail_outline,
                                        color: Color(0xFF566577),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Por favor ingresa tu número de documento';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: fieldSpacing),

                                    // Contraseña field Label
                                    Text(
                                      'Contraseña',
                                      style: TextStyle(
                                        fontSize: bodyFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF092444),
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    // Contraseña field
                                    CustomInput(
                                      controller: _passwordController,
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
                                            _obscurePassword =
                                                !_obscurePassword;
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
                                    const SizedBox(height: 8.0),

                                    // Olvidaste tu contraseña link
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          foregroundColor: const Color(
                                            0xFF00A4E4,
                                          ),
                                        ),
                                        child: Text(
                                          'Olvidaste tu contraseña?',
                                          style: TextStyle(
                                            fontSize: bodyFontSize,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(
                                              0xFF00A4E4,
                                            ), // Color cyan como en la referencia
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: sectionSpacing),

                                    // Button "Iniciar sesion"
                                    CustomButton(
                                      text: _isLoading
                                          ? 'Verificando...'
                                          : 'Iniciar sesión',
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF39A900),
                                          Color(0xFF238500),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      textColor: Colors.white,
                                      onPressed: _isLoading
                                          ? null
                                          : _handleLogin,
                                    ),

                                    SizedBox(height: sectionSpacing),

                                    // ¿No tienes una cuenta? separator
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '¿No tienes una cuenta?',
                                              style: TextStyle(
                                                fontSize: footerFontSize,
                                                color: const Color(
                                                  0xFF092444,
                                                ), // Azul oscuro
                                                fontWeight: FontWeight
                                                    .w700, // En negrita como en la foto
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: isSmallPhone ? 8 : 14),

                                    // Footer (c) 2024 SENA (Color oscuro al estar sobre blanco)
                                    Center(
                                      child: Text(
                                        '(c) 2024 SENA. Todos los derechos reservados.',
                                        style: TextStyle(
                                          fontSize: footerFontSize,
                                          color: const Color(0xFF092444),
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
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
