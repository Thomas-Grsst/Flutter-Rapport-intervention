import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart' show PdfColors;
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:rapport_intervention/models/app_settings.dart';
import 'package:rapport_intervention/models/company.dart';
import 'package:rapport_intervention/models/enums.dart';
import 'package:rapport_intervention/models/photo_item.dart';
import 'package:rapport_intervention/models/relevage_template.dart';
import 'package:rapport_intervention/models/report.dart';
import 'package:rapport_intervention/screens/relevage_wizard_screen.dart';
import 'package:rapport_intervention/services/pdf_service.dart';
import 'package:rapport_intervention/services/relevage_pdf.dart';
import 'package:rapport_intervention/services/storage_service.dart';
import 'package:rapport_intervention/state/reports_provider.dart';
import 'package:rapport_intervention/state/settings_provider.dart';

import 'fake_storage.dart';

/// Un PNG rouge de 1 pixel : de quoi donner une vraie image a la mise en page
/// sans embarquer de fichier dans les tests.
final List<int> _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKm'
  'MIQAAAABJRU5ErkJggg==',
);

/// Un rapport de poste de relevage entierement renseigne.
Report _relevageReport() {
  final report = Report(
    id: 'r-relevage',
    createdAt: DateTime(2026, 9, 11, 9),
    updatedAt: DateTime(2026, 9, 11, 11),
    kind: ReportKind.posteRelevage,
    reportNumber: 'ASE-110926-AL',
    interventionType: 'Entretien poste de relevage',
    interventionDate: DateTime(2026, 9, 11),
    clientName: 'Association La Roseraie',
    clientAddressLine: '19, Avenue Salvador Allende',
    clientPostalCode: '69150',
    clientCity: 'DECINES CHARPIEU',
    clientPhone: '07 62 70 39 83',
    clientEmail: 'contact@laroseraie.fr',
    contractDate: DateTime(2026, 3, 3),
    equipmentBrand: 'Technirel',
    equipmentType: 'Maxirel 200',
    technicians: const [
      Technician(name: 'Thierry GROSSAT', phone: '06 50 36 50 00'),
    ],
  );

  for (final section in relevageSections) {
    for (final field in section.fields) {
      report.setChecklistValue(
          section.keyOf(field), field.answers.choices.first);
    }
  }
  report.setChecklistValue('observations',
      "Prévoir le remplacement de la pompe n°1 avant l'hiver.");

  return report;
}

