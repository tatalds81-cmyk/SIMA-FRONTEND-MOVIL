import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sima_movil_froned/models/facial_biometrics_models.dart';
import 'package:sima_movil_froned/services/api_config.dart';
import 'package:sima_movil_froned/services/auth_service.dart';
import 'package:sima_movil_froned/services/facial_embedding_engine.dart';

export 'package:sima_movil_froned/models/facial_biometrics_models.dart';
export 'package:sima_movil_froned/services/facial_embedding_engine.dart';

class FacialBiometricsService {
  FacialBiometricsService._();

  static final String deviceUuid =
      'sima-mobile-face-${DateTime.now().millisecondsSinceEpoch}';

  static Map<String, String> _headers() {
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesion activa. Por favor, inicia sesion nuevamente.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static String _cleanError(Object error) {
    final raw = error.toString();
    return raw.startsWith('Exception: ') ? raw.replaceFirst('Exception: ', '') : raw;
  }

  static Future<Map<String, dynamic>> _requestJson(
    String method,
    String url, {
    Map<String, dynamic>? payload,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = method == 'GET'
          ? await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 15))
          : method == 'DELETE'
              ? await http
                  .delete(uri, headers: _headers(), body: jsonEncode(payload ?? const {}))
                  .timeout(const Duration(seconds: 15))
              : await http
                  .post(uri, headers: _headers(), body: jsonEncode(payload ?? const {}))
                  .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300 && body['ok'] == true) {
        return (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      }

      throw Exception(body['message'] ?? 'Error ${response.statusCode}');
    } on Exception catch (error) {
      throw Exception(_cleanError(error));
    }
  }

  static Future<Map<String, dynamic>> getStatus() {
    return _requestJson('GET', ApiConfig.facialStatus);
  }

  static Future<Map<String, dynamic>> acceptConsent() {
    return _requestJson('POST', ApiConfig.facialConsent, payload: const {});
  }

  static Future<Map<String, dynamic>> revokeConsent({String? reason}) {
    return _requestJson(
      'DELETE',
      ApiConfig.facialConsent,
      payload: {'motivo': reason ?? 'Revocacion solicitada desde movil'},
    );
  }

  static Future<Map<String, dynamic>> requestEnrollmentChallenge({
    required String deviceUuid,
  }) {
    return _requestJson(
      'POST',
      ApiConfig.facialEnrollmentChallenge,
      payload: {'device_uuid': deviceUuid},
    );
  }

  static Future<Map<String, dynamic>> enroll({
    required String deviceUuid,
    required String challengeToken,
    required FacialEmbeddingCapture capture,
  }) {
    return _requestJson(
      'POST',
      ApiConfig.facialEnrollment,
      payload: {
        'device_uuid': deviceUuid,
        'challenge_token': challengeToken,
        'embedding': capture.embedding,
        'calidad_captura': capture.quality,
        'liveness_result': capture.livenessResult,
        'liveness_score': capture.livenessScore,
        'proveedor': capture.provider,
        'modelo_version': capture.modelVersion,
      },
    );
  }

  static Future<Map<String, dynamic>> requestValidationChallenge({
    required int sessionId,
    required String deviceUuid,
  }) {
    return _requestJson(
      'POST',
      ApiConfig.facialValidationChallenge,
      payload: {
        'id_sesion_formacion': sessionId,
        'device_uuid': deviceUuid,
      },
    );
  }

  static Future<Map<String, dynamic>> validateAttempt({
    required int sessionId,
    required String deviceUuid,
    required String challengeToken,
    required FacialEmbeddingCapture capture,
  }) {
    return _requestJson(
      'POST',
      ApiConfig.facialValidationAttempt,
      payload: {
        'id_sesion_formacion': sessionId,
        'device_uuid': deviceUuid,
        'challenge_token': challengeToken,
        'embedding': capture.embedding,
        'liveness_result': capture.livenessResult,
        'liveness_score': capture.livenessScore,
        'proveedor': capture.provider,
        'modelo_version': capture.modelVersion,
      },
    );
  }
}
