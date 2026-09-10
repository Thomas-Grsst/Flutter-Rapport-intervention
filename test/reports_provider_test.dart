import 'package:flutter_test/flutter_test.dart';
import 'package:rapport_intervention/models/app_settings.dart';
import 'package:rapport_intervention/models/enums.dart';
import 'package:rapport_intervention/models/report.dart';
import 'package:rapport_intervention/state/reports_provider.dart';

import 'fake_storage.dart';

Future<ReportsProvider> _provider(FakeStorage storage) async {
  final provider = ReportsProvider(storage);
  await provider.load();
  return provider;
}

Report _report(ReportsProvider provider, {required String clientName}) {
  final draft = provider.createDraft(AppSettings.defaults)
    ..clientName = clientName
    ..interventionDate = DateTime(2026, 3, 12);
  return draft;
}

void main() {
  group('Numéros de rapport', () {
    test('reprend le préfixe, la date et les initiales du client', () async {
      final provider = await _provider(FakeStorage());
      final report = _report(provider, clientName: 'M. Manuel BLANC');

      expect(
        provider.generateReportNumber(report, AppSettings.defaults),
        'ASE-120326-MB',
      );
    });

    test('ignore la forme juridique du client', () async {
      final provider = await _provider(FakeStorage());
      final report = _report(provider, clientName: 'SARL Dupont Immobilier');

      expect(
        provider.generateReportNumber(report, AppSettings.defaults),
        'ASE-120326-DI',
      );
    });

    test('ajoute un suffixe si le numéro est déjà pris', () async {
      final provider = await _provider(FakeStorage());

      final first = _report(provider, clientName: 'M. Manuel BLANC');
      first.reportNumber =
          provider.generateReportNumber(first, AppSettings.defaults);
      await provider.save(first);

      final second = _report(provider, clientName: 'Mme Marie BLANC');

      expect(
        provider.generateReportNumber(second, AppSettings.defaults),
        'ASE-120326-MB-2',
      );
    });
  });

  group('Recherche et filtres', () {
    test('la recherche ignore la casse et les accents', () async {
      final provider = await _provider(FakeStorage());
      final report = _report(provider, clientName: 'M. Manuel BLANC')
        ..siteCity = 'Trévoux';
      await provider.save(report);

      provider.setQuery('trevoux');
      expect(provider.visible, hasLength(1));

      provider.setQuery('MANUEL');
      expect(provider.visible, hasLength(1));

      provider.setQuery('lyon');
      expect(provider.visible, isEmpty);
    });

    test('le filtre sépare les rapports en cours des rapports terminés',
        () async {
      final provider = await _provider(FakeStorage());

      await provider.save(
        _report(provider, clientName: 'Client A')..status = ReportStatus.enCours,
      );
      await provider.save(
        _report(provider, clientName: 'Client B')..status = ReportStatus.termine,
      );

      provider.setFilter(ReportFilter.termines);
      expect(provider.visible.single.clientName, 'Client B');

      provider.setFilter(ReportFilter.enCours);
      expect(provider.visible.single.clientName, 'Client A');

      expect(provider.countFor(ReportFilter.tous), 2);
    });
  });

  group('Persistance', () {
    test('les rapports enregistrés sont relus au démarrage suivant', () async {
      final storage = FakeStorage();
      final provider = await _provider(storage);
      final report = _report(provider, clientName: 'M. Manuel BLANC')
        ..conclusions = 'Intervention conforme.';
      await provider.save(report);

      final reopened = await _provider(storage);

      expect(reopened.all, hasLength(1));
      expect(reopened.all.single.conclusions, 'Intervention conforme.');
    });

    test('dupliquer repart d\'un brouillon vierge de photos et signatures',
        () async {
      final provider = await _provider(FakeStorage());
      final source = _report(provider, clientName: 'M. Manuel BLANC')
        ..reportNumber = 'ASE-120326-MB'
        ..status = ReportStatus.termine
        ..clientSignaturePath = 'media/signature_client_0.png'
        ..photos.add(provider.buildPhoto('media/avant_0.jpg', PhotoStage.avant));
      await provider.save(source);

      final copy = provider.duplicate(source);

      expect(copy.id, isNot(source.id));
      expect(copy.clientName, 'M. Manuel BLANC');
      expect(copy.photos, isEmpty);
      expect(copy.clientSignaturePath, isNull);
      expect(copy.reportNumber, isEmpty);
      expect(copy.status, ReportStatus.brouillon);
    });

    test('supprimer efface aussi les photos et signatures du rapport',
        () async {
      final storage = FakeStorage();
      final provider = await _provider(storage);

      final photoPath = await storage.importMedia('source.jpg');
      final report = _report(provider, clientName: 'M. Manuel BLANC')
        ..photos.add(provider.buildPhoto(photoPath, PhotoStage.avant));
      await provider.save(report);

      await provider.delete(report);

      expect(provider.all, isEmpty);
      expect(await storage.readBytes(photoPath), isNull);
    });
  });
}
