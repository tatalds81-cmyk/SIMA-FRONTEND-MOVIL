import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sima_movil_froned/main.dart';

void main() {
  testWidgets('SIMA app opens apprentice profile details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SimaApp());

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Pantalla principal de SIMA'), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Juan Pérez García'), findsOneWidget);
    expect(find.text('Perfil del aprendiz'), findsOneWidget);
    expect(find.text('Cuenta'), findsNothing);

    await tester.tap(find.byTooltip('Configuración'));
    await tester.pumpAndSettle();
    expect(find.text('Cerrar sesión'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Observaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Seguimiento académico'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.text('Datos personales'), findsOneWidget);
    await tester.tap(find.text('Datos personales'));
    await tester.pumpAndSettle();

    expect(find.text('Información personal'), findsOneWidget);
    expect(find.text('Nombres'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('juan.perez@misena.edu.co'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('juan.perez@misena.edu.co'), findsOneWidget);
  });
}
