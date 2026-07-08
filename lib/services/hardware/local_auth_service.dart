import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  static final _auth = LocalAuthentication();

  static Future<bool> authenticate({String? localizedReason}) async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        throw Exception(
          'El dispositivo no soporta autenticación biométrica ni PIN/patrón nativo.',
        );
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason:
            localizedReason ??
            'Por favor, autentícate para registrar tu asistencia',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable') {
        throw Exception('Seguridad no configurada en el dispositivo.');
      } else if (e.code == 'NotEnrolled') {
        throw Exception('No hay huellas o PIN configurados en el dispositivo.');
      }
      throw Exception('Error al autenticar: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado de autenticación local.');
    }
  }
}
