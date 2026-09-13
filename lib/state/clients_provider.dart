import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/client.dart';
import '../models/client_directory.dart';
import '../models/enums.dart';
import '../services/storage_service.dart';

/// Le carnet d'adresses : les clients sous contrat, et ceux ajoutes en route.
///
/// Il est enregistre a part des rapports, dans clients.json : un client
/// survit a la suppression de ses rapports, et une correction d'adresse
/// profite aux visites suivantes.
class ClientsProvider extends ChangeNotifier {
  ClientsProvider(this._storage);

  static const String _fileName = 'clients.json';

  final StorageService _storage;
  final Uuid _uuid = const Uuid();

  List<Client> _clients = <Client>[];

  /// Tous les clients, par commune puis par nom — l'ordre du recapitulatif
  /// papier, celui dans lequel on les cherche.
  List<Client> get all => List.unmodifiable(_clients);

  Future<void> load() async {
    final data = await _storage.readJson(_fileName);

    if (data == null) {
      // Premiere ouverture : on part du carnet livre avec l'application.
      _clients = List<Client>.from(defaultClients);
      await _save();
    } else {
      _clients = (data['clients'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => Client.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    _sort();
    notifyListeners();
  }

  /// Les clients d'un contrat donne, puis les autres.
  ///
  /// Un entretien de poste de relevage se fait chez un client qui en a un :
  /// les siens viennent en tete, sans pour autant cacher le reste du carnet —
  /// une intervention ponctuelle peut concerner n'importe qui.
  List<Client> forKind(ReportKind kind, {String query = ''}) {
    final needle = _fold(query);
    final found = needle.isEmpty
        ? _clients
        : _clients
            .where((client) => _fold(client.searchText).contains(needle))
            .toList();

    if (kind == ReportKind.intervention) return List.unmodifiable(found);

    return List.unmodifiable([
      ...found.where((client) => client.contracts.contains(kind)),
      ...found.where((client) => !client.contracts.contains(kind)),
    ]);
  }

  Client? byId(String? id) {
    if (id == null) return null;
    for (final client in _clients) {
      if (client.id == id) return client;
    }
    return null;
  }

  /// Le client du carnet qui correspond a un nom et une adresse, s'il existe.
  ///
  /// Sert a savoir si le client saisi dans un rapport est deja connu, pour
  /// proposer de le mettre a jour plutot que de le creer en double.
  Client? matching({required String name, required String addressLine}) {
    final nom = _fold(name);
    if (nom.isEmpty) return null;
    final adresse = _fold(addressLine);

    for (final client in _clients) {
      if (_fold(client.name) == nom && _fold(client.addressLine) == adresse) {
        return client;
      }
    }
    return null;
  }

  /// Ajoute un client, ou met a jour celui qui porte le meme identifiant.
  Future<Client> save(Client client) async {
    final index = _clients.indexWhere((item) => item.id == client.id);
    if (index >= 0) {
      _clients[index] = client;
    } else {
      _clients.add(client);
    }

    _sort();
    await _save();
    notifyListeners();
    return client;
  }

  /// Cree un client a partir de ce qui a ete saisi dans un rapport.
  Client draft({
    required String name,
    required String addressLine,
    required String postalCode,
    required String city,
    required String phone,
    required String email,
    required ReportKind kind,
  }) {
    return Client(
      id: _uuid.v4(),
      name: name.trim(),
      addressLine: addressLine.trim(),
      postalCode: postalCode.trim(),
      city: city.trim(),
      phone: phone.trim(),
      email: email.trim(),
      contracts: kind == ReportKind.intervention
          ? const <ReportKind>{}
          : <ReportKind>{kind},
    );
  }

  Future<void> delete(Client client) async {
    _clients.removeWhere((item) => item.id == client.id);
    await _save();
    notifyListeners();
  }

  Future<void> _save() => _storage.writeJson(_fileName, {
        'clients': _clients.map((client) => client.toJson()).toList(),
      });

  void _sort() {
    _clients.sort((a, b) {
      final ville = _fold(a.city).compareTo(_fold(b.city));
      return ville != 0 ? ville : _fold(a.name).compareTo(_fold(b.name));
    });
  }

  /// Minuscules sans accents : « Décines » et « decines » se cherchent pareil.
  static String _fold(String value) {
    const avec = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿœæ';
    const sans = 'aaaaaaceeeeiiiinooooouuuuyyoa';

    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = avec.indexOf(char);
      buffer.write(index >= 0 ? sans[index] : char);
    }
    return buffer.toString().trim();
  }
}
