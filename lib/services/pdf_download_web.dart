import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'pdf_download.dart';

/// Telecharge le PDF par le navigateur, comme n'importe quel fichier.
///
/// Le PDF n'existe pas sur un disque ici : on le donne au navigateur sous
/// forme de Blob, et un lien cliqué en coulisses declenche le telechargement.
/// L'URL temporaire est relachee aussitot apres, sinon le Blob resterait en
/// memoire tant que l'onglet est ouvert.
Future<PdfDownload> platformDownloadPdf(
    Uint8List bytes, String fileName) async {
  final blob = web.Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);

  final link = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  web.document.body!.append(link);
  link.click();
  link.remove();
  web.URL.revokeObjectURL(url);

  // Le navigateur decide seul de l'endroit : on ne peut pas le nommer.
  return const PdfDownload(done: true);
}
