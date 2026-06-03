import 'package:sima_movil_froned/features/observatory/models/observation.dart';

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
