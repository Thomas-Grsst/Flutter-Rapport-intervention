import 'dart:typed_data';

import 'storage_service.dart';

/// Implementation de repli, jamais compilee en pratique : les imports
/// conditionnels de [StorageService] choisissent toujours la version fichiers
/// ou la version navigateur. Elle existe pour que l'import conditionnel ait
/// une cible par defaut.
class PlatformStorageService implements StorageService {
  static Never _unsupported() => throw UnsupportedError(
        "Cette plateforme n'a pas de stockage : l'application vise le mobile "
        'et le navigateur.',
      );

  @override
  Future<Map<String, dynamic>?> readJson(String fileName) => _unsupported();

  @override
  Future<void> writeJson(String fileName, Map<String, dynamic> data) =>
      _unsupported();

  @override
  Future<String> importMedia(String sourcePath, {String prefix = 'photo'}) =>
      _unsupported();

  @override
  Future<String> saveSignature(Uint8List bytes, {required String prefix}) =>
      _unsupported();

  @override
  Future<String> writePdf(String fileName, Uint8List bytes) => _unsupported();

  @override
  Future<void> deleteFileIfExists(String? path) => _unsupported();

  @override
  Future<Uint8List?> readBytes(String? path) => _unsupported();
}
