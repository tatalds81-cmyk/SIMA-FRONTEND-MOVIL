import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sima_movil_froned/features/observatory/models/observation.dart';
import 'package:sima_movil_froned/services/api_config.dart';
import 'package:sima_movil_froned/services/auth_service.dart';

abstract class ObservationsRepository {
  Future<ObservationDashboard> fetchCurrentApprenticeObservations();

  Future<void> registerObservationAction({
    required String observationId,
    required ObservationActionType actionType,
  });
}

class MockObservationsRepository implements ObservationsRepository {
  const MockObservationsRepository();

  @override
  Future<ObservationDashboard> fetchCurrentApprenticeObservations() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return ObservationDashboard.fromJson(_mockResponse);
  }

  @override
  Future<void> registerObservationAction({
    required String observationId,
    required ObservationActionType actionType,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
  }
}

class BackendObservationsRepository implements ObservationsRepository {
  const BackendObservationsRepository();

  @override
  Future<ObservationDashboard> fetchCurrentApprenticeObservations() async {
    final data = await _sendJson(method: 'GET', url: ApiConfig.myObservations);
    final dashboardJson = _normalizeObservationsResponse(data);

    return ObservationDashboard.fromJson(dashboardJson);
  }

  @override
  Future<void> registerObservationAction({
    required String observationId,
    required ObservationActionType actionType,
  }) async {
    if (observationId.isEmpty || actionType == ObservationActionType.none) {
      return;
    }

    await _sendJson(
      method: 'PATCH',
      url: ApiConfig.observation(observationId),
      payload: {'action_type': actionType.backendValue},
    );
  }
}

Future<Map<String, dynamic>> _sendJson({
  required String method,
  required String url,
  Map<String, dynamic>? payload,
}) async {
  final token = AuthService.currentToken;
  if (token == null || token.isEmpty) {
    throw Exception(
      'No hay sesion activa. Por favor, inicia sesion nuevamente.',
    );
  }

  final uri = Uri.parse(url);
  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  try {
    late final http.Response response;
    switch (method) {
      case 'GET':
        response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 15));
      case 'PATCH':
        response = await http
            .patch(uri, headers: headers, body: jsonEncode(payload ?? const {}))
            .timeout(const Duration(seconds: 15));
      default:
        throw Exception('Metodo HTTP no soportado: $method');
    }

    return _decodeResponse(response);
  } on Exception catch (e) {
    final rawMessage = e.toString();
    final cleanMessage = rawMessage.startsWith('Exception: ')
        ? rawMessage.replaceFirst('Exception: ', '')
        : 'Error de red al conectar con el servidor.';
    throw Exception(cleanMessage);
  }
}

Map<String, dynamic> _decodeResponse(http.Response response) {
  if (response.statusCode == 204) {
    return const {};
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(response.body);
  } catch (_) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return const {};
    }
    throw Exception('El servidor devolvio una respuesta inesperada.');
  }

  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['ok'] == false) {
        throw Exception(decoded['message'] ?? 'Error desconocido del servidor');
      }

      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is List<dynamic>) {
        return {'observations': data};
      }
      return decoded;
    }

    if (decoded is List<dynamic>) {
      return {'observations': decoded};
    }

    return const {};
  }

  if (decoded is Map<String, dynamic>) {
    throw Exception(decoded['message'] ?? 'Error ${response.statusCode}');
  }
  throw Exception('Error ${response.statusCode}');
}

Map<String, dynamic> _normalizeObservationsResponse(Map<String, dynamic> data) {
  final observations = _firstList([
    data['observations'],
    data['observaciones'],
    data['items'],
    data['registros'],
  ]);

  final user = AuthService.currentUser ?? const {};
  final apprentice = _firstMap([
    data['apprentice'],
    data['aprendiz'],
    data['usuario'],
    data['user'],
    user,
  ]);

  return {
    'generated_at': data['generated_at'] ?? data['fecha_generacion'],
    'apprentice': {
      'id': _firstString([
        apprentice['id'],
        apprentice['id_aprendiz'],
        apprentice['id_usuario'],
      ]),
      'name': _firstString([
        apprentice['name'],
        apprentice['nombre_completo'],
        apprentice['nombre'],
        'Aprendiz',
      ]),
    },
    'observations': observations ?? const [],
  };
}

Map<String, dynamic> _firstMap(List<Object?> values) {
  for (final value in values) {
    if (value is Map<String, dynamic>) {
      return value;
    }
  }
  return const {};
}

List<dynamic>? _firstList(List<Object?> values) {
  for (final value in values) {
    if (value is List<dynamic>) {
      return value;
    }
  }
  return null;
}

String _firstString(List<Object?> values) {
  for (final value in values) {
    if (value == null) {
      continue;
    }
    if (value is Map<String, dynamic>) {
      final nested = _firstString([
        value['nombre_completo'],
        value['nombre'],
        value['name'],
        value['label'],
      ]);
      if (nested.isNotEmpty) {
        return nested;
      }
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

const _mockResponse = {
  'generated_at': '2024-05-29T10:30:00',
  'apprentice': {'id': '1234567890', 'name': 'Juan Perez'},
  'observations': [
    {
      'id': 'obs-001',
      'apprentice_id': '1234567890',
      'title': 'Asistencia por justificar',
      'type_label': 'Asistencia',
      'area': 'Coordinacion academica',
      'author_name': 'Franco Reina',
      'date': '2024-05-29',
      'due_date': '2024-05-31',
      'severity': 'action_required',
      'status_label': 'Requiere respuesta',
      'description':
          'Registra una inasistencia pendiente. Carga el soporte o confirma la novedad con tu instructor.',
      'action_type': 'upload_support',
      'action_label': 'Enviar soporte',
      'active': true,
    },
    {
      'id': 'obs-002',
      'apprentice_id': '1234567890',
      'title': 'Entrega de evidencia',
      'type_label': 'Academica',
      'area': 'Instructor Carlos Ramirez',
      'author_name': 'Carlos Ramirez',
      'date': '2024-05-24',
      'due_date': '2024-06-03',
      'severity': 'in_progress',
      'status_label': 'En seguimiento',
      'description':
          'La evidencia del proyecto formativo requiere un ajuste antes de la proxima revision.',
      'action_type': 'view_detail',
      'action_label': 'Ver detalle',
      'active': true,
    },
    {
      'id': 'obs-003',
      'apprentice_id': '1234567890',
      'title': 'Acompanamiento preventivo',
      'type_label': 'Bienestar',
      'area': 'Equipo de bienestar',
      'author_name': 'Equipo de bienestar',
      'date': '2024-05-20',
      'due_date': null,
      'severity': 'informative',
      'status_label': 'Informativa',
      'description':
          'Bienestar registra buena disposicion y recomienda mantener contacto si necesitas apoyo.',
      'action_type': 'contact_support',
      'action_label': 'Contactar',
      'active': true,
    },
  ],
};
