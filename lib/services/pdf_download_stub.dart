import 'dart:typed_data';

import 'pdf_download.dart';

/// Implementation de repli, jamais compilee en pratique : les imports
/// conditionnels de [downloadPdf] choisissent toujours la version fichiers ou
/// la version navigateur. Elle existe pour que l'import conditionnel ait une
/// cible par defaut.
Future<PdfDownload> platformDownloadPdf(Uint8List bytes, String fileName) async
    => PdfDownload.unavailable;
