import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sima_movil_froned/features/access.dart';
import 'package:sima_movil_froned/services/auth_service.dart';

import 'password_recovery_page.dart';
import 'widgets/custom_button.dart';
import 'widgets/custom_input.dart';

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
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await AuthService.login(
      documento: _documentController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.ok
            ? const Color(0xFF39A900)
            : const Color(0xFFD32F2F),
      ),
    );

    if (result.ok) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccessPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF062B50),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF041E39), Color(0xFF073B68)],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 700;
                final keyboardOpen =
                    MediaQuery.viewInsetsOf(context).bottom > 0;
                final content = Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: compact ? 8 : 14,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/sima_logo.png',
                            width: compact ? 56 : 68,
                            height: compact ? 56 : 68,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Bienvenido a SIMA',
                            style: TextStyle(
                              color: Color(0xFF13A9E7),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: compact ? 5 : 8),
                          Text(
                            'Sistema Integral de Monitoreo del Aprendiz',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 21 : 24,
                              height: 1.08,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Seguimiento acad\u00e9mico de los aprendices.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .75),
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: compact ? 9 : 13),
                          _buildCard(context),
                          const SizedBox(height: 9),
                          const Text(
                            '\u00a9 2026 SENA. Todos los derechos reservados.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: keyboardOpen
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: keyboardOpen ? 0 : constraints.maxHeight,
                    ),
                    child: content,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .2),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Iniciar sesi\u00f3n',
              style: TextStyle(
                color: Color(0xFF092444),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Ingresa tus credenciales para continuar',
              style: TextStyle(color: Color(0xFF657184), fontSize: 13),
            ),
            const SizedBox(height: 13),
            const _FieldLabel('Documento de identidad'),
            const SizedBox(height: 5),
            CustomInput(
              controller: _documentController,
              hintText: 'N\u00famero de documento',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.badge_outlined, size: 21),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa tu documento'
                  : null,
            ),
            const SizedBox(height: 9),
            const _FieldLabel('Contrase\u00f1a'),
            const SizedBox(height: 5),
            CustomInput(
              controller: _passwordController,
              hintText: 'Ingresa tu contrase\u00f1a',
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outline, size: 21),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 21,
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Ingresa tu contrase\u00f1a'
                  : null,
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PasswordRecoveryPage(),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFF009BDD),
                ),
                child: const Text(
                  '\u00bfOlvidaste tu contrase\u00f1a?',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 14),
            CustomButton(
              text: _isLoading ? 'Verificando...' : 'Iniciar sesi\u00f3n',
              height: 48,
              gradient: const LinearGradient(
                colors: [Color(0xFF42B900), Color(0xFF269000)],
              ),
              onPressed: _isLoading ? null : _handleLogin,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF092444),
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );
}
