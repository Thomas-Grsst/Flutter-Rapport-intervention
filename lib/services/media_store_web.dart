import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Echec du stockage des fichiers du navigateur.
///
/// C'est une Exception et non une Error : les ecrans qui importent une photo
/// ou generent un PDF rattrapent les Exception pour afficher un message, et
/// une Error leur passerait sous le nez jusqu'au plantage.
class MediaStoreException implements Exception {
  const MediaStoreException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Range les photos, signatures, logos et PDF dans la base IndexedDB du
/// navigateur.
///
/// Le stockage local — celui qui accueille les fichiers JSON — plafonne a
/// 5 Mo, soit une vingtaine de photos de telephone pour l'ensemble des
/// rapports. Au-dela, l'ecriture echoue : le rapport continuait d'annoncer ses
/// photos, mais elles avaient disparu au rechargement suivant. IndexedDB se
/// compte en centaines de megaoctets et n'a pas ce probleme.
class MediaStoreWeb {
  static const String _dbName = 'rapport_intervention';
  static const String _storeName = 'media';

  Future<web.IDBDatabase>? _database;

  Future<web.IDBDatabase> get _db => _database ??= _open();

  Future<web.IDBDatabase> _open() {
    final completer = Completer<web.IDBDatabase>();
    final request = web.window.indexedDB.open(_dbName, 1);

    request.onupgradeneeded = (web.Event _) {
      final db = request.result as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName);
      }
    }.toJS;
    request.onsuccess = (web.Event _) {
      completer.complete(request.result as web.IDBDatabase);
    }.toJS;
    request.onerror = (web.Event _) {
      completer.completeError(
        const MediaStoreException(
          "Le navigateur a refusé d'ouvrir sa base de fichiers.",
        ),
      );
    }.toJS;

    return completer.future;
  }

  Future<void> write(String path, Uint8List bytes) async {
    final db = await _db;
    final transaction = db.transaction(_storeName.toJS, 'readwrite');
    transaction.objectStore(_storeName).put(bytes.toJS, path.toJS);
    await _completed(transaction);
  }

  Future<Uint8List?> read(String path) async {
    final db = await _db;
    final transaction = db.transaction(_storeName.toJS, 'readonly');
    final request = transaction.objectStore(_storeName).get(path.toJS);
    await _completed(transaction);

    final result = request.result;
    if (result == null) return null;
    return (result as JSUint8Array).toDart;
  }

  Future<void> delete(String path) async {
    final db = await _db;
    final transaction = db.transaction(_storeName.toJS, 'readwrite');
    transaction.objectStore(_storeName).delete(path.toJS);
    await _completed(transaction);
  }

  /// Attend la fin de la transaction plutot que celle de la requete : c'est
  /// seulement une fois la transaction validee que l'ecriture est acquise.
  Future<void> _completed(web.IDBTransaction transaction) {
    final completer = Completer<void>();
    transaction.oncomplete = (web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }.toJS;
    transaction.onerror = (web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          const MediaStoreException(
            "Le navigateur n'a pas pu enregistrer le fichier.",
          ),
        );
      }
    }.toJS;
    transaction.onabort = (web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          const MediaStoreException(
            'Enregistrement interrompu par le navigateur.',
          ),
        );
      }
    }.toJS;
    return completer.future;
  }
}
