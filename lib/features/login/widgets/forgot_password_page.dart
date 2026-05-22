import 'package:flutter/material.dart';
import '../../../core/theme/sima_colors.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState
    extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _documentoCtrl =
      TextEditingController();

  String? _mensaje;
  bool _loading = false;

  @override
  void dispose() {
    _documentoCtrl.dispose();
    super.dispose();
  }

  Future<void> _restablecerPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _mensaje = null;
    });

    // Simulación de petición backend
    await Future.delayed(
      const Duration(milliseconds: 600),
    );

    setState(() {
      _loading = false;

      _mensaje =
          'Te enviamos instrucciones de recuperación a tu correo institucional.';

      _documentoCtrl.clear();
    });
  }

  // ─────────────────────────────────────────────
  // Hero superior
  // ─────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SimaColors.navy,
            SimaColors.navy2,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          // Decoración circular
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SimaColors.green.withOpacity(
                  0.20,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              28,
              52,
              28,
              40,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Botón volver
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Volver',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Marca
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          const BoxDecoration(
                        color: SimaColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 8),

                    const Text(
                      'SENA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Eyebrow
                const Text(
                  'Recuperación de acceso',
                  style: TextStyle(
                    color: SimaColors.cyan,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                // Título
                const Text(
                  'Restablece tu\ncontraseña',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 12),

                // Descripción
                Text(
                  'Valida tu documento institucional para continuar con el proceso de recuperación.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(
                      0.85,
                    ),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Mensaje informativo
  // ─────────────────────────────────────────────
  Widget _buildMensaje() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: SimaColors.infoBg,
        border: Border.all(
          color: SimaColors.infoBorder,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: SimaColors.linkBlue,
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _mensaje!,
              style: const TextStyle(
                color: SimaColors.text,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Campo documento
  // ─────────────────────────────────────────────
  Widget _buildDocumentField() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Documento',
          style: TextStyle(
            color: SimaColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 10),

        TextFormField(
          controller: _documentoCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: SimaColors.text,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText:
                'Ingresa tu número de documento',

            hintStyle: const TextStyle(
              color: Color(0xFF8A95A3),
              fontSize: 16,
            ),

            prefixIcon: const Icon(
              Icons.badge_outlined,
              color: Color(0xFF566577),
              size: 22,
            ),

            filled: true,
            fillColor: Colors.white,

            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 0,
            ),

            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: SimaColors.inputBorder,
              ),
            ),

            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: SimaColors.inputBorder,
              ),
            ),

            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: SimaColors.green,
                width: 1.5,
              ),
            ),

            errorBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.5,
              ),
            ),

            focusedErrorBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.5,
              ),
            ),

            constraints: const BoxConstraints(
              minHeight: 56,
            ),
          ),

          validator: (v) {
            if (v == null ||
                v.trim().isEmpty) {
              return 'Campo requerido';
            }

            return null;
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Botones
  // ─────────────────────────────────────────────
  Widget _buildActions() {
    return Row(
      children: [
        // Botón volver
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },

            style: OutlinedButton.styleFrom(
              minimumSize:
                  const Size(double.infinity, 54),

              side: const BorderSide(
                color: SimaColors.green,
                width: 1.5,
              ),

              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(8),
              ),

              foregroundColor:
                  SimaColors.greenDark,

              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            child: const Text('Volver'),
          ),
        ),

        const SizedBox(width: 12),

        // Botón solicitar
        Expanded(
          flex: 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SimaColors.green,
                  SimaColors.greenDark,
                ],
              ),

              borderRadius:
                  BorderRadius.circular(8),

              boxShadow: [
                BoxShadow(
                  color: SimaColors.greenDark
                      .withOpacity(0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),

            child: ElevatedButton(
              onPressed: _loading
                  ? null
                  : _restablecerPassword,

              style: ElevatedButton.styleFrom(
                minimumSize:
                    const Size(
                  double.infinity,
                  54,
                ),

                backgroundColor:
                    Colors.transparent,

                shadowColor:
                    Colors.transparent,

                disabledBackgroundColor:
                    Colors.transparent,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                ),

                textStyle:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w800,
                ),

                foregroundColor:
                    Colors.white,
              ),

              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Solicitar restablecimiento',
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Card formulario
  // ─────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 28,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: SimaColors.border,
        ),

        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF092444,
            ).withOpacity(0.10),

            blurRadius: 32,

            offset: const Offset(0, 12),
          ),
        ],
      ),

      child: Form(
        key: _formKey,

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Recuperar contraseña',
              style: TextStyle(
                color: SimaColors.text,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Ingresa tu número de documento para continuar',
              style: TextStyle(
                color: SimaColors.subtitle,
                fontSize: 15,
              ),
            ),

            if (_mensaje != null) ...[
              const SizedBox(height: 18),
              _buildMensaje(),
            ],

            const SizedBox(height: 22),

            _buildDocumentField(),

            const SizedBox(height: 24),

            _buildActions(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Build principal
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFC),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Hero
              _buildHero(),

              // Card
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  28,
                  18,
                  32,
                ),

                child: _buildCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}