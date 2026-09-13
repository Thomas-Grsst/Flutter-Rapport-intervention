import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rapport_intervention/models/company.dart';
import 'package:rapport_intervention/models/enums.dart';
import 'package:rapport_intervention/models/filtre_compact_template.dart';
import 'package:rapport_intervention/models/photo_item.dart';
import 'package:rapport_intervention/models/report.dart';
import 'package:rapport_intervention/screens/filtre_compact_wizard_screen.dart';
import 'package:rapport_intervention/services/pdf_service.dart';
import 'package:rapport_intervention/services/storage_service.dart';
import 'package:rapport_intervention/state/clients_provider.dart';
import 'package:rapport_intervention/state/reports_provider.dart';
import 'package:rapport_intervention/state/settings_provider.dart';

import 'fake_storage.dart';
import 'sample_company.dart';

final List<int> _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKm'
  'MIQAAAABJRU5ErkJggg==',
);

/// Un rapport de filtre compact entierement renseigne.
Report _filtreReport() {
  final report = Report(
    id: 'r-filtre',
    createdAt: DateTime(2026, 9, 13, 9),
    updatedAt: DateTime(2026, 9, 13, 11),
    kind: ReportKind.filtreCompact,
    reportNumber: 'ASE-130926-MR',
    reference: 'CONTRAT-2026-014',
    serialNumber: 'PT-5EH-88421',
    lastMaintenanceDate: DateTime(2025, 9, 18),
    interventionType: 'Entretien filtre compact',
    interventionDate: DateTime(2026, 9, 13),
    clientName: 'Mr RAMELLA Matthieu',
    clientAddressLine: '1180, Route du Pont de Reyre',
    clientCity: 'Dommartin',
    clientPhone: '07 69 11 91 76',
    equipmentBrand: 'Premier Tech',
    equipmentType: 'Ecoflo Pack 5 EH sortie haute',
    technicians: const [Technician(name: 'Thierry GROSSAT')],
  );

  for (final field in filtreSummaryFields) {
    report.setChecklistValue(
        filtreSummaryKey(field), field.answers.choices.first);
  }
  for (final section in filtreSections) {
    if (section.hasStateBefore) {
      report.setChecklistValue(section.stateKey, 'Dépôt léger.');
    }
    for (final field in section.fields) {
      report.setChecklistValue(
          section.keyOf(field), field.answers.choices.first);
      report.setChecklistValue(
          section.observationsKeyOf(field), 'Rien à signaler.');
    }
  }
  report.setChecklistValue(filtreWorkKey, 'Nettoyage complet du préfiltre.');
  report.setChecklistValue(filtreAdviceKey, 'Revenir dans douze mois.');
  report.setChecklistValue(filtreNextVisitKey, '09/2027');

  return report;
}

