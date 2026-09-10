import 'package:flutter_test/flutter_test.dart';
import 'package:rapport_intervention/models/company.dart';
import 'package:rapport_intervention/models/enums.dart';
import 'package:rapport_intervention/models/photo_item.dart';
import 'package:rapport_intervention/models/report.dart';

Report _sample() => Report(
      id: 'r1',
      createdAt: DateTime(2026, 3, 12, 8),
      updatedAt: DateTime(2026, 3, 12, 12, 30),
      reportNumber: 'ASE-120326-MB',
      interventionType: 'Entretien poste de relevage',
      interventionDate: DateTime(2026, 3, 12),
      clientName: 'M. Manuel BLANC',
      siteAddressLine: '544 Rue du Vieux Château',
      sitePostalCode: '69250',
      siteCity: 'MONTANAY',
      technicians: const [Technician(name: 'Thierry GROSSAT')],
      findings: "Entretien d'une fosse de relevage.",
      actions: ['Pompage de la fosse'],
      conclusions: "La conformité de l'intervention est attestée.",
      status: ReportStatus.termine,
      photos: [
        PhotoItem(id: 'p1', filePath: '/tmp/a.jpg', stage: PhotoStage.avant),
        PhotoItem(id: 'p2', filePath: '/tmp/b.jpg', stage: PhotoStage.apres),
      ],
    );

void main() {
  group('Report', () {
    test('survit à un aller-retour JSON', () {
      final original = _sample();
      final restored = Report.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.reportNumber, original.reportNumber);
      expect(restored.status, ReportStatus.termine);
      expect(restored.photos.length, 2);
      expect(restored.photos.first.stage, PhotoStage.avant);
      expect(restored.actions, ['Pompage de la fosse']);
    });

    test('clone() est une copie indépendante', () {
      final original = _sample();
      final copy = original.clone();
      copy.clientName = 'Autre client';
      copy.photos.clear();

      expect(original.clientName, 'M. Manuel BLANC');
      expect(original.photos.length, 2);
    });

    test('signale les sections manquantes', () {
      final incomplete = Report(
        id: 'r2',
        createdAt: DateTime(2026, 3, 12),
        updatedAt: DateTime(2026, 3, 12),
      );

      expect(incomplete.isReadyToExport, isFalse);
      expect(incomplete.missingSections, contains('Nom du client'));
      expect(_sample().isReadyToExport, isTrue);
    });

    test('énumère les intervenants pour le rapport', () {
      final report = _sample()
        ..technicians = const [
          Technician(name: 'Thierry GROSSAT'),
          Technician(name: 'Marc DUPONT'),
          Technician(name: 'Léa MARTIN'),
        ];

      expect(report.techniciansLine,
          'Thierry GROSSAT, Marc DUPONT et Léa MARTIN');
      expect(report.missingSections, isNot(contains('Intervenant')));

      report.technicians = const [];
      expect(report.techniciansLine, isEmpty);
      expect(report.missingSections, contains('Intervenant'));
    });

    test('relit un rapport enregistré avant les intervenants multiples', () {
      // Les rapports déjà sur le téléphone portaient un seul nom : ils
      // doivent se rouvrir sans perdre leur intervenant.
      final ancien = {
        ...Report(
          id: 'r3',
          createdAt: DateTime(2026, 3, 12),
          updatedAt: DateTime(2026, 3, 12),
        ).toJson(),
        'technicianName': 'Thierry GROSSAT',
        'technicianPhone': '06 50 36 50 00',
      }..remove('technicians');

      final report = Report.fromJson(ancien);

      expect(report.technicians, hasLength(1));
      expect(report.techniciansLine, 'Thierry GROSSAT');
      expect(report.technicians.single.phone, '06 50 36 50 00');
    });

    test('distingue une intervention sur plusieurs jours', () {
      final report = _sample();
      expect(report.isMultiDay, isFalse);

      // Une date de fin identique au premier jour reste une seule journée.
      report.interventionEndDate = DateTime(2026, 3, 12, 18);
      expect(report.isMultiDay, isFalse);

      report.interventionEndDate = DateTime(2026, 3, 14);
      expect(report.isMultiDay, isTrue);
      expect(Report.fromJson(report.toJson()).interventionEndDate,
          DateTime(2026, 3, 14));
    });

    test('regroupe les photos par moment de prise de vue', () {
      final report = _sample();

      expect(report.photosOfStage(PhotoStage.avant).length, 1);
      expect(report.photosOfStage(PhotoStage.pendant), isEmpty);
    });
  });
}
