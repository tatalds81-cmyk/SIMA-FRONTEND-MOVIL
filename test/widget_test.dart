import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sima_movil_froned/features/access.dart';
import 'package:sima_movil_froned/features/profile/profile_page.dart';
import 'package:sima_movil_froned/widgets/sima_bottom_nav_bar.dart';

void main() {
  Finder bottomNavItem(String label) {
    return find.descendant(
      of: find.byType(SimaBottomNavBar),
      matching: find.text(label),
    );
  }

  void useDesktopViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('SIMA shows observations and profile from bottom navigation', (
    WidgetTester tester,
  ) async {
    useDesktopViewport(tester);

    await tester.pumpWidget(const MaterialApp(home: AccessPage()));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsWidgets);
    expect(bottomNavItem('Observaciones'), findsOneWidget);

    await tester.tap(bottomNavItem('Observaciones'));
    await tester.pumpAndSettle();

    expect(find.text('Mis observaciones'), findsOneWidget);
    expect(find.text('Seguimiento registrado para Juan Perez'), findsOneWidget);
    expect(find.text('Filtros de consulta'), findsOneWidget);
    expect(find.text('Total: 3'), findsOneWidget);
    expect(find.text('Abiertas: 3'), findsOneWidget);
    expect(find.text('Requiere respuesta'), findsOneWidget);
    expect(find.text('Observaciones registradas'), findsOneWidget);
    expect(find.text('Mostrando 3 de 3 observaciones'), findsOneWidget);
    expect(find.text('Asistencia por justificar'), findsOneWidget);
    expect(find.text('Enviar soporte'), findsWidgets);

    await tester.tap(bottomNavItem('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.byTooltip('Cerrar sesion'), findsOneWidget);
    expect(find.text('Accesos del perfil'), findsOneWidget);
    expect(find.text('Datos personales'), findsOneWidget);
    expect(find.byTooltip('Editar datos personales'), findsOneWidget);
    expect(find.text('Cerrar sesion'), findsNothing);
    expect(find.text('Academico'), findsOneWidget);
    expect(find.text('Contacto de emergencia'), findsOneWidget);
    expect(find.byTooltip('Editar contacto de emergencia'), findsOneWidget);
    expect(find.text('Seguridad'), findsOneWidget);
    expect(find.text('juan.perez@misena.edu.co'), findsNothing);
    expect(find.text('Perfil del aprendiz', skipOffstage: false), findsNothing);
    expect(find.text('Notificaciones', skipOffstage: false), findsNothing);
    expect(find.text('Documentos', skipOffstage: false), findsNothing);
    expect(find.text('Carnet digital', skipOffstage: false), findsNothing);
    expect(find.text('Cuenta'), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
  });

  testWidgets('Perfil keeps details inside personal access', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfilePage())),
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
      const MaterialApp(home: Scaffold(body: ProfilePage())),
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
      const MaterialApp(home: Scaffold(body: ProfilePage())),
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
