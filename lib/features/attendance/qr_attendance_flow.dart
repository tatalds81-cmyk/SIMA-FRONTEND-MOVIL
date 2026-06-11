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
      backgroundColor: const Color(0xFF092444), // Azul institucional
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Escanear QR de la sesión',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Stepper Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepItem('1', 'Escanear QR', isActive: true),
                _buildStepConnector(),
                _buildStepItem('2', 'Verificar sesión', isActive: false),
                _buildStepConnector(),
                _buildStepItem('3', 'Confirmar\nasistencia', isActive: false),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // Scanner Area
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Scanner view
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: MobileScanner(
                      controller: controller,
                      onDetect: (capture) async {
                        if (_isProcessing) return;
                        final barcodes = capture.barcodes;
                        if (barcodes.isEmpty) return;
                        final rawValue = barcodes.first.rawValue;
                        if (rawValue == null || rawValue.trim().isEmpty) return;
                        await _processQr(rawValue);
                      },
                    ),
                  ),
                ),
                
                // Decorative Circle Lines overlay
                IgnorePointer(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF39A900), width: 3),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12, width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Botón "Verificar sesión"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Placeholder: la detección automática del QR gatillará el proceso.
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text('Verificar sesión', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39A900),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Flashlight / Linterna
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, state, child) {
              final isFlashOn = state.torchState == TorchState.on || state.torchState == TorchState.auto;
              return GestureDetector(
                onTap: () => controller.toggleTorch(),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: isFlashOn ? Colors.yellow : const Color(0xFF39A900), width: 2),
                      ),
                      child: Icon(
                        isFlashOn ? Icons.highlight : Icons.highlight_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Linterna', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, {required bool isActive}) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? const Color(0xFF39A900) : Colors.white24, width: 2),
            color: Colors.transparent,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isActive ? const Color(0xFF39A900) : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? const Color(0xFF39A900) : Colors.white54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 15),
        height: 2,
        color: Colors.white24,
      ),
    );
  }
}
