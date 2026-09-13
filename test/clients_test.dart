import 'package:flutter_test/flutter_test.dart';
import 'package:rapport_intervention/models/client.dart';
import 'package:rapport_intervention/models/client_directory.dart';
import 'package:rapport_intervention/models/enums.dart';
import 'package:rapport_intervention/state/clients_provider.dart';

import 'fake_storage.dart';

Future<ClientsProvider> _carnet(FakeStorage storage) async {
  final clients = ClientsProvider(storage);
  await clients.load();
  return clients;
}

void main() {
  group('carnet livré', () {
    test('reprend les clients sous contrat', () {
      expect(defaultClients, hasLength(56));

      // Chaque client porte au moins un contrat, et un identifiant a lui.
      for (final client in defaultClients) {
        expect(client.name, isNotEmpty, reason: client.id);
        expect(client.contracts, isNotEmpty, reason: client.name);
      }
      expect(
        defaultClients.map((client) => client.id).toSet(),
        hasLength(defaultClients.length),
      );
    });

    test('fusionne les clients présents dans les deux contrats', () {
      // Deux clients ont un poste de relevage et un filtre compact : ils ne
      // doivent figurer qu'une fois, avec leurs deux contrats.
      final deuxContrats =
          defaultClients.where((client) => client.contracts.length > 1);

      expect(deuxContrats.map((client) => client.name),
          containsAll(['Mr CHAPUIS', 'Mme BERNARD']));
    });
  });

  group('ClientsProvider', () {
    test('part du carnet livré à la première ouverture, puis le relit',
        () async {
      final storage = FakeStorage();

      final premier = await _carnet(storage);
      expect(premier.all, hasLength(defaultClients.length));
      expect(storage.json['clients.json'], isNotNull);

      // Deuxième ouverture : on relit ce qui a été enregistré, sans repartir
      // du carnet livré — sinon un client supprimé reviendrait tout seul.
      final second = await _carnet(storage);
      expect(second.all, hasLength(defaultClients.length));
    });

    test('propose d\'abord les clients du contrat en cours', () async {
      final clients = await _carnet(FakeStorage());

      final pourRelevage = clients.forKind(ReportKind.posteRelevage);
      expect(
        pourRelevage.first.contracts,
        contains(ReportKind.posteRelevage),
      );
      // Les autres restent accessibles : une intervention ponctuelle peut
      // concerner n'importe qui.
      expect(pourRelevage, hasLength(defaultClients.length));
    });

    test('cherche sans se soucier des accents ni de la casse', () async {
      final clients = await _carnet(FakeStorage());

      final trouves = clients.forKind(ReportKind.posteRelevage, query: 'decines');

      expect(trouves, isNotEmpty);
      expect(trouves.first.name, contains('Roseraie'));
    });

    test('retrouve un client déjà connu par son nom et son adresse', () async {
      final clients = await _carnet(FakeStorage());
      final connu = clients.all.first;

      expect(
        clients.matching(name: connu.name, addressLine: connu.addressLine)?.id,
        connu.id,
      );
      expect(clients.matching(name: 'Personne', addressLine: ''), isNull);
    });

    test('enregistre un nouveau client, et le retrouve après relecture',
        () async {
      final storage = FakeStorage();
      final clients = await _carnet(storage);
      final avant = clients.all.length;

      final client = clients.draft(
        name: 'Mme NOUVELLE',
        addressLine: '3, Rue des Essais',
        postalCode: '01600',
        city: 'TREVOUX',
        phone: '06 00 00 00 00',
        email: 'nouvelle@example.fr',
        kind: ReportKind.filtreCompact,
      );
      await clients.save(client);

      expect(clients.all, hasLength(avant + 1));
      expect(
        (await _carnet(storage)).byId(client.id)?.name,
        'Mme NOUVELLE',
      );
    });

    test('met à jour un client existant plutôt que de le dupliquer', () async {
      final storage = FakeStorage();
      final clients = await _carnet(storage);
      final avant = clients.all.length;
      final connu = clients.all.first;

      await clients.save(connu.copyWith(postalCode: '69480'));

      expect(clients.all, hasLength(avant));
      expect(clients.byId(connu.id)?.postalCode, '69480');
    });

    test('survit à un aller-retour JSON, contrats compris', () {
      const client = Client(
        id: 'c1',
        name: 'Mr CHAPUIS',
        city: 'Fontaines Sur Saône',
        contracts: {ReportKind.posteRelevage, ReportKind.filtreCompact},
      );

      final relu = Client.fromJson(client.toJson());

      expect(relu.name, client.name);
      expect(relu.contracts, client.contracts);
    });
  });
}
