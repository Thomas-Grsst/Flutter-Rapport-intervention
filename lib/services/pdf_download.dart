import 'dart:typed_data';

import 'pdf_download_stub.dart'
    if (dart.library.io) 'pdf_download_io.dart'
    if (dart.library.js_interop) 'pdf_download_web.dart';

/// Ce qu'il est advenu d'un PDF qu'on a voulu telecharger.
class PdfDownload {
  const PdfDownload({required this.done, this.path});

  /// Le telechargement a abouti sans autre geste a faire.
  final bool done;

  /// L'endroit ou le fichier a atterri, quand il porte un nom lisible pour
  /// l'utilisateur. Null dans un navigateur, ou c'est lui qui decide.
  final String? path;

  /// Rien n'a pu etre enregistre : l'appelant doit proposer autre chose,
  /// comme la feuille de partage du systeme, qui sait « Enregistrer dans
  /// Fichiers ».
  static const PdfDownload unavailable = PdfDownload(done: false);
}

/// Enregistre un PDF genere a un endroit ou l'utilisateur le retrouvera.
///
/// Imprimer et envoyer ne suffisent pas toujours : il faut parfois simplement
/// garder le fichier. Chaque plateforme a sa facon de faire — le navigateur
/// telecharge, le telephone ecrit dans son dossier de telechargements — d'ou
/// cette indirection, pour que l'ecran qui l'appelle n'ait pas a le savoir.
Future<PdfDownload> downloadPdf(Uint8List bytes, String fileName) =>
    platformDownloadPdf(bytes, fileName);
