import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sima_movil_froned/features/observatory/data/observations_repository.dart';
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
    expect(
      find.text('Consulta tus observaciones y alertas de seguimiento.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Mostrar filtros'), findsOneWidget);
    expect(find.text('Buscar'), findsNothing);
    expect(find.text('Total de observaciones: 3'), findsOneWidget);
    expect(find.text('Abiertas: 2'), findsOneWidget);
    expect(find.text('Observaciones registradas'), findsOneWidget);
    expect(find.text('Mostrando 3 observaciones'), findsOneWidget);
    expect(find.text('Asistencia por justificar'), findsOneWidget);

    await tester.tap(find.byTooltip('Mostrar filtros'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Ocultar filtros'), findsOneWidget);
    expect(find.text('Fecha'), findsOneWidget);
    expect(find.text('Severidad'), findsOneWidget);
    expect(find.text('Estado'), findsOneWidget);
    expect(find.text('Tipo'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Limpiar'), findsOneWidget);
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
      find.widgetWithText(TextFormField, 'Correo'),
      'juan.actualizado@misena.edu.co',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Datos personales actualizados.'), findsOneWidget);
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
