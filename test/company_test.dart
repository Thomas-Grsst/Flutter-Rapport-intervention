import 'package:flutter_test/flutter_test.dart';
import 'package:rapport_intervention/models/app_settings.dart';
import 'package:rapport_intervention/models/company.dart';

import 'sample_company.dart';

void main() {
  group('Company', () {
    test('compose les mentions légales du pied de page', () {
      final legal = sampleCompany.legalLine;

      expect(legal, startsWith('SASU MARTIN ASSAINISSEMENT'));
      expect(legal, contains('SIRET : 12345678900012'));
      expect(legal, contains('APE : 3700Z'));
      expect(legal, contains('RCS BOURG EN BRESSE B 123 456 789'));
      expect(legal, contains('N° TVA intracom : FR00123456789'));
      expect(legal, contains('Capital : 5 000,00 €'));
    });

    test('retombe sur les coordonnées quand rien n\'est renseigné', () {
      // Un pied de page vide ferait plus mauvais effet qu'une adresse.
      const company = Company(
        legalForm: 'SASU',
        name: 'MARTIN ASSAINISSEMENT',
        addressLine: '12, Rue des Ateliers',
        postalCode: '01000',
        city: 'BOURG-EN-BRESSE',
        phone: '04 74 00 00 00',
      );

      expect(company.legalLine, company.contactLine);
      expect(company.legalLine,
          contains('12, Rue des Ateliers - 01000 BOURG-EN-BRESSE'));
    });

    test('sépare les coordonnées de l\'en-tête en lignes', () {
      expect(sampleCompany.contactLines, [
        '12, Rue des Ateliers - 01000 BOURG-EN-BRESSE',
        'Tél. : 04 74 00 00 00',
        'Mail : contact@martin-assainissement.fr',
      ]);
    });

    test('compose le cachet apposé en fin de rapport', () {
      expect(sampleCompany.stampLines, [
        'MARTIN ASSAINISSEMENT',
        '12, Rue des Ateliers - 01000 BOURG-EN-BRESSE',
        'SASU au capital de 5 000,00 €',
        'SIRET 12345678900012',
        'RCS BOURG EN BRESSE B 123 456 789',
        'TVA Intracommunautaire : FR00123456789',
      ]);
    });

    test('n\'imprime pas de ligne vide dans un cachet incomplet', () {
      const company = Company(name: 'MARTIN ASSAINISSEMENT', siret: '123');

      expect(company.stampLines, ['MARTIN ASSAINISSEMENT', 'SIRET 123']);
    });

    test('survit à un aller-retour JSON, mentions légales comprises', () {
      final restored = Company.fromJson(sampleCompany.toJson());

      expect(restored.siret, sampleCompany.siret);
      expect(restored.vatNumber, sampleCompany.vatNumber);
      expect(restored.legalLine, sampleCompany.legalLine);
    });
  });

  group('réglages livrés', () {
    test('sortent un rapport complet sans rien configurer', () {
      // L'application est distribuée en APK à l'entreprise qui l'utilise :
      // sa fiche est livrée remplie, et le premier rapport porte son en-tête,
      // ses mentions légales et son intervenant sans passer par les réglages.
      final settings = AppSettings.defaults;

      expect(settings.company.name, isNotEmpty);
      expect(settings.company.siret, isNotEmpty);
      expect(settings.company.legalLine, contains('SIRET'));
      expect(settings.technicians, isNotEmpty);
      expect(settings.reportNumberPrefix, isNotEmpty);
    });

    test('proposent les gestes du métier', () {
      final settings = AppSettings.defaults;

      expect(settings.interventionTypes, isNotEmpty);
      expect(settings.materialPresets, isNotEmpty);
      expect(settings.findingPresets, isNotEmpty);
      expect(settings.actionPresets, isNotEmpty);
    });
  });
}
