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
    test('ne contiennent aucune entreprise ni aucun intervenant', () {
      // L'application se télécharge sur une boutique : y laisser les
      // coordonnées, le SIRET ou les intervenants de quelqu'un les
      // distribuerait à tous ceux qui l'installent.
      final settings = AppSettings.defaults;

      expect(settings.company.name, isEmpty);
      expect(settings.company.siret, isEmpty);
      expect(settings.company.phone, isEmpty);
      expect(settings.company.email, isEmpty);
      expect(settings.company.logoPath, anyOf(isNull, isEmpty));
      expect(settings.technicians, isEmpty);
      expect(settings.reportNumberPrefix, isEmpty);
    });

    test('proposent tout de même les gestes du métier', () {
      // Ceux-là ne désignent personne : ils font gagner du temps dès la
      // première ouverture, et restent modifiables.
      final settings = AppSettings.defaults;

      expect(settings.interventionTypes, isNotEmpty);
      expect(settings.materialPresets, isNotEmpty);
      expect(settings.findingPresets, isNotEmpty);
      expect(settings.actionPresets, isNotEmpty);
    });
  });
}
