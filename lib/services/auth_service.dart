import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class LoginResult {
  const LoginResult({
    required this.ok,
    required this.message,
    this.token,
    this.user,
  });

  final bool ok;
  final String message;
  final String? token;
  final Map<String, dynamic>? user;
}

class AuthService {
  AuthService._();

  static String? currentToken;
  static Map<String, dynamic>? currentUser;

  static Future<LoginResult> login({
    required String documento,
    required String password,
  }) async {
    try {
      final response = await _postLogin(
        documento: documento.trim(),
        password: password,
      );

      final Map<String, dynamic> body;
      try {
        body =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } catch (_) {
        return const LoginResult(
          ok: false,
          message: 'El servidor devolvi\u00f3 una respuesta inesperada.',
        );
      }

      final serverMessage =
          body['message'] as String? ??
          'El servidor no devolvi\u00f3 ning\u00fan mensaje.';
      final success =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['ok'] == true;

      if (!success) {
        return LoginResult(ok: false, message: serverMessage);
      }

      final data = body['data'] as Map<String, dynamic>?;
      final token = data?['token'] as String?;
      final user = data?['user'] as Map<String, dynamic>?;
      if (token == null || token.isEmpty || user == null) {
        return const LoginResult(
          ok: false,
          message: 'La sesi\u00f3n recibida no es v\u00e1lida.',
        );
      }

      currentToken = token;
      currentUser = user;
      return LoginResult(
        ok: true,
        message: serverMessage,
        token: token,
        user: user,
      );
    } on TimeoutException {
      return const LoginResult(
        ok: false,
        message:
            'El servidor est\u00e1 tardando en responder. Intenta nuevamente en unos segundos.',
      );
    } on SocketException {
      return const LoginResult(
        ok: false,
        message:
            'No hay conexi\u00f3n con el servidor. Revisa el internet del celular.',
      );
    } on http.ClientException {
      return const LoginResult(
        ok: false,
        message:
            'No fue posible establecer una conexi\u00f3n segura con el servidor.',
      );
    } catch (_) {
      return const LoginResult(
        ok: false,
        message: 'Ocurri\u00f3 un error inesperado al iniciar sesi\u00f3n.',
      );
    }
  }

  static Future<http.Response> _postLogin({
    required String documento,
    required String password,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await http
            .post(
              Uri.parse(ApiConfig.login),
              headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({'documento': documento, 'password': password}),
            )
            .timeout(const Duration(seconds: 35));
      } on TimeoutException catch (error) {
        lastError = error;
      } on SocketException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      }

      if (attempt == 0) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }

    if (lastError is TimeoutException) throw lastError;
    if (lastError is SocketException) throw lastError;
    if (lastError is http.ClientException) throw lastError;
    throw http.ClientException('No fue posible conectar con el servidor.');
  }
}
