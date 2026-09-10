import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rapport_intervention/models/app_settings.dart';
import 'package:rapport_intervention/models/enums.dart';
import 'package:rapport_intervention/screens/report_wizard_screen.dart';
import 'package:rapport_intervention/services/pdf_service.dart';
import 'package:rapport_intervention/services/storage_service.dart';
import 'package:rapport_intervention/state/reports_provider.dart';
import 'package:rapport_intervention/state/settings_provider.dart';

import 'fake_storage.dart';

/// Monte l'assistant de saisie sur un brouillon neuf, comme le fait l'accueil.
Future<ReportsProvider> _pumpWizard(WidgetTester tester,
    {required FakeStorage storage}) async {
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
  return reports;
}

/// Amene l'assistant a l'etape suivante.
Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.text('Suivant'));
  await tester.pumpAndSettle();
}

/// Fait defiler jusqu'a l'element avant de le toucher.
///
/// Sans cela, un `tap` sur un widget sorti de la zone visible touche
/// silencieusement ce qui se trouve a sa place a l'ecran, et le test passe
/// sans avoir rien coche.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('les sept étapes se suivent dans l\'ordre', (tester) async {
    await _pumpWizard(tester, storage: FakeStorage());

    for (final title in [
      'Le chantier',
      'Observations',
      'Matériel',
      'Constats et actions',
      'Photos',
      'Conclusion',
      'Validation',
    ]) {
      expect(find.text(title), findsOneWidget, reason: 'étape « $title »');
      if (title != 'Validation') await _next(tester);
    }

    // La derniere etape propose de terminer, plus de continuer.
    expect(find.text('Terminer'), findsOneWidget);
    expect(find.text('Suivant'), findsNothing);
  });

  testWidgets('la saisie est enregistrée en changeant d\'étape',
      (tester) async {
    final storage = FakeStorage();
    final reports = await _pumpWizard(tester, storage: storage);

    await tester.enterText(
      find.widgetWithText(TextField, 'Ex. : M. Manuel BLANC'),
      'M. Manuel BLANC',
    );
    await tester.pumpAndSettle();
    await _next(tester);

    expect(reports.all, hasLength(1));
    expect(reports.all.single.clientName, 'M. Manuel BLANC');
    // Le numero de rapport est attribue des que le client est connu.
    expect(reports.all.single.reportNumber, isNotEmpty);
    expect(storage.json['reports.json'], isNotNull);
  });

  testWidgets('cocher un constat fait passer le rapport en cours',
      (tester) async {
    final reports = await _pumpWizard(tester, storage: FakeStorage());

    await _next(tester); // Observations
    await _next(tester); // Matériel
    await _next(tester); // Constats et actions

    await _tap(tester, find.text('Canalisation bouchée'));
    await _next(tester);

    expect(reports.all.single.findingTags, ['Canalisation bouchée']);
    expect(reports.all.single.status, ReportStatus.enCours);
  });

  testWidgets('la conclusion proposée reprend le type, les constats et les '
      'actions', (tester) async {
    final reports = await _pumpWizard(tester, storage: FakeStorage());

    await _tap(tester, find.text('Entretien poste de relevage'));
    await _next(tester); // Observations
    await _next(tester); // Matériel
    await _next(tester); // Constats et actions

    await _tap(tester, find.text('Canalisation bouchée'));
    await _tap(tester, find.text('Pompage de la fosse'));

    await _next(tester); // Photos
    await _next(tester); // Conclusion

    await _tap(tester, find.text('Proposer une conclusion'));
    await _next(tester); // Validation, ce qui enregistre le brouillon

    final conclusions = reports.all.single.conclusions;
    expect(conclusions, contains('entretien poste de relevage'));
    expect(conclusions, contains('canalisation bouchée'));
    expect(conclusions, contains('pompage de la fosse'));
  });

  testWidgets('on peut cocher et décocher les intervenants', (tester) async {
    final reports = await _pumpWizard(tester, storage: FakeStorage());

    // L'intervenant enregistré dans les réglages est coché d'avance.
    await _tap(tester, find.text('Thierry GROSSAT'));
    await _next(tester);
    expect(reports.all.single.technicians, isEmpty);

    await tester.tap(find.text('Précédent'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Thierry GROSSAT'));
    await _next(tester);

    expect(reports.all.single.techniciansLine, 'Thierry GROSSAT');
  });

  testWidgets('une intervention peut s\'étaler sur plusieurs jours',
      (tester) async {
    final reports = await _pumpWizard(tester, storage: FakeStorage());

    await _tap(tester, find.text("L'intervention a duré plusieurs jours"));

    // Le calendrier s'ouvre sur le premier jour : on valide deux jours plus
    // tard pour obtenir une vraie plage.
    final start = reports.createDraft(AppSettings.defaults).interventionDate;
    final end = start.add(const Duration(days: 2));
    await _tap(tester, find.text('${end.day}').last);
    await _tap(tester, find.text('OK'));
    await _next(tester);

    final saved = reports.all.single;
    expect(saved.isMultiDay, isTrue);
    expect(saved.interventionEndDate!.day, end.day);
  });

  testWidgets('la dernière étape liste ce qui reste à compléter',
      (tester) async {
    await _pumpWizard(tester, storage: FakeStorage());

    for (var i = 0; i < 6; i++) {
      await _next(tester);
    }

    await tester.ensureVisible(
        find.textContaining('information(s) à compléter'));
    await tester.pumpAndSettle();
    expect(find.textContaining('information(s) à compléter'), findsOneWidget);
    expect(find.textContaining('Nom du client'), findsOneWidget);
  });
}
