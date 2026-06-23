import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_config.dart';
import 'auth_service.dart';

class AttendanceService {
  AttendanceService._();

  /// Consume GET /api/apprentice-portal/dashboard
  /// Requiere que AuthService.currentToken no sea nulo.
  static Future<Map<String, dynamic>?> getDashboard() async {
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa. Por favor, inicia sesión nuevamente.');
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/apprentice-portal/dashboard');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['ok'] == true && body['data'] != null) {
          return body['data'] as Map<String, dynamic>;
        } else {
          throw Exception(body['message'] ?? 'Error desconocido del servidor');
        }
      } else {
        // Manejo de errores HTTP
        String errorMessage = 'Error ${response.statusCode}';
        try {
          final body = jsonDecode(response.body);
          if (body['message'] != null) {
            errorMessage = body['message'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } on Exception catch (e) {
      final rawMessage = e.toString();
      final cleanMessage = rawMessage.startsWith('Exception: ')
          ? rawMessage.replaceFirst('Exception: ', '')
          : 'Error de red al conectar con el servidor.';
      throw Exception(cleanMessage);
    }
  }

  static Future<Map<String, dynamic>?> getMyCalendar({
   String? periodo,
   String? fechaReferencia, 
  }) async {
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa. Por favor, inicia sesión nuevamente.');
    }

    try {
      final queryParams = <String, String>{};// elimine la linea: final uri = Uri.parse(ApiConfig.myCalendar);
      if (periodo != null) queryParams['periodo'] = periodo;// se add esto
      if (fechaReferencia != null) queryParams['fecha_referencia'] = fechaReferencia;// esto

      final uri = Uri.parse(ApiConfig.myCalendar)//esto
         .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null); //esto
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['ok'] == true && body['data'] != null) {
          return body['data'] as Map<String, dynamic>;
        } else {
          throw Exception(body['message'] ?? 'Error desconocido del servidor');
        }
      } else {
        // Manejo de errores HTTP
        String errorMessage = 'Error ${response.statusCode}';
        try {
          final body = jsonDecode(response.body);
          if (body['message'] != null) {
            errorMessage = body['message'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } on Exception catch (e) {
      final rawMessage = e.toString();
      final cleanMessage = rawMessage.startsWith('Exception: ')
          ? rawMessage.replaceFirst('Exception: ', '')
          : 'Error de red al conectar con el servidor.';
      throw Exception(cleanMessage);
    }
  }

  /// Consume GET /api/apprentice-portal/sessions
  /// Retorna la sesión activa y próximas sesiones del aprendiz.
  static Future<Map<String, dynamic>?> getSessions() async {
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa. Por favor, inicia sesión nuevamente.');
    }

    try {
      final uri = Uri.parse(ApiConfig.sessions);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['ok'] == true && body['data'] != null) {
          return body['data'] as Map<String, dynamic>;
        } else {
          throw Exception(body['message'] ?? 'Error desconocido del servidor');
        }
      } else {
        String errorMessage = 'Error ${response.statusCode}';
        try {
          final body = jsonDecode(response.body);
          if (body['message'] != null) {
            errorMessage = body['message'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } on Exception catch (e) {
      final rawMessage = e.toString();
      final cleanMessage = rawMessage.startsWith('Exception: ')
          ? rawMessage.replaceFirst('Exception: ', '')
          : 'Error de red al conectar con el servidor.';
      throw Exception(cleanMessage);
    }
  }
  /// Registra la asistencia mediante código QR usando coordenadas y biometría
  static Future<void> registerQrAttendance(Map<String, dynamic> payload) async {
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa. Por favor, inicia sesión nuevamente.');
    }

    try {
      final uri = Uri.parse(ApiConfig.qrAttendance);
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['ok'] == true) {
          return; // Éxito
        } else {
          throw Exception(body['message'] ?? 'Error desconocido del servidor');
        }
      } else {
        String errorMessage = 'Error ${response.statusCode}';
        try {
          final body = jsonDecode(response.body);
          if (body['message'] != null) {
            errorMessage = body['message'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } on Exception catch (e) {
      final rawMessage = e.toString();
      final cleanMessage = rawMessage.startsWith('Exception: ')
          ? rawMessage.replaceFirst('Exception: ', '')
          : 'Error de red al conectar con el servidor.';
      throw Exception(cleanMessage);
    }
  }

  static Future<void> submitJustification({
    required String attendanceId,
    required String description,
    required PlatformFile file,
  }) async {
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa. Por favor, inicia sesión nuevamente.');
    }

    try {
      final uri = Uri.parse(ApiConfig.submitJustification);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.fields['id_asistencia'] = attendanceId;
      request.fields['comentario_aprendiz'] = description;
      final extension = file.extension?.toLowerCase();
      final contentType = extension == 'pdf'
          ? MediaType('application', 'pdf')
          : MediaType('image', 'png');

      if (file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'soporte',
          file.bytes!,
          filename: file.name,
          contentType: contentType,
        ));
      } else if (file.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'soporte',
          file.path!,
          filename: file.name,
          contentType: contentType,
        ));
      } else {
        throw Exception('No se pudo cargar el archivo de justificación.');
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['ok'] == true) {
          return;
        } else {
          throw Exception(body['message'] ?? 'Error desconocido del servidor');
        }
      } else {
        String errorMessage = 'Error ${response.statusCode}';
        try {
          final body = jsonDecode(response.body);
          if (body['message'] != null) {
            errorMessage = body['message'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } on Exception catch (e) {
      final rawMessage = e.toString();
      final cleanMessage = rawMessage.startsWith('Exception: ')
          ? rawMessage.replaceFirst('Exception: ', '')
          : 'Error de red al conectar con el servidor.';
      throw Exception(cleanMessage);
    }
  }

  static Future<Map<String, dynamic>?> getEligibleJustifications() async {
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesiÃ³n activa. Por favor, inicia sesiÃ³n nuevamente.');
    }

    try {
      final uri = Uri.parse(ApiConfig.eligibleJustifications);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['ok'] == true && body['data'] != null) {
          return body['data'] as Map<String, dynamic>;
        }
        throw Exception(body['message'] ?? 'Error desconocido del servidor');
      }

      String errorMessage = 'Error ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        if (body['message'] != null) {
          errorMessage = body['message'];
        }
      } catch (_) {}
      throw Exception(errorMessage);
    } on Exception catch (e) {
      final rawMessage = e.toString();
      final cleanMessage = rawMessage.startsWith('Exception: ')
          ? rawMessage.replaceFirst('Exception: ', '')
          : 'Error de red al conectar con el servidor.';
      throw Exception(cleanMessage);
    }
  }

  static Future<Map<String, dynamic>?> getMyJustifications() async {
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesiÃ³n activa. Por favor, inicia sesiÃ³n nuevamente.');
    }

    try {
      final uri = Uri.parse(ApiConfig.myJustifications);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['ok'] == true && body['data'] != null) {
          return body['data'] as Map<String, dynamic>;
        }
        throw Exception(body['message'] ?? 'Error desconocido del servidor');
      }

      String errorMessage = 'Error ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        if (body['message'] != null) {
          errorMessage = body['message'];
        }
      } catch (_) {}
      throw Exception(errorMessage);
    } on Exception catch (e) {
      final rawMessage = e.toString();
      final cleanMessage = rawMessage.startsWith('Exception: ')
          ? rawMessage.replaceFirst('Exception: ', '')
          : 'Error de red al conectar con el servidor.';
      throw Exception(cleanMessage);
    }
  }
}
