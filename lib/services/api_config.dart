/// Configuración central de la URL base del backend SIMA.
///
/// IMPORTANTE: Cambia [baseUrl] según el entorno donde corres la app:
///
///   Flutter Web / Chrome (localhost):
///     const String baseUrl = 'http://localhost:3000/api';
///
///   Emulador Android (el host de la máquina virtual):
///     const String baseUrl = 'http://10.0.2.2:3000/api';
///
///   Dispositivo físico (misma red Wi-Fi que la PC):
///     const String baseUrl = 'http://<IP_LOCAL_PC>:3000/api';
///     Ej: const String baseUrl = 'http://192.168.1.50:3000/api';
class ApiConfig {
  ApiConfig._(); // Clase no instanciable

  static const String baseUrl = 'http://localhost:3000/api';

  // Endpoints de autenticación
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';

  // Endpoints de aprendiz
  static const String apprenticeDashboard = '$baseUrl/apprentice-portal/dashboard';
  static const String myCalendar = '$baseUrl/attendances/my-calendar';
  static const String sessions = '$baseUrl/apprentice-portal/sessions';
  static const String qrAttendance = '$baseUrl/attendances/qr';
}
