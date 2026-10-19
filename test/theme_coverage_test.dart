import 'package:appcaixaauto/src/app.dart';
import 'package:appcaixaauto/src/state/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show FixtureRepository;

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('fluxos principais renderizam em ${mode.name}', (tester) async {
      final theme = ThemeController();
      await theme.setMode(mode);
      theme.initialized = true;
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        App247Client(repository: FixtureRepository(), themeController: theme),
      );

      // Login.
      expect(find.textContaining('Seu condomínio'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        '123.456.789-01',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'segredo8');
      await tester.ensureVisible(find.text('ACESSAR'));
      await tester.tap(find.text('ACESSAR'));
      await tester.pumpAndSettle();

      // Home.
      expect(find.textContaining('Jefferson'), findsOneWidget);

      // Meu QR.
      await tester.tap(
        find.byKey(const ValueKey('open-customer-identification')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Identificação segura no Terminal'), findsOneWidget);

      // Catálogo e detalhe do produto.
      await tester.tap(find.text('Catálogo').last);
      await tester.pumpAndSettle();
      expect(find.text('Consulte antes de ir ao Terminal'), findsOneWidget);
      await tester.tap(find.text('Café torrado e moído tradicional 500 g'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhe do produto'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar').last);
      await tester.pumpAndSettle();

      // Compras e detalhe.
      await tester.tap(find.text('Compras').last);
      await tester.pumpAndSettle();
      expect(find.text('Minhas compras'), findsOneWidget);
      await tester.tap(find.text('Aprovada').first);
      await tester.pumpAndSettle();
      expect(find.text('Detalhe da compra'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar').last);
      await tester.pumpAndSettle();

      // Benefícios.
      await tester.tap(find.text('Início').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-open-benefits')));
      await tester.pumpAndSettle();
      expect(find.text('MEUS PONTOS'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar').last);
      await tester.pumpAndSettle();

      // Perfil.
      await tester.tap(find.byKey(const ValueKey('home-open-profile')));
      await tester.pumpAndSettle();
      expect(find.text('Jefferson Silva'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  }
}
