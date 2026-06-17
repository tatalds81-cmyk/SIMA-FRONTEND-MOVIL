import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sima_movil_froned/features/observatory/models/observation.dart';
import 'package:sima_movil_froned/services/api_config.dart';
import 'package:sima_movil_froned/services/auth_service.dart';

abstract class ObservatoryRepository {
  Future<ObservatoryObservationResponse> fetchObservations(
    ObservatoryFilters filters,
  );

  Future<ObservatoryAlertResponse> fetchAlerts(ObservatoryFilters filters);
}

class MockObservationsRepository implements ObservatoryRepository {
  const MockObservationsRepository();

  @override
  Future<ObservatoryObservationResponse> fetchObservations(
    ObservatoryFilters filters,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return ObservatoryObservationResponse.fromJson(_mockObservationsResponse);
  }

  @override
  Future<ObservatoryAlertResponse> fetchAlerts(
    ObservatoryFilters filters,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return ObservatoryAlertResponse.fromJson(_mockAlertsResponse);
  }
}

class BackendObservatoryRepository implements ObservatoryRepository {
  const BackendObservatoryRepository();

  @override
  Future<ObservatoryObservationResponse> fetchObservations(
    ObservatoryFilters filters,
  ) async {
    final data = await _sendGet(
      ApiConfig.apprenticeObservatoryObservations,
      filters,
    );
    return ObservatoryObservationResponse.fromJson(data);
  }

  @override
  Future<ObservatoryAlertResponse> fetchAlerts(
    ObservatoryFilters filters,
  ) async {
    final data = await _sendGet(
      ApiConfig.apprenticeObservatoryAlerts,
      filters,
    );
    return ObservatoryAlertResponse.fromJson(data);
  }
}

Future<Map<String, dynamic>> _sendGet(
  String url,
  ObservatoryFilters filters,
) async {
  final token = AuthService.currentToken;
  if (token == null || token.isEmpty) {
    throw Exception('No hay sesion activa. Por favor, inicia sesion nuevamente.');
  }

  final baseUri = Uri.parse(url);
  final uri = baseUri.replace(queryParameters: filters.toQueryParams());

  try {
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    return _decodeResponse(response);
  } on Exception catch (error) {
    final rawMessage = error.toString();
    final cleanMessage = rawMessage.startsWith('Exception: ')
        ? rawMessage.replaceFirst('Exception: ', '')
        : 'Error de red al conectar con el servidor.';
    throw Exception(cleanMessage);
  }
}

Map<String, dynamic> _decodeResponse(http.Response response) {
  final Object? decoded;
  try {
    decoded = jsonDecode(response.body);
  } catch (_) {
    throw Exception('El servidor devolvio una respuesta inesperada.');
  }

  if (decoded is! Map<String, dynamic>) {
    throw Exception('El servidor devolvio una respuesta inesperada.');
  }

  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (decoded['ok'] == false) {
      throw Exception(decoded['message'] ?? 'Error desconocido del servidor');
    }

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return decoded;
  }

  throw Exception(decoded['message'] ?? 'Error ${response.statusCode}');
}

const _mockObservationsResponse = {
  'metricas': {
    'total': 3,
    'por_estado': {'ABIERTA': 2, 'CERRADA': 1},
    'por_severidad': {'GRAVE': 1, 'MODERADA': 1, 'LEVE': 1},
  },
  'observaciones': [
    {
      'id_observacion': 'obs-1',
      'fecha': '2026-06-03',
      'tipo': 'Asistencia por justificar',
      'severidad': 'GRAVE',
      'estado': 'ABIERTA',
      'descripcion': 'El aprendiz registra inasistencia pendiente de soporte.',
      'responsable': {
        'nombre_completo': 'Juan Perez',
        'rol': 'Instructor',
      },
    },
    {
      'id_observacion': 'obs-2',
      'fecha': '2026-05-28',
      'tipo': 'Seguimiento academico',
      'severidad': 'MODERADA',
      'estado': 'ABIERTA',
      'descripcion': 'Se recomienda reforzar las evidencias pendientes.',
      'responsable': {
        'nombre_completo': 'Laura Gomez',
        'rol': 'Bienestar',
      },
    },
    {
      'id_observacion': 'obs-3',
      'fecha': '2026-05-20',
      'tipo': 'Convivencia',
      'severidad': 'LEVE',
      'estado': 'CERRADA',
      'descripcion': 'Caso cerrado despues del acompanamiento realizado.',
      'responsable': {
        'nombre_completo': 'Carlos Ruiz',
        'rol': 'Coordinador',
      },
    },
  ],
  'mensaje': 'Observaciones cargadas',
};

const _mockAlertsResponse = {
  'metricas': {
    'total': 2,
    'por_estado': {'ABIERTA': 1, 'CERRADA': 1},
    'por_severidad': {'GRAVE': 1, 'MODERADA': 1, 'LEVE': 0},
  },
  'alertas': [
    {
      'id_alerta': 'alert-1',
      'tipo': 'Riesgo academico',
      'severidad': 'GRAVE',
      'estado': 'ABIERTA',
      'origen': 'Sistema academico',
      'regla_disparo': 'Tres evidencias pendientes',
      'descripcion': 'Se detecta acumulacion de evidencias sin entregar.',
      'fecha_alerta': '2026-06-04',
      'responsable': {
        'nombre_completo': 'Laura Gomez',
        'rol': 'Bienestar',
      },
    },
    {
      'id_alerta': 'alert-2',
      'tipo': 'Asistencia',
      'severidad': 'MODERADA',
      'estado': 'CERRADA',
      'origen': 'Control de asistencia',
      'regla_disparo': 'Dos fallas consecutivas',
      'descripcion': 'Alerta cerrada tras validar soporte.',
      'fecha_alerta': '2026-05-24',
      'fecha_cierre': '2026-05-30',
      'justificacion_cierre': 'Soporte validado por el instructor.',
      'responsable': {
        'nombre_completo': 'Juan Perez',
        'rol': 'Instructor',
      },
      'responsable_cierre': {
        'nombre_completo': 'Carlos Ruiz',
        'rol': 'Coordinador',
      },
    },
  ],
  'mensaje': 'Alertas cargadas',
};
