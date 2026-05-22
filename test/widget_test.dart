import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sima_movil_froned/main.dart';

void main() {
  testWidgets('SIMA opens apprentice profile details after login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SimaApp());

    expect(find.text('Bienvenido a SIMA'), findsOneWidget);
    expect(
      find.text('Sistema Integral\nde Monitoreo del\nAprendiz'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesion'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).at(0), '1234567890');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesion'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Resumen de tu jornada academica'), findsOneWidget);

    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();

    expect(find.text('Perfil del aprendiz'), findsOneWidget);
    expect(find.text('Datos personales'), findsOneWidget);
    expect(find.text('Cuenta'), findsNothing);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Cuenta'), findsOneWidget);
    expect(find.text('Ayuda y soporte'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Observaciones'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Observaciones activas para revisar con el equipo de seguimiento.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Datos personales'));
    await tester.pumpAndSettle();

    expect(find.text('Nombres'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('juan.perez@misena.edu.co'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('juan.perez@misena.edu.co'), findsOneWidget);
  });
}