/// Monte l'assistant du poste de relevage sur un brouillon neuf.
Future<ReportsProvider> _pumpRelevageWizard(
  WidgetTester tester, {
  required FakeStorage storage,
}) async {
  final settings = SettingsProvider(storage);
  final reports = ReportsProvider(storage);
  await settings.load();
  await reports.load();

  final draft =
      reports.createDraft(settings.settings, kind: ReportKind.posteRelevage);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<PdfService>(create: (_) => PdfService(storage)),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<ReportsProvider>.value(value: reports),
      ],
      child: MaterialApp(home: RelevageWizardScreen(report: draft, isNew: true)),
    ),
  );
  await tester.pumpAndSettle();
  return reports;
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.text('Suivant'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('gabarit du poste de relevage', () {
    test('suit le modèle papier, section par section', () {
      expect(
        relevageSections.map((section) => section.title),
        [
          'Environnement',
          'Cuve',
          'Clapet anti-retour',
          'Flotteurs ou poires de commande',
          'Pompe(s)',
          'Coffret ou armoire électrique',
          'Exutoire',
          'Observations',
        ],
      );
    });

    test('les identifiants de section sont uniques', () {
      // Ils servent de cle de rangement : deux sections qui les partageraient
      // melangeraient leurs etats et leurs photos.
      final ids = relevageSections.map((section) => section.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
    });

    test('ne propose que les trois états, sauf pour l\'alarme', () {
      for (final section in relevageSections) {
        for (final field in section.fields) {
          final expected = field.label == 'Alarme avant entretien'
              ? ['Oui', 'Non']
              : ['Excellent', 'Correct', 'À remplacer'];

          expect(field.answers.choices, expected,
              reason: '${section.title} — ${field.label}');
        }
      }
    });

    test('les observations sont un texte libre, sans photo', () {
      final observations = relevageSections.last;

      expect(observations.hasFreeText, isTrue);
      expect(observations.hasPhotos, isFalse);
      expect(observations.fields, isEmpty);
    });
  });

  group('rapport de poste de relevage', () {
    test('relit les états et le type de rapport après enregistrement', () {
      final saved = Report.fromJson(_relevageReport().toJson());

      expect(saved.kind, ReportKind.posteRelevage);
      expect(saved.equipmentBrand, 'Technirel');
      expect(saved.contractDate, DateTime(2026, 3, 3));
      expect(saved.checklistValue('cuve/Etat général avant nettoyage'),
          'Excellent');
      expect(saved.checklistValue('coffret/Alarme avant entretien'), 'Oui');
      expect(saved.checklistValue('observations'),
          startsWith('Prévoir le remplacement'));
    });

    test('un rapport d\'intervention reste un rapport d\'intervention', () {
      // Les rapports enregistres avant l'arrivee du second modele n'ont pas de
      // champ « kind » : ils doivent rester des rapports d'intervention.
      final json = _relevageReport().toJson()..remove('kind');

      expect(Report.fromJson(json).kind, ReportKind.intervention);
    });

    test('range les photos par section, sans jamais dupliquer un lot', () {
      final report = _relevageReport();

      final first = report.photoGroupFor('cuve', title: 'Cuve');
      final again = report.photoGroupFor('cuve', title: 'Cuve');

      expect(identical(first, again), isTrue);
      expect(report.photoGroups.where((group) => group.id == 'cuve'),
          hasLength(1));
    });

    test('liste ce qui manque, et rien de plus quand tout est là', () {
      final report = _relevageReport()
        ..photoGroupFor('cuve', title: 'Cuve').photos.add(
              PhotoItem(id: 'p1', filePath: 'media/p1.png'),
            );

      expect(report.missingSections, isEmpty);
      expect(report.isReadyToExport, isTrue);
    });

    test('ne réclame pas les rubriques du rapport d\'intervention', () {
      final report = Report(
        id: 'vide',
        createdAt: DateTime(2026, 9, 11),
        updatedAt: DateTime(2026, 9, 11),
        kind: ReportKind.posteRelevage,
      );

      // Ni constats, ni conclusions, ni adresse de chantier : ce rapport-la ne
      // les comporte pas, les reclamer n'aurait aucun sens.
      expect(
        report.missingSections,
        ['Nom du client', 'Adresse du client', 'Type de poste', 'Intervenant',
          'États relevés', 'Photos'],
      );
    });
  });

  group('PDF du poste de relevage', () {
    test('produit un PDF valide, photos comprises', () async {
      final storage = FakeStorage();
      storage.files['media/p1.png'] = Uint8List.fromList(_onePixelPng);
      storage.files['media/p2.png'] = Uint8List.fromList(_onePixelPng);

      final report = _relevageReport();
      report.photoGroupFor('environnement', title: 'Environnement').photos.add(
            PhotoItem(id: 'p1', filePath: 'media/p1.png', caption: 'Le regard'),
          );
      report
          .photoGroupFor('pompes', title: 'Pompe(s)')
          .photos
          .add(PhotoItem(id: 'p2', filePath: 'media/p2.png'));

      final bytes = await PdfService(storage).buildReportPdf(
        report: report,
        company: AppSettings.defaults.company,
      );

      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(latin1.decode(bytes).trimRight(), endsWith('%%EOF'));
    });

    test('génère aussi le PDF d\'un poste à peine commencé', () async {
      final draft = Report(
        id: 'vide',
        createdAt: DateTime(2026, 9, 11),
        updatedAt: DateTime(2026, 9, 11),
        kind: ReportKind.posteRelevage,
      );

      final bytes = await PdfService(FakeStorage()).buildReportPdf(
        report: draft,
        company: AppSettings.defaults.company,
      );

      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('nomme le fichier d\'après le rapport et le client', () {
      final name = PdfService(FakeStorage()).fileNameFor(_relevageReport());

      expect(name, 'Rapport_ASE-110926-AL_Association-La-Roseraie.pdf');
    });

    test('met en page toutes les combinaisons d\'avant et d\'après', () async {
      // Un avant n'appelle pas forcement un apres, et l'inverse non plus : la
      // mise en page doit tenir dans tous les cas, y compris quand une rangee
      // manque tout a fait ou deborde de la largeur de la page.
      for (final counts in const <List<int>>[
        [1, 0], // que des avant
        [0, 1], // que des apres
        [1, 1],
        [3, 1], // une rangee moins fournie que l'autre
        [1, 3],
        [5, 4], // plus que la largeur d'une rangee
      ]) {
        final storage = FakeStorage();
        final report = _relevageReport();
        final group = report.photoGroupFor('cuve', title: 'Cuve');

        var n = 0;
        void add(int howMany, PhotoStage stage) {
          for (var i = 0; i < howMany; i++) {
            final path = 'media/p${n++}.png';
            storage.files[path] = Uint8List.fromList(_onePixelPng);
            group.photos
                .add(PhotoItem(id: path, filePath: path, stage: stage));
          }
        }

        add(counts[0], PhotoStage.avant);
        add(counts[1], PhotoStage.apres);

        final bytes = await PdfService(storage).buildReportPdf(
          report: report,
          company: AppSettings.defaults.company,
        );

        expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-',
            reason: '${counts[0]} avant / ${counts[1]} après');
      }
    });

    test('ne laisse jamais « Après » seul en bas d\'une page', () {
      // Le titre d'un moment et sa première rangée forment un bloc insécable :
      // sans cela la page se tourne juste entre les deux, et le rapport
      // annonce un « Après » que rien ne suit.
      final images = <String, pw.MemoryImage>{};
      final photos = <PhotoItem>[];
      for (var i = 0; i < 4; i++) {
        images['p$i'] = pw.MemoryImage(Uint8List.fromList(_onePixelPng));
        photos.add(PhotoItem(id: 'p$i', filePath: 'media/p$i.png'));
      }

      final rows = const RelevagePdfLayout(brandDark: PdfColors.blue)
          .photoRows(photos.sublist(0, 2), photos.sublist(2), images);

      // Deux blocs insécables : « Avant » et « Après », chacun avec sa rangée.
      expect(rows.whereType<pw.Inseparable>(), hasLength(2));
      expect(rows.first, isA<pw.Inseparable>());
    });

    test('imprime encore les photos des rapports d\'avant l\'avant/après',
        () async {
      // Celles-la n'ont pas de moment : elles rejoignent la rangee « Avant »
      // plutot que de disparaitre du rapport.
      final storage = FakeStorage();
      storage.files['media/vieille.png'] = Uint8List.fromList(_onePixelPng);

      final report = _relevageReport();
      report.photoGroupFor('exutoire', title: 'Exutoire').photos.add(
            PhotoItem(id: 'v1', filePath: 'media/vieille.png'),
          );

      expect(
        report.photoGroups
            .firstWhere((group) => group.id == 'exutoire')
            .inColumn(PhotoStage.avant),
        hasLength(1),
      );

      final bytes = await PdfService(storage).buildReportPdf(
        report: report,
        company: AppSettings.defaults.company,
      );

      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('assistant du poste de relevage', () {
    testWidgets('déroule le client, le poste, puis les huit sections',
        (tester) async {
      await _pumpRelevageWizard(tester, storage: FakeStorage());

      final titles = <String>[
        'Le client',
        'Le poste',
        for (final section in relevageSections) section.title,
      ];

      for (final title in titles) {
        expect(find.text(title), findsWidgets, reason: 'étape « $title »');
        if (title != titles.last) await _next(tester);
      }

      expect(find.text('Terminer'), findsOneWidget);
      expect(find.text('Suivant'), findsNothing);
    });

    testWidgets('un état coché est enregistré sous la clé de sa section',
        (tester) async {
      final reports = await _pumpRelevageWizard(tester, storage: FakeStorage());

      await _next(tester); // Le poste
      await _next(tester); // Environnement
      await _next(tester); // Cuve

      await _tap(tester, find.text('À remplacer'));
      await _next(tester);

      final saved = reports.all.single;
      expect(saved.kind, ReportKind.posteRelevage);
      expect(saved.checklistValue('cuve/Etat général avant nettoyage'),
          'À remplacer');
      // Un etat releve suffit a sortir le rapport du brouillon.
      expect(saved.status, ReportStatus.enCours);
    });

    testWidgets('chaque section propose un avant et un après', (tester) async {
      await _pumpRelevageWizard(tester, storage: FakeStorage());

      await _next(tester); // Le poste
      await _next(tester); // Environnement

      expect(find.text('Avant'), findsOneWidget);
      expect(find.text('Après'), findsOneWidget);
      // Chaque moment a sa propre tuile d'ajout.
      expect(find.text('Ajouter'), findsNWidgets(2));
    });

    testWidgets('la dernière étape rappelle ce qui reste à compléter',
        (tester) async {
      await _pumpRelevageWizard(tester, storage: FakeStorage());

      for (var i = 0; i < relevageSections.length + 1; i++) {
        await _next(tester);
      }

      await tester
          .ensureVisible(find.textContaining('information(s) à compléter'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Type de poste'), findsOneWidget);
    });
  });
}
