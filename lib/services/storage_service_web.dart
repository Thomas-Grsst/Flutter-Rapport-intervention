import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as p;
import 'package:web/web.dart' as web;

import 'media_store_web.dart';
import 'storage_service.dart';

/// Stockage utilise quand l'application tourne dans un navigateur.
///
/// L'application vise le telephone, mais pouvoir l'ouvrir dans un navigateur
/// permet de la faire essayer sans rien installer. Le navigateur remplace
/// alors le dossier documents, avec deux emplacements distincts :
///
/// - les fichiers JSON — rapports et reglages — vont dans le stockage local,
///   simple et synchrone, largement suffisant pour du texte ;
/// - les photos, signatures, logos et PDF vont dans IndexedDB, parce que le
///   stockage local plafonne a 5 Mo, soit une vingtaine de photos pour
///   l'ensemble des rapports.
class PlatformStorageService implements StorageService {
  static const String _prefix = 'rapport_intervention/';

  final MediaStoreWeb _media = MediaStoreWeb();

  web.Storage get _store => web.window.localStorage;

  String _key(String path) => '$_prefix$path';

  // --- JSON -----------------------------------------------------------------

  @override
  Future<Map<String, dynamic>?> readJson(String fileName) async {
    final content = _store.getItem(_key(fileName));
    if (content == null || content.trim().isEmpty) return null;
    return jsonDecode(content) as Map<String, dynamic>;
  }

  @override
  Future<void> writeJson(String fileName, Map<String, dynamic> data) async {
    _store.setItem(_key(fileName), jsonEncode(data));
  }

  // --- Fichiers -------------------------------------------------------------

  @override
  Future<String> importMedia(String sourcePath,
      {String prefix = 'photo'}) async {
    // Dans un navigateur, image_picker renvoie une URL de blob plutot qu'un
    // chemin de fichier : XFile sait la relire dans les deux cas.
    final bytes = await XFile(sourcePath).readAsBytes();
    final extension = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath).toLowerCase();
    return _write('media/${prefix}_${_stamp()}$extension', bytes);
  }

  @override
  Future<String> saveSignature(Uint8List bytes,
      {required String prefix}) async {
    return _write('media/${prefix}_${_stamp()}.png', bytes);
  }

  @override
  Future<String> writePdf(String fileName, Uint8List bytes) async {
    return _write('rapports/$fileName', bytes);
  }

  @override
  Future<void> deleteFileIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    await _media.delete(path);
    // Les medias enregistres par les versions precedentes vivaient dans le
    // stockage local : on les retire aussi, sinon ils l'encombreraient pour
    // toujours.
    _store.removeItem(_key(path));
  }

  @override
  Future<Uint8List?> readBytes(String? path) async {
    if (path == null || path.isEmpty) return null;

    final stored = await _media.read(path);
    if (stored != null) return stored;

    // Media enregistre par une version precedente, encore dans le stockage
    // local : on le relit, et on le deplace au passage.
    final legacy = _store.getItem(_key(path));
    if (legacy == null || legacy.isEmpty) return null;

    final bytes = base64Decode(legacy);
    await _media.write(path, bytes);
    _store.removeItem(_key(path));
    return bytes;
  }

  int _stamp() => DateTime.now().microsecondsSinceEpoch;

  Future<String> _write(String path, Uint8List bytes) async {
    await _media.write(path, bytes);
    return path;
  }
}
