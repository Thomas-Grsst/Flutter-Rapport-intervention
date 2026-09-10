import 'package:flutter_test/flutter_test.dart';
import 'package:rapport_intervention/models/app_settings.dart';
import 'package:rapport_intervention/models/company.dart';

void main() {
  group('Company', () {
    test('compose les mentions légales du pied de page', () {
      final legal = AppSettings.defaults.company.legalLine;

      expect(legal, startsWith("SASU AU SERVICE DE L'EAU"));
      expect(legal, contains('SIRET : 91345781800015'));
      expect(legal, contains('APE : 3700Z'));
      expect(legal, contains('RCS BOURG EN BRESSE B 913 457 818'));
      expect(legal, contains('N° TVA intracom : FR82913457818'));
      expect(legal, contains('Capital : 2 000,00 €'));
    });

    test('retombe sur les coordonnées quand rien n\'est renseigné', () {
      // Un pied de page vide ferait plus mauvais effet qu'une adresse.
      const company = Company(
        legalForm: 'SASU',
        name: "AU SERVICE DE L'EAU",
        addressLine: '164, Route de Lyon',
        postalCode: '01600',
        city: 'TREVOUX',
        phone: '06 50 36 50 00',
      );

      expect(company.legalLine, company.contactLine);
      expect(company.legalLine, contains('164, Route de Lyon - 01600 TREVOUX'));
    });

    test('sépare les coordonnées de l\'en-tête en lignes', () {
      final lines = AppSettings.defaults.company.contactLines;

      expect(lines, [
        '164, Route de Lyon - 01600 TREVOUX',
        'Tél. : 06 50 36 50 00',
        'Mail : contact@auservicedeleau.fr',
      ]);
    });

    test('compose le cachet apposé en fin de rapport', () {
      final stamp = AppSettings.defaults.company.stampLines;

      expect(stamp, [
        "AU SERVICE DE L'EAU",
        '164, Route de Lyon - 01600 TREVOUX',
        'SASU au capital de 2 000,00 €',
        'SIRET 91345781800015',
        'RCS BOURG EN BRESSE B 913 457 818',
        'TVA Intracommunautaire : FR82913457818',
      ]);
    });

    test('n\'imprime pas de ligne vide dans un cachet incomplet', () {
      const company = Company(name: "AU SERVICE DE L'EAU", siret: '123');

      expect(company.stampLines, ["AU SERVICE DE L'EAU", 'SIRET 123']);
    });

    test('survit à un aller-retour JSON, mentions légales comprises', () {
      final original = AppSettings.defaults.company;
      final restored = Company.fromJson(original.toJson());

      expect(restored.siret, original.siret);
      expect(restored.vatNumber, original.vatNumber);
      expect(restored.legalLine, original.legalLine);
    });
  });
}
