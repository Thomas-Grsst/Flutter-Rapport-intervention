import 'package:flutter_test/flutter_test.dart';
import 'package:rapport_intervention/models/enums.dart';
import 'package:rapport_intervention/models/photo_item.dart';
import 'package:rapport_intervention/models/report.dart';
import 'package:rapport_intervention/services/pdf_service.dart';
import 'package:rapport_intervention/services/storage_service.dart';

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
      technicianName: 'Thierry GROSSAT',
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

    test('regroupe les photos par moment de prise de vue', () {
      final report = _sample();

      expect(report.photosOfStage(PhotoStage.avant).length, 1);
      expect(report.photosOfStage(PhotoStage.pendant), isEmpty);
    });
  });

  group('PdfService', () {
    test("nomme le fichier d'après le rapport et le client", () {
      final name = PdfService(StorageService()).fileNameFor(_sample());

      expect(name, 'Rapport_ASE-120326-MB_M-Manuel-BLANC.pdf');
    });
  });
}
