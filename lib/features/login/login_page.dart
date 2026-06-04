import 'package:flutter/material.dart';
import 'package:sima_movil_froned/features/access.dart';
import 'package:sima_movil_froned/services/auth_service.dart';
import 'package:sima_movil_froned/theme/app_colors.dart';
import 'package:sima_movil_froned/widgets/app_text_field.dart';
import 'package:sima_movil_froned/widgets/app_primary_button.dart';

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
          backgroundColor: AppColors.accentGreen, // Verde SENA
          duration: const Duration(seconds: 2),
        ),
      );

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.alertCritical, // Rojo error
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

    // --- Proportional values ---
    final double horizontalPad = (width * 0.06).clamp(16.0, 24.0);
    final double cardPadding = isSmallPhone || isNarrow ? 24.0 : 32.0;

    final double titleFontSize = isNarrow ? 24.0 : 28.0;
    final double subtitleFontSize = isNarrow ? 13.0 : 14.0;
    final double footerFontSize = isNarrow ? 11.0 : 12.0;
    final double logoSize = isSmallPhone ? 40.0 : 45.0;
    final double welcomeFontSize = isNarrow ? 14.0 : 16.0;

    final double fieldSpacing = isSmallPhone ? 14.0 : 18.0;
    final double sectionSpacing = isSmallPhone ? 18.0 : 24.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.primaryBlue, // Azul principal
      body: SafeArea(
        bottom: false,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
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
                                  color: AppColors.accentGreen, // verde SENA
                                  colorBlendMode: BlendMode.srcIn,
                                ),
                              ),
                              SizedBox(height: isSmallPhone ? 12.0 : 18.0),

                              // Welcome Text Section
                              Text(
                                'Bienvenido a SIMA',
                                style: TextStyle(
                                  fontSize: welcomeFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentGreen,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              
                              // Title
                              Text(
                                'Sistema Integral\nde Monitoreo del\nAprendiz',
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w900,
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
                                  color: Colors.white.withValues(alpha: 0.7),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Tarjeta blanca de Login ──
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(
                              horizontalPad, 
                              cardPadding, 
                              horizontalPad, 
                              mq.padding.bottom + 12.0,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(40),
                                topRight: Radius.circular(40),
                              ),
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
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textMain, 
                                    ),
                                  ),
                                  const SizedBox(height: 6.0),
                                  Text(
                                    'Ingresa tus credenciales para continuar',
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      color: AppColors.secondaryGrey,
                                    ),
                                  ),
                                  SizedBox(height: sectionSpacing),

                                  // Documento field (using consolidated AppTextField)
                                  AppTextField(
                                    controller: _documentController,
                                    labelText: 'Documento de Identidad',
                                    hintText: 'Ingresa tu número de documento',
                                    keyboardType: TextInputType.number,
                                    prefixIcon: const Icon(
                                      Icons.mail_outline_rounded,
                                      color: AppColors.secondaryGrey,
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
                                  AppTextField(
                                    controller: _passwordController,
                                    labelText: 'Contraseña',
                                    hintText: 'Ingresa tu contraseña',
                                    obscureText: _obscurePassword,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: AppColors.secondaryGrey,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.secondaryGrey,
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
                                  const SizedBox(height: 8.0),

                                  // Olvidaste tu contraseña link
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        foregroundColor: AppColors.accentGreen, 
                                      ),
                                      child: Text(
                                        '¿Olvidaste tu contraseña?',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.accentGreen,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: sectionSpacing),

                                  // Button "Iniciar sesion" (using custom AppPrimaryButton with press scaling)
                                  AppPrimaryButton(
                                    text: 'Iniciar sesión',
                                    isLoading: _isLoading,
                                    onPressed: _handleLogin,
                                  ),
                                  
                                  SizedBox(height: sectionSpacing),

                                  // ¿No tienes una cuenta? separator
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: Colors.grey.shade200)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            '¿No tienes una cuenta?',
                                            style: TextStyle(
                                              fontSize: footerFontSize,
                                              color: AppColors.textMain,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: Colors.grey.shade200)),
                                    ],
                                  ),
                                  
                                  const Spacer(),

                                  // Footer (c) 2024 SENA (Color oscuro al estar sobre blanco)
                                  Center(
                                    child: Text(
                                      '(c) 2024 SENA. Todos los derechos reservados.',
                                      style: TextStyle(
                                        fontSize: footerFontSize,
                                        color: AppColors.secondaryGrey,
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
      ),
    );
  }
}


