import 'dart:typed_data';

import 'package:rapport_intervention/services/storage_service.dart';

/// Stockage en memoire, utilise par les tests.
///
/// Les tests ne peuvent pas ecrire dans le dossier documents de l'application
/// (il n'existe pas sur la machine qui execute les tests) : ce double joue le
/// meme role sans toucher au disque.
class FakeStorage implements StorageService {
  final Map<String, Map<String, dynamic>> json = <String, Map<String, dynamic>>{};
  final Map<String, Uint8List> files = <String, Uint8List>{};

  @override
  Future<Map<String, dynamic>?> readJson(String fileName) async =>
      json[fileName];

  @override
  Future<void> writeJson(String fileName, Map<String, dynamic> data) async {
    json[fileName] = data;
  }

  @override
  Future<String> importMedia(String sourcePath,
      {String prefix = 'photo'}) async {
    final path = 'media/${prefix}_${files.length}.jpg';
    files[path] = Uint8List(0);
    return path;
  }

  @override
  Future<String> saveSignature(Uint8List bytes,
      {required String prefix}) async {
    final path = 'media/${prefix}_${files.length}.png';
    files[path] = bytes;
    return path;
  }

  @override
  Future<String> writePdf(String fileName, Uint8List bytes) async {
    final path = 'rapports/$fileName';
    files[path] = bytes;
    return path;
  }

  @override
  Future<void> deleteFileIfExists(String? path) async {
    if (path != null) files.remove(path);
  }

  @override
  Future<Uint8List?> readBytes(String? path) async =>
      path == null ? null : files[path];
}
