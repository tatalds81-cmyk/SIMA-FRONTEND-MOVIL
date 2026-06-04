import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sima_movil_froned/features/observatory/data/observations_repository.dart';
import 'package:sima_movil_froned/features/observatory/models/observation.dart';
import 'package:sima_movil_froned/features/observatory/observatory_page.dart';
import 'package:sima_movil_froned/features/profile/data/profile_repository.dart';
import 'package:sima_movil_froned/features/profile/profile_page.dart';

void main() {
  void useDesktopViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('SIMA shows observations dashboard with backend shape', (
    WidgetTester tester,
  ) async {
    useDesktopViewport(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ObservatoryPage(repository: MockObservationsRepository()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Observatorio'), findsOneWidget);
    expect(find.text('Seguimiento registrado para Juan Perez'), findsOneWidget);
    expect(find.text('Filtros'), findsOneWidget);
    expect(find.text('Total de observaciones: 3'), findsOneWidget);
    expect(find.text('Abiertas: 3'), findsOneWidget);
    expect(find.text('Observaciones registradas'), findsOneWidget);
    expect(find.text('Mostrando 3 observaciones'), findsOneWidget);
    expect(find.text('Asistencia por justificar'), findsOneWidget);
  });

  testWidgets('Perfil keeps details inside personal access', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProfilePage(repository: MockProfileRepository())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.byTooltip('Cerrar sesion'), findsOneWidget);
    expect(find.text('Accesos del perfil'), findsOneWidget);
    expect(find.text('Datos personales'), findsOneWidget);
    expect(find.byTooltip('Editar datos personales'), findsOneWidget);
    expect(find.text('Cerrar sesion'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Datos personales'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .ancestor(
            of: find.text('Datos personales'),
            matching: find.byType(InkWell),
          )
          .last,
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Nombres'), findsOneWidget);
    final emailField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Correo'),
    );
    expect(emailField.controller?.text, 'juan.perez@misena.edu.co');
    expect(find.text('Cerrar sesion'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombres'),
      'Carlos',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Apellidos'),
      'Lopez',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Carlos Lopez'), findsOneWidget);
  });

  testWidgets('Perfil opens personal form from access edit action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProfilePage(repository: MockProfileRepository())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byTooltip('Editar datos personales'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar datos personales'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Nombres'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Guardar cambios'),
      findsOneWidget,
    );
  });

  testWidgets('Perfil opens logout confirmation from header action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProfilePage(repository: MockProfileRepository())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cerrar sesion'));
    await tester.pumpAndSettle();

    expect(
      find.text('Quieres salir de tu cuenta en este dispositivo?'),
      findsOneWidget,
    );
    expect(find.text('Cerrar sesion'), findsNWidgets(2));
  });
}

class MockObservationsRepository implements ObservatoryRepository {
  const MockObservationsRepository();

  @override
  Future<ObservatoryObservationResponse> fetchObservations(
    ObservatoryFilters filters,
  ) async {
    return ObservatoryObservationResponse(
      metrics: const ObservatoryMetrics(
        total: 3,
        abiertas: 3,
        cerradas: 0,
        alta: 1,
        media: 1,
        baja: 1,
      ),
      items: [
        ObservatoryObservation(
          id: 'obs-001',
          fecha: DateTime(2024, 5, 29),
          tipo: 'General',
          severidad: 'LEVE',
          estado: 'ABIERTA',
          descripcion: 'Seguimiento registrado para Juan Perez',
          responsableNombre: 'Juan Perez',
          responsableRol: 'Instructor',
        ),
        ObservatoryObservation(
          id: 'obs-002',
          fecha: DateTime(2024, 5, 24),
          tipo: 'Academica',
          severidad: 'MODERADA',
          estado: 'ABIERTA',
          descripcion: 'La evidencia del proyecto formativo requiere un ajuste',
          responsableNombre: 'Carlos Ramirez',
          responsableRol: 'Instructor',
        ),
        ObservatoryObservation(
          id: 'obs-003',
          fecha: DateTime(2024, 5, 20),
          tipo: 'Asistencia por justificar',
          severidad: 'GRAVE',
          estado: 'ABIERTA',
          descripcion: 'Registra una inasistencia pendiente.',
          responsableNombre: 'Franco Reina',
          responsableRol: 'Coordinador',
        ),
      ],
      message: 'Ok',
    );
  }

  @override
  Future<ObservatoryAlertResponse> fetchAlerts(
    ObservatoryFilters filters,
  ) async {
    return ObservatoryAlertResponse(
      metrics: const ObservatoryMetrics(
        total: 3,
        abiertas: 3,
        cerradas: 0,
        alta: 1,
        media: 1,
        baja: 1,
      ),
      items: [
        ObservatoryAlert(
          id: 'alt-001',
          tipo: 'Asistencia por justificar',
          severidad: 'GRAVE',
          estado: 'ABIERTA',
          origen: 'Sistema',
          reglaDisparo: 'Inasistencia',
          descripcion: 'Falta sin justificar',
          fechaAlerta: DateTime(2024, 5, 29),
          fechaCierre: null,
          justificacionCierre: '',
          fechaReapertura: null,
          justificacionReapertura: '',
          responsableNombre: 'Franco Reina',
          responsableRol: 'Coordinador',
          responsableCierreNombre: '',
          responsableCierreRol: '',
          responsableReaperturaNombre: '',
          responsableReaperturaRol: '',
        ),
      ],
      message: 'Ok',
    );
  }
}
