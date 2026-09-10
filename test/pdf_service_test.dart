import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart' show TtfParser;
import 'package:rapport_intervention/models/app_settings.dart';
import 'package:rapport_intervention/models/company.dart';
import 'package:rapport_intervention/models/enums.dart';
import 'package:rapport_intervention/models/report.dart';
import 'package:rapport_intervention/services/pdf_service.dart';

import 'fake_storage.dart';

/// Le rapport d'exemple du modele papier, utilise comme cas de reference.
Report _blancReport() => Report(
      id: 'r1',
      createdAt: DateTime(2026, 3, 12, 8),
      updatedAt: DateTime(2026, 3, 12, 12, 30),
      reportNumber: 'ASE-120326-MB',
      reference: 'DEV-2026-0148',
      interventionType: 'Entretien poste de relevage',
      interventionDate: DateTime(2026, 3, 12),
      startTime: '08:00',
      endTime: '12:30',
      clientName: 'M. Manuel BLANC',
      clientAddressLine: '544, Rue du Vieux Château',
      clientPostalCode: '69250',
      clientCity: 'MONTANAY',
      siteAddressLine: '544 Rue du Vieux Château',
      sitePostalCode: '69250',
      siteCity: 'MONTANAY',
      siteLocation: "Cuisine d'été extérieur",
      siteContact: 'M. Manuel BLANC',
      technicians: const [
        Technician(name: 'Thierry GROSSAT', phone: '06 50 36 50 00'),
      ],
      observations: 'Intervention programmée le jeudi matin 12/03/2026 pour '
          "le pompage et l'entretien du poste de relevage.",
      accessConstraints: 'Prévoir 50 à 70 mètres de tuyaux, le poste étant '
          'situé en partie basse du terrain.',
      materials: ['Camion hydrocureur', 'Tuyaux de pompage'],
      occupant: 'M. BLANC',
      findingTags: ['Fosse de relevage encrassée', 'Suspicion de contre-pente'],
      findings: "L'intervention a porté sur l'entretien d'une fosse de "
          'relevage.',
      actions: ['Pompage de la fosse', 'Débouchage des WC'],
      status: ReportStatus.termine,
      conclusions: "La conformité de l'intervention est attestée.",
      remainingPoints: 'Surveillance de la suspicion de contre-pente.',
      interventionLabel: 'Intervention assainissement',
      documentsToTransmit: "Rapport d'intervention",
      clientEvaluation: 'Client satisfait de la prestation.',
    );

void main() {
  // Le service charge les polices du PDF depuis les assets de l'application.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfService', () {
    test("nomme le fichier d'après le rapport et le client", () {
      final name = PdfService(FakeStorage()).fileNameFor(_blancReport());

      expect(name, 'Rapport_ASE-120326-MB_M-Manuel-BLANC.pdf');
    });

    test('produit un PDF valide', () async {
      final bytes = await PdfService(FakeStorage()).buildReportPdf(
        report: _blancReport(),
        company: AppSettings.defaults.company,
      );

      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(latin1.decode(bytes).trimRight(), endsWith('%%EOF'));
      expect(bytes.length, greaterThan(2000));
    });

    test('sa police sait dessiner les caractères du rapport', () async {
      // Les polices intégrées au format PDF omettent silencieusement le « œ »
      // de « Matériel(s) mis en œuvre » et le tiret cadratin de l'en-tête.
      // Un caractère absent de la police ne se voit qu'à l'impression, jamais
      // à la compilation : on vérifie ici que la police embarquée les couvre.
      final parser = TtfParser(await rootBundle.load(PdfService.regularFontAsset));

      const printed = 'œŒ—–éèêëàâçùûüôîïÉÀÈÇ«»°²’…•';
      final missing = printed.runes
          .where((rune) => !parser.charToGlyphIndexMap.containsKey(rune))
          .map(String.fromCharCode)
          .toList();

      expect(missing, isEmpty,
          reason: 'La police du rapport ne sait pas dessiner : $missing');
    });

    test('enregistre le PDF et renvoie de quoi le partager', () async {
      final storage = FakeStorage();
      final report = _blancReport();

      final saved = await PdfService(storage).saveReportPdf(
        report: report,
        company: AppSettings.defaults.company,
      );

      expect(saved.fileName, 'Rapport_ASE-120326-MB_M-Manuel-BLANC.pdf');
      expect(saved.bytes, isNotEmpty);
      expect(await storage.readBytes(saved.path), saved.bytes);
    });

    test('pagine un rapport très long sans se bloquer', () async {
      // Les blocs rendus insécables (titre + début de section, cadres de
      // signature) ne doivent jamais devenir plus hauts qu'une page : sinon
      // la mise en page n'aurait plus nulle part où les poser.
      final long = 'Texte de constat très détaillé. ' * 200;
      final report = _blancReport()
        ..observations = long
        ..accessConstraints = long
        ..findings = long
        ..conclusions = long
        ..remainingPoints = long
        ..clientEvaluation = long
        ..findingTags = List.generate(40, (i) => 'Constat numéro $i')
        ..actions = List.generate(40, (i) => 'Action numéro $i');

      final bytes = await PdfService(FakeStorage()).buildReportPdf(
        report: report,
        company: AppSettings.defaults.company,
      );

      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('génère aussi le PDF d\'un rapport à peine commencé', () async {
      final draft = Report(
        id: 'r2',
        createdAt: DateTime(2026, 3, 12),
        updatedAt: DateTime(2026, 3, 12),
      );

      final bytes = await PdfService(FakeStorage()).buildReportPdf(
        report: draft,
        company: AppSettings.defaults.company,
      );

      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });
}
