import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sima_movil_froned/services/attendance_service.dart';
import 'package:sima_movil_froned/services/facial_biometrics_service.dart';
import 'package:sima_movil_froned/services/hardware/local_auth_service.dart';
import 'package:sima_movil_froned/services/hardware/location_service.dart';

final String _dashboardDeviceUuid =
    'sima-mobile-mvp-${DateTime.now().millisecondsSinceEpoch}';

Future<bool> startDashboardQrFlow(BuildContext context) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const _DashboardQrScannerScreen()),
  );

  return result == true;
}

class _DashboardQrScannerScreen extends StatefulWidget {
  const _DashboardQrScannerScreen();

  @override
  State<_DashboardQrScannerScreen> createState() =>
      _DashboardQrScannerScreenState();
}

class _DashboardQrScannerScreenState extends State<_DashboardQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processQr(String value) async {
    setState(() => _isProcessing = true);
    await _controller.stop();

    if (!mounted) return;

    try {
      if (_isInvalidDesignQr(value)) {
        throw Exception('El código QR no coincide con tu sesión activa.');
      }

      final idSesionActiva = await _getActiveSessionId();

      if (!mounted) return;

      final selectedMethod = await Navigator.of(context)
          .push<_DashboardStepType?>(
            MaterialPageRoute(
              builder: (_) => const _DashboardMethodChoiceStep(),
            ),
          );

      if (selectedMethod == null) {
        if (!mounted) return;
        _controller.start();
        return;
      }

      if (!mounted) return;

      final locationData = await LocationService.getCurrentLocation();

      if (!mounted) return;

      var biometricOutcome = selectedMethod == _DashboardStepType.face
          ? await _runFaceValidation(idSesionActiva)
          : await Navigator.of(context).push<_DashboardBiometricOutcome?>(
              MaterialPageRoute(
                builder: (_) => _DashboardBiometricStep(type: selectedMethod),
              ),
            );

      if (selectedMethod == _DashboardStepType.face &&
          (biometricOutcome == null || !biometricOutcome.approved)) {
        if (!mounted) return;
        await _showFacialFallbackMessage(biometricOutcome);
        if (!mounted) return;
        biometricOutcome =
            await Navigator.of(context).push<_DashboardBiometricOutcome?>(
          MaterialPageRoute(
            builder: (_) => const _DashboardBiometricStep(
              type: _DashboardStepType.fingerprint,
            ),
          ),
        );
      }

      if (biometricOutcome == null || !biometricOutcome.approved) {
        throw Exception(
          selectedMethod == _DashboardStepType.face
              ? 'No se pudo validar la biometria facial ni la biometria del dispositivo. Solicita apoyo al instructor.'
              : 'No se pudo verificar tu huella. Inténtalo nuevamente.',
        );
      }

      final challenge = await AttendanceService.requestMobileBiometricChallenge({
        'id_sesion_formacion': idSesionActiva,
        'token_qr': value,
        'device_uuid': _dashboardDeviceUuid,
        'metodo_solicitado': biometricOutcome.method,
      });

      await AttendanceService.registerQrAttendance({
        'id_sesion_formacion': idSesionActiva,
        'token_qr': value,
        'latitud': locationData['latitud'],
        'longitud': locationData['longitud'],
        'precision': locationData['precision'],
        'mocked': locationData['mocked'],
        'local_auth': true,
        'device_uuid': _dashboardDeviceUuid,
        'biometric_method': biometricOutcome.method,
        'biometric_result': 'APROBADO',
        'biometric_challenge_token': challenge['challenge_token'],
        if (biometricOutcome.facialValidationToken != null)
          'facial_validation_token': biometricOutcome.facialValidationToken,
        'biometric_metadata': {
          'provider': biometricOutcome.provider,
          'attempt_number': biometricOutcome.attemptNumber,
          'duration_ms': biometricOutcome.durationMs,
          'reason': biometricOutcome.reason,
        },
      });

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _DashboardResultDialog(success: true),
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _DashboardResultDialog(
          success: false,
          message: _cleanError(error),
          onRetry: () {
            Navigator.of(context).pop();
            setState(() => _isProcessing = false);
            _controller.start();
          },
        ),
      );
    }
  }

  Future<void> _showFacialFallbackMessage(
    _DashboardBiometricOutcome? outcome,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Facial SIMA no disponible'),
        content: Text(
          outcome?.reason == 'NO_ENROLADO'
              ? 'No tienes un enrolamiento facial activo. Puedes usar la biometria personal del telefono mientras se completa el enrolamiento institucional.'
              : outcome?.reason == 'RECHAZADO'
              ? 'No se pudo aprobar Facial SIMA en los intentos permitidos. Ahora valida con la biometria personal del telefono.'
              : 'En este momento Facial SIMA no esta disponible. Valida con la biometria personal del telefono.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<_DashboardBiometricOutcome> _runFaceValidation(int sessionId) async {
    final startedAt = DateTime.now();
    try {
      var status = await FacialBiometricsService.getStatus();
      final requiresConsent = status['requiere_consentimiento'] == true;

      if (requiresConsent) {
        final accepted = await _confirmFacialConsent();
        if (!accepted) {
          return _DashboardBiometricOutcome(
            method: 'FACIAL_SIMA',
            approved: false,
            provider: 'facial_sima_identity',
            attemptNumber: 1,
            durationMs: DateTime.now().difference(startedAt).inMilliseconds,
            reason: 'CONSENTIMIENTO_PENDIENTE',
          );
        }
        await FacialBiometricsService.acceptConsent();
        status = await FacialBiometricsService.getStatus();
      }

      if (status['requiere_enrolamiento'] == true) {
        return _DashboardBiometricOutcome(
          method: 'FACIAL_SIMA',
          approved: false,
          provider: 'facial_sima_identity',
          attemptNumber: 1,
          durationMs: DateTime.now().difference(startedAt).inMilliseconds,
          reason: 'NO_ENROLADO',
        );
      }

      String lastReason = 'RECHAZADO';
      for (var attempt = 1; attempt <= 3; attempt++) {
        final capture = await _showFacialValidationPreview(attempt);
        if (capture == null) {
          lastReason = 'CANCELADO';
          break;
        }

        final challenge = await FacialBiometricsService.requestValidationChallenge(
          sessionId: sessionId,
          deviceUuid: _dashboardDeviceUuid,
        );
        final validation = await FacialBiometricsService.validateAttempt(
          sessionId: sessionId,
          deviceUuid: _dashboardDeviceUuid,
          challengeToken: challenge['challenge_token']?.toString() ?? '',
          capture: capture,
        );

        final approved = validation['aprobado'] == true;
        if (approved) {
          return _DashboardBiometricOutcome(
            method: 'FACIAL_SIMA',
            approved: true,
            provider: capture.provider,
            attemptNumber: attempt,
            durationMs: DateTime.now().difference(startedAt).inMilliseconds,
            reason: 'OK',
            facialValidationToken:
                validation['facial_validation_token']?.toString(),
          );
        }

        lastReason = validation['motivo']?.toString() ?? 'RECHAZADO';
        if (!mounted) break;
        if (attempt < 3) {
          await _showFacialRetryMessage(attempt, lastReason);
        }
      }

      return _DashboardBiometricOutcome(
        method: 'FACIAL_SIMA',
        approved: false,
        provider: 'facial_sima_identity',
        attemptNumber: 3,
        durationMs: DateTime.now().difference(startedAt).inMilliseconds,
        reason: lastReason,
      );
    } on FacialSimaUnavailableException catch (error) {
      return _DashboardBiometricOutcome(
        method: 'FACIAL_SIMA',
        approved: false,
        provider: 'facial_sima_identity',
        attemptNumber: 1,
        durationMs: DateTime.now().difference(startedAt).inMilliseconds,
        reason: error.message.contains('no esta disponible')
            ? 'NO_DISPONIBLE'
            : 'MOTOR_NO_CONFIGURADO',
      );
    } catch (_) {
      return _DashboardBiometricOutcome(
        method: 'FACIAL_SIMA',
        approved: false,
        provider: 'facial_sima_identity',
        attemptNumber: 1,
        durationMs: DateTime.now().difference(startedAt).inMilliseconds,
        reason: 'ERROR',
      );
    }
  }

  Future<FacialEmbeddingCapture?> _showFacialValidationPreview(int attempt) {
    return Navigator.of(context).push<FacialEmbeddingCapture>(
      MaterialPageRoute(
        builder: (_) => _DashboardFacialValidationStep(attempt: attempt),
      ),
    );
  }

  Future<void> _showFacialRetryMessage(int attempt, String reason) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Rostro no validado'),
        content: Text(
          'Intento $attempt de 3 no aprobado. Motivo: $reason. Puedes intentarlo nuevamente.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmFacialConsent() async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Consentimiento facial'),
        content: const Text(
          'Para usar Facial SIMA debes autorizar el tratamiento de tu embedding facial cifrado. No se guardara imagen ni video de tu rostro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    return accepted == true;
  }

  Future<int> _getActiveSessionId() async {
    final sessionsData = await AttendanceService.getSessions();
    final activeSession = sessionsData?['sesion_activa'];

    if (activeSession is! Map<String, dynamic> ||
        activeSession['id_sesion_formacion'] == null) {
      throw Exception('No hay una sesiÃ³n activa para registrar asistencia.');
    }

    final idSesion = activeSession['id_sesion_formacion'];
    final parsedId =
        idSesion is int ? idSesion : int.tryParse(idSesion.toString());

    if (parsedId == null) {
      throw Exception('No hay una sesiÃ³n activa para registrar asistencia.');
    }

    return parsedId;
  }

  bool _isInvalidDesignQr(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized.contains('invalido') ||
        normalized.contains('error');
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              if (_isProcessing) return;
              final rawValue = capture.barcodes.isEmpty
                  ? null
                  : capture.barcodes.first.rawValue;
              if (rawValue == null || rawValue.trim().isEmpty) return;

              setState(() => _isProcessing = true);
              await _controller.stop();

              if (!mounted) return;

              await _processQr(rawValue);
            },
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 62),
                const _StepProgress(activeStep: 1),
                const SizedBox(height: 18),
                _ScannerLabel(
                  text: _isProcessing
                      ? 'Validando QR...'
                      : 'Escanee el código QR',
                ),
                const Spacer(),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF39A900),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Text(
                    'Alinee el código QR dentro del recuadro',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _DashboardStepType { face, fingerprint }

extension _DashboardStepTypeBackend on _DashboardStepType {
  String get biometricMethod =>
      this == _DashboardStepType.face ? 'FACIAL_SIMA' : 'BIOMETRIA_MOVIL';
}

class _DashboardBiometricOutcome {
  const _DashboardBiometricOutcome({
    required this.method,
    required this.approved,
    required this.provider,
    required this.attemptNumber,
    required this.durationMs,
    required this.reason,
    this.facialValidationToken,
  });

  final String method;
  final bool approved;
  final String provider;
  final int attemptNumber;
  final int durationMs;
  final String reason;
  final String? facialValidationToken;
}

class _DashboardMethodChoiceStep extends StatelessWidget {
  const _DashboardMethodChoiceStep();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF052D4F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF052D4F),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: const Text(
          'Selecciona el método',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              const _StepProgress(activeStep: 2, thirdLabel: 'Biométrico'),
              const SizedBox(height: 22),
              const Text(
                'Elige si deseas validar tu sesión con reconocimiento facial o huella dactilar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Column(
                  children: [
                    _MethodOptionCard(
                      icon: Icons.face_retouching_natural_rounded,
                      title: 'Reconocimiento facial',
                      description: 'Usa tu rostro para validar tu asistencia.',
                      onTap: () =>
                          Navigator.of(context).pop(_DashboardStepType.face),
                    ),
                    const SizedBox(height: 18),
                    _MethodOptionCard(
                      icon: Icons.fingerprint_rounded,
                      title: 'Huella dactilar',
                      description: 'Usa tu huella para validar tu asistencia.',
                      onTap: () => Navigator.of(
                        context,
                      ).pop(_DashboardStepType.fingerprint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodOptionCard extends StatelessWidget {
  const _MethodOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF07375F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF0A4D72),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF7FDB64), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBiometricStep extends StatefulWidget {
  const _DashboardBiometricStep({required this.type});

  final _DashboardStepType type;

  @override
  State<_DashboardBiometricStep> createState() => _DashboardBiometricStepState();
}

class _DashboardBiometricStepState extends State<_DashboardBiometricStep> {
  bool get _isFace => widget.type == _DashboardStepType.face;

  Future<void> _authenticate() async {
    final startedAt = DateTime.now();
    try {
      var attempt = 1;
      var success = false;

      while (attempt <= (_isFace ? 3 : 1)) {
        success = await LocalAuthService.authenticate(
          localizedReason: _isFace
              ? 'Usa Facial SIMA para registrar tu asistencia. Intento $attempt de 3'
              : 'Usa la biometria personal de tu telefono para registrar tu asistencia',
        );
        if (success) break;
        attempt += 1;
      }

      if (!mounted) return;
      Navigator.of(context).pop(
        _DashboardBiometricOutcome(
          method: widget.type.biometricMethod,
          approved: success,
          provider: _isFace ? 'facial_sima_mvp' : 'local_auth_device',
          attemptNumber: attempt.clamp(1, 3).toInt(),
          durationMs: DateTime.now().difference(startedAt).inMilliseconds,
          reason: success ? 'OK' : 'RECHAZADO',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      if (_isFace) {
        Navigator.of(context).pop(
          _DashboardBiometricOutcome(
            method: 'FACIAL_SIMA',
            approved: false,
            provider: 'facial_sima_mvp',
            attemptNumber: 1,
            durationMs: DateTime.now().difference(startedAt).inMilliseconds,
            reason: 'NO_DISPONIBLE',
          ),
        );
        return;
      }
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Error de Biometria'),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        _DashboardBiometricOutcome(
          method: 'BIOMETRIA_MOVIL',
          approved: false,
          provider: 'local_auth_device',
          attemptNumber: 1,
          durationMs: DateTime.now().difference(startedAt).inMilliseconds,
          reason: 'RECHAZADO',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isFace ? 'Reconocimiento facial' : 'Huella dactilar';
    final helper = _isFace
        ? 'Mantenga su rostro dentro del recuadro'
        : 'Coloque su dedo sobre el sensor';
    final actionIcon = _isFace
        ? Icons.face_retouching_natural_rounded
        : Icons.fingerprint_rounded;
    final stepLabel = _isFace ? 'Facial' : 'Huella dactilar';

    return Scaffold(
      backgroundColor: const Color(0xFF052D4F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF052D4F),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              _StepProgress(activeStep: 3, thirdLabel: stepLabel),
              const SizedBox(height: 22),
              Text(
                helper,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Center(child: _BiometricPanel(isFace: _isFace)),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: Icon(actionIcon),
                  label: const Text('Verificar sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39A900),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardFacialValidationStep extends StatefulWidget {
  const _DashboardFacialValidationStep({required this.attempt});

  final int attempt;

  @override
  State<_DashboardFacialValidationStep> createState() =>
      _DashboardFacialValidationStepState();
}

class _DashboardFacialValidationStepState
    extends State<_DashboardFacialValidationStep> {
  late Future<CameraController> _controllerFuture;
  CameraController? _controller;
  String? _errorMessage;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _controllerFuture = _initCamera();
  }

  Future<CameraController> _initCamera() async {
    final previousController = _controller;
    _controller = null;
    await previousController?.dispose();

    final controller = await FacialEmbeddingEngine.createPreviewController();
    _controller = controller;
    return controller;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      setState(() {
        _errorMessage = 'La camara aun no esta lista. Intenta nuevamente.';
      });
      return;
    }

    setState(() {
      _capturing = true;
      _errorMessage = null;
    });

    try {
      final capture =
          await FacialEmbeddingEngine.captureForValidationWithPreview(controller);
      if (!mounted) return;
      Navigator.of(context).pop(capture);
    } on FacialSimaUnavailableException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _cleanErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  String _cleanErrorMessage(Object? error) {
    if (error == null) return 'Revisa la camara e intenta nuevamente.';
    final raw = error.toString();
    final clean = raw.startsWith('Exception: ')
        ? raw.replaceFirst('Exception: ', '')
        : raw;
    return clean.trim().isEmpty ? 'Revisa la camara e intenta nuevamente.' : clean;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF052D4F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF052D4F),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: _capturing ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: Text(
          'Facial SIMA ${widget.attempt}/3',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              const _StepProgress(activeStep: 3, thirdLabel: 'Facial SIMA'),
              const SizedBox(height: 18),
              const Text(
                'Centra tu rostro, mira de frente y presiona capturar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: FutureBuilder<CameraController>(
                  future: _controllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return _DashboardCameraError(
                        message: _cleanErrorMessage(snapshot.error),
                        onRetry: () {
                          setState(() {
                            _errorMessage = null;
                            _controllerFuture = _initCamera();
                          });
                        },
                      );
                    }

                    final controller = snapshot.data!;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: controller.value.previewSize?.height ?? 720,
                              height: controller.value.previewSize?.width ?? 960,
                              child: CameraPreview(controller),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 230,
                              height: 290,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF7FDB64),
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(150),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _DashboardInlineError(message: _errorMessage!),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _capturing ? null : _capture,
                  icon: _capturing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.camera_alt_outlined),
                  label: Text(_capturing ? 'Validando rostro' : 'Capturar rostro'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39A900),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCameraError extends StatelessWidget {
  const _DashboardCameraError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF07375F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Color(0xFF7FDB64),
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudo abrir la camara',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardInlineError extends StatelessWidget {
  const _DashboardInlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFB3262E).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB3262E)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BiometricPanel extends StatelessWidget {
  const _BiometricPanel({required this.isFace});

  final bool isFace;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        decoration: BoxDecoration(
          color: const Color(0xFF07375F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              painter: _ScannerRingPainter(),
              child: const SizedBox.expand(),
            ),
            if (isFace)
              ClipOval(
                child: Image.asset(
                  'assets/images/aprendices_sena.png',
                  width: 190,
                  height: 230,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Icon(
                Icons.fingerprint_rounded,
                color: Color(0xFF7FDB64),
                size: 142,
              ),
            const _CornerGuide(top: 96, left: 78),
            const _CornerGuide(top: 96, right: 78, flipX: true),
            const _CornerGuide(bottom: 96, left: 78, flipY: true),
            const _CornerGuide(bottom: 96, right: 78, flipX: true, flipY: true),
          ],
        ),
      ),
    );
  }
}

class _CornerGuide extends StatelessWidget {
  const _CornerGuide({
    this.top,
    this.right,
    this.bottom,
    this.left,
    this.flipX = false,
    this.flipY = false,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final bool flipX;
  final bool flipY;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(flipX ? -1 : 1, flipY ? -1 : 1, 1),
        child: CustomPaint(
          size: const Size(28, 28),
          painter: _CornerGuidePainter(),
        ),
      ),
    );
  }
}

class _CornerGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7FDB64)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(size.width * 0.55, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height * 0.55), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerGuidePainter oldDelegate) => false;
}

class _ScannerRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final background = Paint()
      ..color = const Color(0xFF1A5175).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final accent = Paint()
      ..color = const Color(0xFF7FDB64)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (final radius in [78.0, 112.0, 146.0]) {
      canvas.drawCircle(center, radius, background);
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 146),
      -math.pi / 2,
      math.pi * 1.25,
      false,
      accent,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerRingPainter oldDelegate) => false;
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.activeStep,
    this.thirdLabel = 'Biométrico',
  });

  final int activeStep;
  final String thirdLabel;

  @override
  Widget build(BuildContext context) {
    final labels = ['Escanear QR', 'Elegir método', thirdLabel];

    return Row(
      children: List.generate(3, (index) {
        final step = index + 1;
        final done = step <= activeStep;
        final color = done ? const Color(0xFF7FDB64) : Colors.white70;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: step == activeStep
                            ? const Color(0xFF39A900)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '$step',
                          style: TextStyle(
                            color: step == activeStep ? Colors.white : color,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < 2)
                Container(
                  width: 28,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 22),
                  color: activeStep > step
                      ? const Color(0xFF7FDB64)
                      : Colors.white24,
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _ScannerLabel extends StatelessWidget {
  const _ScannerLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DashboardResultDialog extends StatelessWidget {
  const _DashboardResultDialog({
    required this.success,
    this.message,
    this.onRetry,
  });

  final bool success;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final accent = success ? const Color(0xFF39A900) : const Color(0xFFB3262E);
    final soft = success ? const Color(0xFFE6F7E6) : const Color(0xFFFFE8EA);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () =>
                    success ? Navigator.of(context).pop() : onRetry?.call(),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF607086)),
              ),
            ),
            Image.asset(
              'assets/images/aprendices_sena.png',
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
              child: Icon(
                success ? Icons.check_rounded : Icons.close_rounded,
                color: accent,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              success
                  ? '¡Asistencia registrada!'
                  : 'No se pudo registrar\nla asistencia',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF092444),
                fontSize: 20,
                height: 1.08,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Container(width: 60, height: 2, color: accent),
            const SizedBox(height: 14),
            Text(
              success
                  ? 'Tu asistencia ha sido registrada\ncorrectamente.'
                  : (message ?? 'Ocurrió un error. Inténtalo nuevamente.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF20334D),
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () =>
                    success ? Navigator.of(context).pop() : onRetry?.call(),
                icon: Icon(
                  success
                      ? Icons.calendar_today_outlined
                      : Icons.refresh_rounded,
                  color: accent,
                ),
                label: Text(
                  success ? 'Ver mi próxima sesión' : 'Intentar nuevamente',
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF052D4F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
