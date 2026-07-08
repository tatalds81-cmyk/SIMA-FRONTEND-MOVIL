/// Configuración central de la URL base del backend SIMA.
///
/// IMPORTANTE: Cambia [baseUrl] según el entorno donde corres la app:
///
///   Flutter Web / Chrome:
///     flutter run -d chrome --dart-define=SIMA_API_URL=http://localhost:3000/api
///
///   Emulador Android (el host de la máquina virtual):
///     const String baseUrl = 'http://10.0.2.2:3000/api';
///
///   Dispositivo físico (misma red Wi-Fi que la PC):
///     `const String baseUrl = 'http://<IP_LOCAL_PC>:3000/api';`
///     Ej: const String baseUrl = 'http://192.168.1.50:3000/api';
class ApiConfig {
  ApiConfig._(); // Clase no instanciable

  // Backend desplegado para APK de pruebas.
  // Para desarrollo local usa --dart-define=SIMA_API_URL=http://<IP_LOCAL>:3000/api.
  static const String railwayUrl =
      'https://sima-backend-monitoreo-production.up.railway.app/api';

  // Backend local de la PC. En Android fisico se accede mediante:
  // adb reverse tcp:3000 tcp:3000
  static const String localUsbUrl = 'http://127.0.0.1:3000/api';

  static const String baseUrl = String.fromEnvironment(
    'SIMA_API_URL',
    defaultValue: railwayUrl,
  );

  // Endpoints de autenticación
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';

  // Endpoints de aprendiz
  static const String apprenticeDashboard =
      '$baseUrl/apprentice-portal/dashboard';
  static const String myCalendar = '$baseUrl/attendances/my-calendar';
  static const String sessions = '$baseUrl/apprentice-portal/sessions';
  static const String qrAttendance = '$baseUrl/attendances/qr';
  static const String mobileBiometricChallenge =
      '$baseUrl/attendances/mobile-biometric-challenge';
  static const String submitJustification =
      '$baseUrl/attendances/justifications';
  static const String eligibleJustifications =
      '$baseUrl/attendances/justifications/eligible';
  static const String myJustifications =
      '$baseUrl/attendances/justifications/my';
  static const String profileOverview = '$baseUrl/profile/overview';
  static const String profilePhoto = '$baseUrl/profile/photo';
  static const String myObservations = '$baseUrl/observations/my';
  static const String apprenticeObservatoryObservations =
      '$baseUrl/apprentice-portal/observatory/observations';
  static const String apprenticeObservatoryAlerts =
      '$baseUrl/apprentice-portal/observatory/alerts';

  static String observation(String id) => '$baseUrl/observations/$id';
}
