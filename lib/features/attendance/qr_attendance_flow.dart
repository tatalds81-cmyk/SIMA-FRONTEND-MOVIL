import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sima_movil_froned/services/attendance_service.dart';
import 'package:sima_movil_froned/services/hardware/local_auth_service.dart';
import 'package:sima_movil_froned/services/hardware/location_service.dart';

Future<bool> startQrAttendanceFlow(BuildContext context) async {
  final scaffold = ScaffoldMessenger.of(context);

  _showLoadingDialog(context, 'Validando sesión activa...');

  Map<String, dynamic>? sessionsData;
  try {
    sessionsData = await AttendanceService.getSessions();
  } catch (error) {
    if (context.mounted) {
      Navigator.of(context).pop();
      scaffold.showSnackBar(
        SnackBar(
          content: Text(_normalizeQrError(error)),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }

  if (!context.mounted) {
    return false;
  }
  Navigator.of(context).pop();

  final sesionActiva = sessionsData?['sesion_activa'];
  if (sesionActiva is! Map<String, dynamic> ||
      sesionActiva['id_sesion_formacion'] == null) {
    scaffold.showSnackBar(
      const SnackBar(
        content: Text('No hay una sesión activa para registrar asistencia.'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  // Punto de extension futuro: validacion facial SIMA antes de abrir scanner.
  final idSesion = sesionActiva['id_sesion_formacion'];
  final idSesionActiva = idSesion is int
      ? idSesion
      : int.tryParse(idSesion.toString());

  if (idSesionActiva == null) {
    scaffold.showSnackBar(
      const SnackBar(
        content: Text('No hay una sesión activa para registrar asistencia.'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => QrAttendanceScannerScreen(
        idSesionActiva: idSesionActiva,
      ),
    ),
  );

  return result == true;
}

void _showLoadingDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF39A900)),
          const SizedBox(height: 20),
          Text(message),
        ],
      ),
    ),
  );
}

String _normalizeQrError(Object error) {
  final raw = error.toString().replaceFirst('Exception: ', '').trim();
  final value = raw.toLowerCase();

  if (value.contains('sesion') && value.contains('no') && value.contains('act')) {
    return 'La sesión ya no está activa. No es posible registrar asistencia.';
  }
  if (value.contains('sesión') && value.contains('no') && value.contains('act')) {
    return 'La sesión ya no está activa. No es posible registrar asistencia.';
  }
  if (value.contains('grupo') ||
      value.contains('ficha') ||
      value.contains('pertenece') ||
      value.contains('corresponde')) {
    return 'Este QR no corresponde a tu ficha activa.';
  }
  if (value.contains('seleccionar') ||
      value.contains('seleccion') ||
      value.contains('selección') ||
      value.contains('id_grupo')) {
    return 'Debes seleccionar una ficha activa antes de registrar asistencia.';
  }
  if (raw.isEmpty) {
    return 'No fue posible registrar la asistencia.';
  }

  return raw;
}

class QrAttendanceScannerScreen extends StatefulWidget {
  const QrAttendanceScannerScreen({
    super.key,
    required this.idSesionActiva,
  });

  final int idSesionActiva;

  @override
  State<QrAttendanceScannerScreen> createState() =>
      _QrAttendanceScannerScreenState();
}

class _QrAttendanceScannerScreenState extends State<QrAttendanceScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _processQr(String tokenQr) async {
    setState(() => _isProcessing = true);
    await controller.stop();

    if (!mounted) {
      return;
    }

    _showLoadingDialog(context, 'Validando ubicación y seguridad...');

    try {
      final authSuccess = await LocalAuthService.authenticate();
      if (!authSuccess) {
        throw Exception('No se pudo validar tu identidad en el dispositivo.');
      }

      final locationData = await LocationService.getCurrentLocation();
      final payload = {
        'id_sesion_formacion': widget.idSesionActiva,
        'token_qr': tokenQr,
        'latitud': locationData['latitud'],
        'longitud': locationData['longitud'],
        'precision': locationData['precision'],
        'mocked': locationData['mocked'],
        'local_auth': true,
      };

      await AttendanceService.registerQrAttendance(payload);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF39A900), size: 30),
              SizedBox(width: 10),
              Text('Éxito'),
            ],
          ),
          content: const Text('Asistencia registrada correctamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Aceptar',
                style: TextStyle(color: Color(0xFF39A900)),
              ),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error de Registro'),
          content: Text(_normalizeQrError(error)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _isProcessing = false);
                controller.start();
              },
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Color(0xFF39A900)),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                  case TorchState.auto:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                  case CameraFacing.unknown:
                  case CameraFacing.external:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              if (_isProcessing) {
                return;
              }

              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) {
                return;
              }

              final rawValue = barcodes.first.rawValue;
              if (rawValue == null || rawValue.trim().isEmpty) {
                return;
              }

              await _processQr(rawValue);
            },
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Busque un código',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: Container(
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
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Text(
                    'Alinee el código QR dentro del marco',
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
