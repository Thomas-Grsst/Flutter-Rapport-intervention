import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:web/web.dart' as web;

import 'storage_service.dart';

/// Stockage utilise quand l'application tourne dans un navigateur.
///
/// L'application vise le telephone, mais pouvoir l'ouvrir dans un navigateur
/// permet de la faire essayer sans rien installer. Le stockage du navigateur
/// remplace alors le dossier documents : les rapports et les reglages y sont
/// enregistres en JSON, les photos et signatures en base64.
///
/// Le stockage local d'un navigateur est limite (quelques megaoctets). Quand
/// il est plein, les fichiers restent en memoire pour la duree de la session
/// plutot que de faire echouer la saisie en cours : sur un poste de demo, on
/// prefere perdre les photos au rechargement que perdre le rapport tout de
/// suite.
class PlatformStorageService implements StorageService {
  static const String _prefix = 'rapport_intervention/';

  /// Fichiers que le stockage du navigateur a refuses, faute de place.
  final Map<String, Uint8List> _memoryFallback = <String, Uint8List>{};

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
    _memoryFallback.remove(path);
    _store.removeItem(_key(path));
  }

  @override
  Future<Uint8List?> readBytes(String? path) async {
    if (path == null || path.isEmpty) return null;

    final fromMemory = _memoryFallback[path];
    if (fromMemory != null) return fromMemory;

    final encoded = _store.getItem(_key(path));
    if (encoded == null || encoded.isEmpty) return null;
    return base64Decode(encoded);
  }

  int _stamp() => DateTime.now().microsecondsSinceEpoch;

  /// Ecrit un fichier binaire et renvoie son chemin. Si le stockage du
  /// navigateur est plein, le fichier est conserve en memoire pour la session.
  String _write(String path, Uint8List bytes) {
    try {
      _store.setItem(_key(path), base64Encode(bytes));
      _memoryFallback.remove(path);
    } catch (error) {
      _memoryFallback[path] = bytes;
      debugPrint(
        'Stockage du navigateur plein : "$path" est conserve en memoire '
        'jusqu\'au rechargement de la page ($error).',
      );
    }
    return path;
  }
}
