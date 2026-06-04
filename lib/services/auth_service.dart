import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Resultado del intento de login.
/// Encapsula éxito, token, datos de usuario o mensaje de error.
class LoginResult {
  final bool ok;
  final String message;
  final String? token;
  final Map<String, dynamic>? user;

  const LoginResult({
    required this.ok,
    required this.message,
    this.token,
    this.user,
  });
}

/// Servicio de autenticación que se comunica con el backend SIMA.
class AuthService {
  AuthService._(); // Clase no instanciable

  /// Token de sesión en memoria
  static String? currentToken;
  
  /// Usuario autenticado en memoria
  static Map<String, dynamic>? currentUser;

  /// Realiza POST /api/auth/login con [documento] y [password].
  ///
  /// El backend acepta tanto `documento` como `numero_documento`.
  /// Usamos `documento` como campo principal.
  ///
  /// Respuesta exitosa del backend:
  /// ```json
  /// {
  ///   "ok": true,
  ///   "message": "Inicio de sesión exitoso",
  ///   "data": {
  ///     "token": "JWT...",
  ///     "user": { "id_usuario": 1, "rol": "aprendiz", ... }
  ///   }
  /// }
  /// ```
  static Future<LoginResult> login({
    required String documento,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.login);

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'documento': documento.trim(),
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(
              'El servidor no respondió. Verifica tu conexión o que el backend esté en línea.',
            ),
          );

      // Intentar decodificar la respuesta como JSON
      Map<String, dynamic> responseBody;
      try {
        responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return const LoginResult(
          ok: false,
          message: 'El servidor devolvió una respuesta inesperada.',
        );
      }

      final bool serverOk = responseBody['ok'] == true;
      final String serverMessage =
          responseBody['message'] as String? ?? 'Sin mensaje del servidor';

      if (response.statusCode == 200 && serverOk) {
        // Éxito: extraer token y user desde response.data.data
        final data = responseBody['data'] as Map<String, dynamic>?;
        final token = data?['token'] as String?;
        final user = data?['user'] as Map<String, dynamic>?;

        // Guardar temporalmente en memoria
        currentToken = token;
        currentUser = user;

        return LoginResult(
          ok: true,
          message: serverMessage,
          token: token,
          user: user,
        );
      } else {
        // Error del servidor (401, 403, 400, etc.) con mensaje real
        return LoginResult(
          ok: false,
          message: serverMessage,
        );
      }
    } on Exception catch (e) {
      // Error de red, timeout u otro error inesperado
      final rawMessage = e.toString();
      final cleanMessage = rawMessage.startsWith('Exception: ')
          ? rawMessage.replaceFirst('Exception: ', '')
          : 'Error de conexión. Verifica que el backend esté corriendo en ${ApiConfig.baseUrl}';
      return LoginResult(ok: false, message: cleanMessage);
    }
  }
}
