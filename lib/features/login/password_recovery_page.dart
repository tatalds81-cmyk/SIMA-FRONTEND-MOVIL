import 'package:flutter/material.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final _formKey = GlobalKey<FormState>();
  final _documentController = TextEditingController();

  @override
  void dispose() {
    _documentController.dispose();
    super.dispose();
  }

  void _requestRecoveryCode() {
    if (!_formKey.currentState!.validate()) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF7E7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.engineering_outlined,
            color: Color(0xFF39A900),
            size: 28,
          ),
        ),
        title: const Text(
          'Conexión pendiente',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF092444),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'El diseño ya está listo. El envío del código se habilitará cuando el endpoint de recuperación esté disponible.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF607086), height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF092F4F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF092444),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 18),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recuperar contraseña',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Acceso seguro a tu cuenta SIMA',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F5FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7E7),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: Color(0xFF39A900),
                              size: 38,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Center(
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF092444),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Ingresa tu documento. Te enviaremos un código para verificar tu identidad y crear una nueva contraseña.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF607086),
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE1E7EF)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF092444)
                                    .withValues(alpha: 0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Documento de identidad',
                                style: TextStyle(
                                  color: Color(0xFF092444),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _documentController,
                                keyboardType: TextInputType.number,
                                autofillHints: const [AutofillHints.username],
                                decoration: InputDecoration(
                                  hintText: 'Escribe tu número de documento',
                                  prefixIcon: const Icon(
                                    Icons.badge_outlined,
                                    color: Color(0xFF607086),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFD),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(13),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD5DDE7),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(13),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD5DDE7),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(13),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF39A900),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  final document = value?.trim() ?? '';
                                  if (document.isEmpty) {
                                    return 'Ingresa tu número de documento';
                                  }
                                  if (document.length < 5) {
                                    return 'Verifica el número de documento';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FilledButton.icon(
                                  onPressed: _requestRecoveryCode,
                                  icon: const Icon(Icons.mark_email_read_outlined),
                                  label: const Text('Solicitar código'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF39A900),
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _RecoverySteps(),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text('Volver a iniciar sesión'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF092444),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _RecoverySteps extends StatelessWidget {
  const _RecoverySteps();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F2FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4E2EF)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo funciona?',
            style: TextStyle(
              color: Color(0xFF092444),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          _RecoveryStep(number: '1', text: 'Verificamos tu documento.'),
          _RecoveryStep(number: '2', text: 'Enviamos un código de seguridad.'),
          _RecoveryStep(number: '3', text: 'Creas una contraseña nueva.'),
        ],
      ),
    );
  }
}

class _RecoveryStep extends StatelessWidget {
  const _RecoveryStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF092F4F),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF607086),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
