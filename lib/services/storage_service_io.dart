import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'storage_service.dart';

/// Stockage sur fichiers, utilise sur telephone.
///
/// Tout est ecrit dans le dossier documents de l'application :
///
/// - `reports.json` et `settings.json` a la racine ;
/// - `media/` pour les photos, le logo et les signatures ;
/// - `rapports/` pour les PDF generes.
class PlatformStorageService implements StorageService {
  Directory? _root;

  Future<Directory> get _rootDir async =>
      _root ??= await getApplicationDocumentsDirectory();

  Future<Directory> _subDirectory(String name) async {
    final dir = Directory(p.join((await _rootDir).path, name));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Dossier des photos et signatures importees.
  Future<Directory> get mediaDirectory => _subDirectory('media');

  /// Dossier des rapports PDF generes.
  Future<Directory> get pdfDirectory => _subDirectory('rapports');

  // --- JSON -----------------------------------------------------------------

  Future<File> _dataFile(String fileName) async =>
      File(p.join((await _rootDir).path, fileName));

  @override
  Future<Map<String, dynamic>?> readJson(String fileName) async {
    final file = await _dataFile(fileName);
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    if (content.trim().isEmpty) return null;
    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// Ecriture atomique : on ecrit dans un fichier temporaire puis on le
  /// renomme, pour ne jamais laisser un JSON tronque si l'application est
  /// fermee pendant l'enregistrement.
  @override
  Future<void> writeJson(String fileName, Map<String, dynamic> data) async {
    final file = await _dataFile(fileName);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(data), flush: true);
    await temp.rename(file.path);
  }

  // --- Fichiers -------------------------------------------------------------

  @override
  Future<String> importMedia(String sourcePath,
      {String prefix = 'photo'}) async {
    final dir = await mediaDirectory;
    final extension = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath).toLowerCase();
    final fileName =
        '${prefix}_${DateTime.now().microsecondsSinceEpoch}$extension';
    final target = File(p.join(dir.path, fileName));
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  @override
  Future<String> saveSignature(Uint8List bytes,
      {required String prefix}) async {
    final dir = await mediaDirectory;
    final fileName = '${prefix}_${DateTime.now().microsecondsSinceEpoch}.png';
    final target = File(p.join(dir.path, fileName));
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  @override
  Future<String> writePdf(String fileName, Uint8List bytes) async {
    final dir = await pdfDirectory;
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<void> deleteFileIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<Uint8List?> readBytes(String? path) async {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }
}
