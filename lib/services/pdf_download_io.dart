import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show MissingPluginException;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'pdf_download.dart';

/// Ecrit le PDF dans le dossier de telechargements de l'appareil.
///
/// Sur Android et sur ordinateur, ce dossier existe et le fichier y reste
/// accessible depuis le gestionnaire de fichiers. Sur iOS il n'y en a pas :
/// on renvoie alors [PdfDownload.unavailable], a charge de l'ecran d'ouvrir la
/// feuille de partage du systeme, qui propose « Enregistrer dans Fichiers ».
Future<PdfDownload> platformDownloadPdf(
    Uint8List bytes, String fileName) async {
  Directory? directory;
  try {
    directory = await getDownloadsDirectory();
  } on MissingPluginException {
    directory = null;
  } on UnsupportedError {
    directory = null;
  }
  if (directory == null) return PdfDownload.unavailable;

  await directory.create(recursive: true);
  final file = File(_freePath(directory.path, fileName));
  await file.writeAsBytes(bytes, flush: true);

  return PdfDownload(done: true, path: file.path);
}

/// Un chemin encore libre : télécharger deux fois le même rapport ne doit pas
/// écraser la copie précédente sans prévenir.
String _freePath(String directory, String fileName) {
  final extension = p.extension(fileName);
  final base = p.basenameWithoutExtension(fileName);

  var candidate = p.join(directory, fileName);
  var index = 2;
  while (File(candidate).existsSync()) {
    candidate = p.join(directory, '$base ($index)$extension');
    index++;
  }
  return candidate;
}
