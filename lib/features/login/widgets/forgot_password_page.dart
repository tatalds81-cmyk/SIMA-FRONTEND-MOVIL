import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState
    extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _documentController =
      TextEditingController();

  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _documentController.dispose();
    super.dispose();
  }

  Future<void> _handleRecovery() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    // Simulación de petición backend
    await Future.delayed(
      const Duration(seconds: 1),
    );

    setState(() {
      _loading = false;
      _message =
          'Revisa tu correo institucional para continuar el proceso de recuperación.';
      _documentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            const Color(0xFF052D4F),
        title: const Text(
          'Recuperar contraseña',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Card principal
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    border: Border.all(
                      color: const Color(
                        0xFFDFE5EC,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF092444,
                        ).withOpacity(0.06),
                        offset:
                            const Offset(0, 10),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'Restablecer contraseña',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight:
                              FontWeight.w800,
                          color: Color(
                            0xFF092444,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      const Text(
                        'Ingresa tu documento institucional para recuperar el acceso.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(
                            0xFF596879,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      // Campo documento
                      TextFormField(
                        controller:
                            _documentController,
                        keyboardType:
                            TextInputType
                                .number,
                        decoration:
                            InputDecoration(
                          labelText:
                              'Documento',
                          hintText:
                              'Ingresa tu número de documento',
                          prefixIcon:
                              const Icon(
                            Icons
                                .badge_outlined,
                            color: Color(
                              0xFF566577,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              Colors.white,
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                            borderSide:
                                const BorderSide(
                              color: Color(
                                0xFFCFD6DF,
                              ),
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                            borderSide:
                                const BorderSide(
                              color: Color(
                                0xFF39A900,
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Por favor ingresa tu documento';
                          }
                          return null;
                        },
                      ),

                      // Mensaje éxito
                      if (_message !=
                          null) ...[
                        const SizedBox(
                          height: 20,
                        ),

                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(14),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.green
                                    .withOpacity(
                              0.08,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                            border: Border.all(
                              color:
                                  Colors.green,
                            ),
                          ),
                          child: Text(
                            _message!,
                            style:
                                const TextStyle(
                              color:
                                  Colors.green,
                              fontWeight:
                                  FontWeight
                                      .w500,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 32,
                      ),

                      // Botón
                      SizedBox(
                        width:
                            double.infinity,
                        height: 54,
                        child:
                            ElevatedButton(
                          onPressed:
                              _loading
                                  ? null
                                  : _handleRecovery,
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                              0xFF39A900,
                            ),
                            foregroundColor:
                                Colors.white,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    color:
                                        Colors
                                            .white,
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Text(
                                  'Solicitar recuperación',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}