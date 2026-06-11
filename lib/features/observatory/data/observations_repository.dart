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
    return ObservatoryObservationResponse(
      metrics: const ObservatoryMetrics(
        total: 3,
        abiertas: 2,
        cerradas: 1,
        alta: 1,
        media: 1,
        baja: 1,
      ),
      items: [
        ObservatoryObservation(
          id: 'obs-1',
          fecha: DateTime(2026, 6, 3),
          tipo: 'Asistencia por justificar',
          severidad: 'GRAVE',
          estado: 'ABIERTA',
          descripcion:
              'El aprendiz registra inasistencia pendiente de soporte.',
          responsableNombre: 'Juan Perez',
          responsableRol: 'Instructor',
        ),
        ObservatoryObservation(
          id: 'obs-2',
          fecha: DateTime(2026, 5, 28),
          tipo: 'Seguimiento academico',
          severidad: 'MODERADA',
          estado: 'ABIERTA',
          descripcion: 'Se recomienda reforzar las evidencias pendientes.',
          responsableNombre: 'Laura Gomez',
          responsableRol: 'Bienestar',
        ),
        ObservatoryObservation(
          id: 'obs-3',
          fecha: DateTime(2026, 5, 20),
          tipo: 'Convivencia',
          severidad: 'LEVE',
          estado: 'CERRADA',
          descripcion: 'Caso cerrado despues del acompanamiento realizado.',
          responsableNombre: 'Carlos Ruiz',
          responsableRol: 'Coordinador',
        ),
      ],
      message: 'Observaciones cargadas',
    );
  }

  @override
  Future<ObservatoryAlertResponse> fetchAlerts(
    ObservatoryFilters filters,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return ObservatoryAlertResponse(
      metrics: const ObservatoryMetrics(
        total: 2,
        abiertas: 1,
        cerradas: 1,
        alta: 1,
        media: 1,
        baja: 0,
      ),
      items: [
        ObservatoryAlert(
          id: 'alert-1',
          tipo: 'Riesgo academico',
          severidad: 'GRAVE',
          estado: 'ABIERTA',
          origen: 'Sistema academico',
          reglaDisparo: 'Tres evidencias pendientes',
          descripcion: 'Se detecta acumulacion de evidencias sin entregar.',
          fechaAlerta: DateTime(2026, 6, 4),
          fechaCierre: null,
          justificacionCierre: '',
          fechaReapertura: null,
          justificacionReapertura: '',
          responsableNombre: 'Laura Gomez',
          responsableRol: 'Bienestar',
          responsableCierreNombre: '',
          responsableCierreRol: '',
          responsableReaperturaNombre: '',
          responsableReaperturaRol: '',
        ),
        ObservatoryAlert(
          id: 'alert-2',
          tipo: 'Asistencia',
          severidad: 'MODERADA',
          estado: 'CERRADA',
          origen: 'Control de asistencia',
          reglaDisparo: 'Dos fallas consecutivas',
          descripcion: 'Alerta cerrada tras validar soporte.',
          fechaAlerta: DateTime(2026, 5, 24),
          fechaCierre: DateTime(2026, 5, 30),
          justificacionCierre: 'Soporte validado por el instructor.',
          fechaReapertura: null,
          justificacionReapertura: '',
          responsableNombre: 'Juan Perez',
          responsableRol: 'Instructor',
          responsableCierreNombre: 'Carlos Ruiz',
          responsableCierreRol: 'Coordinador',
          responsableReaperturaNombre: '',
          responsableReaperturaRol: '',
        ),
      ],
      message: 'Alertas cargadas',
    );
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
    final data = await _sendGet(ApiConfig.apprenticeObservatoryAlerts, filters);
    return ObservatoryAlertResponse.fromJson(data);
  }
}

Future<Map<String, dynamic>> _sendGet(
  String url,
  ObservatoryFilters filters,
) async {
  final token = AuthService.currentToken;
  if (token == null || token.isEmpty) {
    throw Exception(
      'No hay sesion activa. Por favor, inicia sesion nuevamente.',
    );
  }

  final baseUri = Uri.parse(url);
  final uri = baseUri.replace(queryParameters: filters.toQueryParams());

  try {
    final response = await http
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

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
