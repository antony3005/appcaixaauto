import 'package:appcaixaauto/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show FixtureRepository;

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('fluxos principais sem overflow com texto em ${scale}x', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(App247Client(repository: FixtureRepository()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        '123.456.789-01',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'segredo8');
      await tester.ensureVisible(find.text('ACESSAR'));
      await tester.tap(find.text('ACESSAR'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (final tab in ['Catálogo', 'Meu QR', 'Compras', 'Início']) {
        await tester.tap(find.text(tab).last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: tab);
      }

      await tester.tap(find.byKey(const ValueKey('home-open-profile')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Perfil');
      await tester.tap(find.text('Início').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('home-open-benefits')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Benefícios');
    });
  }
}
