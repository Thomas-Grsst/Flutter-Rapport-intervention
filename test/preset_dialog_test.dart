import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rapport_intervention/screens/report_wizard_screen.dart';
import 'package:rapport_intervention/services/pdf_service.dart';
import 'package:rapport_intervention/services/storage_service.dart';
import 'package:rapport_intervention/state/reports_provider.dart';
import 'package:rapport_intervention/state/settings_provider.dart';

import 'fake_storage.dart';

void main() {
  testWidgets('ajouter un matériel « Autre… » ne casse rien', (tester) async {
    final storage = FakeStorage();
    final settings = SettingsProvider(storage);
    final reports = ReportsProvider(storage);
    await settings.load();
    await reports.load();
    final draft = reports.createDraft(settings.settings);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          Provider<PdfService>(create: (_) => PdfService(storage)),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<ReportsProvider>.value(value: reports),
        ],
        child: MaterialApp(
          home: ReportWizardScreen(report: draft, isNew: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Jusqu'a l'etape 3, Materiel.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Autre…'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Nettoyeur vapeur');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    // La valeur saisie devient une case cochée, et rien n'a explosé pendant la
    // fermeture de la boîte de dialogue.
    expect(tester.takeException(), isNull);
    expect(find.text('Nettoyeur vapeur'), findsWidgets);

    // Elle est bien portée au rapport en passant à l'étape suivante, et
    // mémorisée pour les rapports suivants.
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();

    expect(reports.all.single.materials, contains('Nettoyeur vapeur'));
    expect(settings.presetsOf(PresetList.materials),
        contains('Nettoyeur vapeur'));
    expect(tester.takeException(), isNull);
  });
}