Future<ReportsProvider> _pumpWizard(
  WidgetTester tester, {
  required FakeStorage storage,
}) async {
  final settings = SettingsProvider(storage);
  final reports = ReportsProvider(storage);
  final clients = ClientsProvider(storage);
  await settings.load();
  await reports.load();
  await clients.load();

  final draft =
      reports.createDraft(settings.settings, kind: ReportKind.filtreCompact);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<PdfService>(create: (_) => PdfService(storage)),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<ReportsProvider>.value(value: reports),
        ChangeNotifierProvider<ClientsProvider>.value(value: clients),
      ],
      child: MaterialApp(
        home: FiltreCompactWizardScreen(report: draft, isNew: true),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return reports;
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.text('Suivant'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('gabarit du filtre compact', () {
    test('suit le modèle papier, section par section', () {
      expect(filtreSections.map((section) => section.title), [
        "Environnement de l'installation",
        'Nettoyage du regard en amont',
        'Nettoyage de la fosse toutes eaux',
        'Nettoyage du préfiltre',
        "Nettoyage de l'auget du média filtrant",
        'Nettoyage de la grille de répartition',
        'Nettoyage de la pompe de relevage',
        'Scarification du média filtrant',
        "Nettoyage de l'évent du média filtrant",
        'Vérification du regard de répartition des tranchées',
        'Vérification du regard de bouclage des tranchées',
        'Contrôles complémentaires',
      ]);
    });

    test('les identifiants de section sont uniques', () {
      // Ils servent de cle de rangement : deux sections qui les partageraient
      // melangeraient leurs releves et leurs photos.
      final ids = filtreSections.map((section) => section.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
    });

    test('les regards des tranchées ne se photographient qu\'une fois', () {
      // On ne les nettoie pas, on les constate : un avant / apres n'aurait
      // aucun sens.
      final regards = filtreSections
          .where((section) => section.id.startsWith('regard-'))
          .where((section) => section.photos == FiltrePhotos.unique);

      expect(regards, hasLength(2));
      for (final section in regards) {
        expect(section.hasStateBefore, isFalse);
        expect(section.fields.single.answers, FiltreAnswers.conformite);
      }
    });

    test('les contrôles complémentaires forment un tableau sans photo', () {
      final controles = filtreSections.last;

      expect(controles.photos, FiltrePhotos.aucune);
      expect(controles.fields, hasLength(5));
      for (final field in controles.fields) {
        expect(field.answers, FiltreAnswers.okNok);
        expect(field.hasObservations, isTrue);
      }
    });
  });

  group('rapport de filtre compact', () {
    test('relit ses repères et ses relevés après enregistrement', () {
      final saved = Report.fromJson(_filtreReport().toJson());

      expect(saved.kind, ReportKind.filtreCompact);
      expect(saved.serialNumber, 'PT-5EH-88421');
      expect(saved.lastMaintenanceDate, DateTime(2025, 9, 18));
      expect(saved.checklistValue('prefiltre/Nettoyage effectué'), 'Oui');
      expect(saved.checklistValue(filtreNextVisitKey), '09/2027');
    });

    test('ne réclame pas les rubriques des autres rapports', () {
      final report = Report(
        id: 'vide',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
        kind: ReportKind.filtreCompact,
      );

      expect(report.missingSections, [
        'Nom du client',
        'Adresse du client',
        'Intervenant',
        'Points relevés',
        'Photos',
      ]);
    });

    test('est prêt une fois rempli et photographié', () {
      final report = _filtreReport()
        ..photoGroupFor('prefiltre', title: 'Préfiltre').photos.add(
              PhotoItem(id: 'p1', filePath: 'media/p1.png'),
            );

      expect(report.missingSections, isEmpty);
    });
  });

  group('PDF du filtre compact', () {
    test('produit un PDF valide, photos et signatures comprises', () async {
      final storage = FakeStorage();
      for (final nom in ['p1', 'p2', 'sig-client', 'sig-tech']) {
        storage.files['media/$nom.png'] = Uint8List.fromList(_onePixelPng);
      }

      final report = _filtreReport()
        ..clientSignaturePath = 'media/sig-client.png'
        ..technicianSignaturePath = 'media/sig-tech.png'
        ..clientEvaluation = 'Intervention rapide et propre.';
      report.photoGroupFor('fosse', title: 'Fosse').photos.addAll([
        PhotoItem(id: 'p1', filePath: 'media/p1.png'),
        PhotoItem(
            id: 'p2', filePath: 'media/p2.png', stage: PhotoStage.apres),
      ]);
      report
          .photoGroupFor('regard-repartition', title: 'Regard')
          .photos
          .add(PhotoItem(id: 'p3', filePath: 'media/p1.png'));

      final bytes = await PdfService(storage).buildReportPdf(
        report: report,
        company: sampleCompany,
      );

      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(latin1.decode(bytes).trimRight(), endsWith('%%EOF'));
    });

    test('génère aussi le PDF d\'un entretien à peine commencé', () async {
      final draft = Report(
        id: 'vide',
        createdAt: DateTime(2026, 9, 13),
        updatedAt: DateTime(2026, 9, 13),
        kind: ReportKind.filtreCompact,
      );

      final bytes = await PdfService(FakeStorage()).buildReportPdf(
        report: draft,
        company: sampleCompany,
      );

      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('assistant du filtre compact', () {
    testWidgets('déroule le client, l\'installation, les douze sections, '
        'la synthèse et la validation', (tester) async {
      await _pumpWizard(tester, storage: FakeStorage());

      final titles = <String>[
        'Le client',
        "L'installation",
        for (var i = 0; i < filtreSections.length; i++)
          '${i + 1}. ${filtreSections[i].title}',
        'Synthèse',
        'Validation',
      ];

      for (final title in titles) {
        expect(find.text(title), findsWidgets, reason: 'étape « $title »');
        if (title != titles.last) await _next(tester);
      }

      expect(find.text('Terminer'), findsOneWidget);
      expect(find.text('Suivant'), findsNothing);
    });

    testWidgets('les trois textes de la synthèse vont chacun à leur place',
        (tester) async {
      final reports = await _pumpWizard(tester, storage: FakeStorage());

      // Le client, l'installation, puis les douze sections : la synthèse
      // vient juste après.
      for (var i = 0; i < filtreSections.length + 2; i++) {
        await _next(tester);
      }

      final saisies = <String, String>{
        'Ex. : pompage de la fosse, nettoyage du préfiltre et scarification '
            'du média filtrant.': 'Nettoyage du préfiltre.',
        'Ce qui ne va pas, et depuis quand si vous le savez.':
            'Aucune anomalie.',
        'Ce que le client doit faire, et dans quel délai.':
            'Remplacer le couvercle du regard amont.',
        'Ex. : dans 12 mois, ou 09/2027': '09/2027',
      };

      for (final saisie in saisies.entries) {
        final champ = find.widgetWithText(TextField, saisie.key);
        await tester.ensureVisible(champ);
        await tester.pumpAndSettle();
        await tester.enterText(champ, saisie.value);
        await tester.pumpAndSettle();
      }

      await _next(tester);
      final saved = reports.all.single;

      expect(saved.checklistValue(filtreWorkKey), 'Nettoyage du préfiltre.');
      expect(saved.checklistValue(filtreAnomaliesKey), 'Aucune anomalie.');
      expect(saved.checklistValue(filtreAdviceKey),
          'Remplacer le couvercle du regard amont.');
      expect(saved.checklistValue(filtreNextVisitKey), '09/2027');
    });

    testWidgets('un relevé coché est enregistré sous la clé de sa section',
        (tester) async {
      final reports = await _pumpWizard(tester, storage: FakeStorage());

      await _next(tester); // L'installation
      await _next(tester); // 1. Environnement

      await tester.tap(find.text('Oui').first);
      await tester.pumpAndSettle();
      await _next(tester);

      final saved = reports.all.single;
      expect(saved.kind, ReportKind.filtreCompact);
      expect(
        saved.checklistValue('environnement/Zone accessible et sécurisée'),
        'Oui',
      );
      expect(saved.status, ReportStatus.enCours);
      // Le modèle sous contrat est pré-rempli.
      expect(saved.equipmentType, 'Ecoflo Pack 5 EH sortie haute');
    });
  });
}
