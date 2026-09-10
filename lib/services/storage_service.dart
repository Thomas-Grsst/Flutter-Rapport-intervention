import 'dart:typed_data';

import 'storage_service_stub.dart'
    if (dart.library.io) 'storage_service_io.dart'
    if (dart.library.js_interop) 'storage_service_web.dart';

/// Acces au stockage local : fichiers JSON de donnees, photos, signatures et
/// PDF generes. Tout reste sur l'appareil, aucune connexion n'est requise sur
/// un chantier.
///
/// Deux implementations sont fournies :
///
/// - sur mobile, [createStorageService] renvoie un stockage sur fichiers, dans
///   le dossier documents de l'application ;
/// - dans un navigateur, un stockage equivalent adosse au stockage local du
///   navigateur, pour pouvoir essayer l'application sans telephone.
///
/// Les chemins manipules par le reste de l'application (`filePath` d'une
/// photo, `logoPath` de l'entreprise) restent de simples chaines : les ecrans
/// n'ont jamais a savoir sur quelle plateforme ils tournent.
abstract class StorageService {
  /// Le stockage adapte a la plateforme sur laquelle l'application tourne.
  factory StorageService() = PlatformStorageService;

  // --- JSON -----------------------------------------------------------------

  /// Lit un fichier JSON de donnees, ou renvoie null s'il n'existe pas encore.
  Future<Map<String, dynamic>?> readJson(String fileName);

  /// Enregistre un fichier JSON de donnees, sans jamais laisser de contenu
  /// tronque derriere soi si l'application est fermee pendant l'ecriture.
  Future<void> writeJson(String fileName, Map<String, dynamic> data);

  // --- Fichiers -------------------------------------------------------------

  /// Copie une photo choisie dans la galerie ou prise avec l'appareil vers le
  /// stockage de l'application, et renvoie le nouveau chemin.
  Future<String> importMedia(String sourcePath, {String prefix = 'photo'});

  /// Enregistre une signature dessinee a l'ecran (PNG) et renvoie son chemin.
  Future<String> saveSignature(Uint8List bytes, {required String prefix});

  /// Enregistre un PDF genere et renvoie son chemin.
  Future<String> writePdf(String fileName, Uint8List bytes);

  Future<void> deleteFileIfExists(String? path);

  /// Lit un fichier local, ou renvoie null s'il a disparu.
  Future<Uint8List?> readBytes(String? path);
}
