import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rapport_intervention/models/client.dart';
import 'package:rapport_intervention/models/client_directory.dart';
import 'package:rapport_intervention/models/enums.dart';
import 'package:rapport_intervention/models/report.dart';
import 'package:rapport_intervention/state/clients_provider.dart';
import 'package:rapport_intervention/widgets/client_directory_actions.dart';
import 'package:rapport_intervention/widgets/client_picker.dart';

import 'fake_storage.dart';

Future<ClientsProvider> _carnet(FakeStorage storage) async {
  final clients = ClientsProvider(storage);
  await clients.load();
  return clients;
}

/// Monte les boutons du carnet sur un rapport, comme dans l'assistant.
Future<void> _pumpActions(
  WidgetTester tester, {
  required ClientsProvider clients,
  required Report draft,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<ClientsProvider>.value(
      value: clients,
      child: MaterialApp(
        home: Scaffold(
          body: ClientDirectoryActions(draft: draft, onChanged: () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Ouvre le carnet, comme le fait le bouton « Choisir un client ».
Future<void> _ouvreCarnet(
  WidgetTester tester, {
  required ClientsProvider clients,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<ClientsProvider>.value(
      value: clients,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => chooseClient(context, ReportKind.posteRelevage),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
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

  group('corriger une fiche depuis un rapport', () {
    testWidgets('met à jour le client repris du carnet, nom compris',
        (tester) async {
      // C'est tout l'intérêt du lien : un nom ou une adresse corrigés sur le
      // chantier doivent corriger la fiche, pas créer un second client.
      final clients = await _carnet(FakeStorage());
      final avant = clients.all.length;
      final connu = clients.all.first;

      final draft = Report(
        id: 'r1',
        createdAt: DateTime(2026, 9, 14),
        updatedAt: DateTime(2026, 9, 14),
        kind: ReportKind.posteRelevage,
        clientId: connu.id,
        clientName: '${connu.name} — corrigé',
        clientAddressLine: '3, Rue Neuve',
        clientPostalCode: '69480',
        clientCity: connu.city,
      );

      await _pumpActions(tester, clients: clients, draft: draft);
      expect(find.text('Mettre à jour la fiche client'), findsOneWidget);

      await tester.tap(find.text('Mettre à jour la fiche client'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Mettre à jour'));
      await tester.pumpAndSettle();

      expect(clients.all, hasLength(avant));
      expect(clients.byId(connu.id)?.name, '${connu.name} — corrigé');
      expect(clients.byId(connu.id)?.addressLine, '3, Rue Neuve');
      expect(clients.byId(connu.id)?.postalCode, '69480');
    });

    testWidgets('sait tout de même en faire un nouveau client',
        (tester) async {
      // Reprendre un client puis tout retaper, c'est parfois vouloir son
      // voisin : le choix reste offert au moment de confirmer.
      final clients = await _carnet(FakeStorage());
      final avant = clients.all.length;
      final connu = clients.all.first;

      final draft = Report(
        id: 'r1',
        createdAt: DateTime(2026, 9, 14),
        updatedAt: DateTime(2026, 9, 14),
        clientId: connu.id,
        clientName: 'Mme VOISINE',
        clientAddressLine: '5, Rue Neuve',
      );

      await _pumpActions(tester, clients: clients, draft: draft);
      await tester.tap(find.text('Mettre à jour la fiche client'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Nouveau client'));
      await tester.pumpAndSettle();

      expect(clients.all, hasLength(avant + 1));
      expect(clients.byId(connu.id)?.name, connu.name);
      expect(draft.clientId, isNot(connu.id));
    });

    testWidgets('propose d\'ajouter un client encore inconnu', (tester) async {
      final clients = await _carnet(FakeStorage());
      final avant = clients.all.length;

      final draft = Report(
        id: 'r1',
        createdAt: DateTime(2026, 9, 14),
        updatedAt: DateTime(2026, 9, 14),
        clientName: 'Mme INCONNUE',
        clientAddressLine: '7, Rue Neuve',
      );

      await _pumpActions(tester, clients: clients, draft: draft);
      expect(find.text('Ajouter au carnet'), findsOneWidget);

      await tester.tap(find.text('Ajouter au carnet'));
      await tester.pumpAndSettle();

      // Aucune confirmation : rien n'est écrasé.
      expect(clients.all, hasLength(avant + 1));
      expect(draft.clientId, isNotNull);
    });
  });

  group('retirer un client du carnet', () {
    testWidgets('le supprime après confirmation', (tester) async {
      final clients = await _carnet(FakeStorage());
      final avant = clients.all.length;

      await _ouvreCarnet(tester, clients: clients);

      // On réduit la liste à un seul client, pour viser sans ambiguïté.
      await tester.enterText(find.byType(TextField), 'roseraie');
      await tester.pumpAndSettle();
      final vise = clients.forKind(ReportKind.posteRelevage, query: 'roseraie')
          .single;

      await tester.tap(find.byTooltip('Retirer du carnet'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Retirer'));
      await tester.pumpAndSettle();

      expect(clients.all, hasLength(avant - 1));
      expect(clients.byId(vise.id), isNull);

      // La liste du carnet se met à jour sous les yeux.
      expect(find.text(vise.name), findsNothing);
    });

    testWidgets('ne supprime rien si on annule', (tester) async {
      final clients = await _carnet(FakeStorage());
      final avant = clients.all.length;

      await _ouvreCarnet(tester, clients: clients);
      await tester.enterText(find.byType(TextField), 'roseraie');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Retirer du carnet'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
      await tester.pumpAndSettle();

      expect(clients.all, hasLength(avant));
    });
  });
}
