import 'package:pdf/widgets.dart' as pw;

import '../models/photo_item.dart';
import 'pdf_style.dart';

/// Les photos d'une section d'un rapport d'entretien.
///
/// Les deux rapports sous contrat — poste de relevage et filtre compact — les
/// posent de la meme facon, et le lecteur passe de l'un a l'autre : la mise
/// en page vit donc ici, en un seul exemplaire.
class PhotoRows {
  const PhotoRows();

  /// Au plus trois photos par rangée : au-delà, chacune devient trop petite
  /// pour qu'on y distingue quoi que ce soit.
  static const int _maxPerRow = 3;

  /// Les photos d'une section : la rangée des « avant », puis celle des
  /// « après » juste en dessous.
  ///
  /// Les deux rangées partagent le même nombre de colonnes, celui de la plus
  /// fournie. Une photo d'après tombe ainsi sous une photo d'avant de même
  /// largeur, même quand il y en a moins — et l'une des deux rangées peut
  /// manquer tout à fait : tout ne se photographie pas deux fois.
  ///
  /// Une seule photo de chaque côté fait exception : elles se posent côte à
  /// côte sur une même ligne, l'avant puis l'après, ce qui les compare d'un
  /// coup d'œil et évite deux rangées presque vides.
  List<pw.Widget> build(
    List<PhotoItem> avant,
    List<PhotoItem> apres,
    Map<String, pw.MemoryImage> images,
  ) {
    if (avant.isEmpty && apres.isEmpty) return const <pw.Widget>[];

    if (avant.length == 1 && apres.length == 1) {
      return <pw.Widget>[_pairRow(avant.single, apres.single, images)];
    }

    final perRow = (avant.length > apres.length ? avant.length : apres.length)
        .clamp(1, _maxPerRow);

    return <pw.Widget>[
      ..._stageRows('Avant', avant, perRow, images),
      ..._stageRows('Après', apres, perRow, images),
    ];
  }

  /// L'avant et l'après côte à côte, chacun sous son intitulé.
  pw.Widget _pairRow(
    PhotoItem avant,
    PhotoItem apres,
    Map<String, pw.MemoryImage> images,
  ) {
    pw.Widget cell(String title, PhotoItem photo) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: _stageLabel(title),
            ),
            PdfStyle.photoCard(
              photo,
              images[photo.id]!,
              height: 140,
              fit: pw.BoxFit.contain,
              showStage: false,
            ),
          ],
        );

    return pw.Inseparable(
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: cell('Avant', avant)),
            pw.SizedBox(width: 10),
            pw.Expanded(child: cell('Après', apres)),
          ],
        ),
      ),
    );
  }

  pw.Widget _stageLabel(String title) => pw.Text(
        title,
        style: const pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfStyle.brandDark,
        ),
      );

  /// Les rangées d'un moment — « Avant » ou « Après » — sous son intitulé.
  List<pw.Widget> _stageRows(
    String title,
    List<PhotoItem> photos,
    int perRow,
    Map<String, pw.MemoryImage> images,
  ) {
    if (photos.isEmpty) return const <pw.Widget>[];

    final height = perRow == 1
        ? 175.0
        : perRow == 2
            ? 140.0
            : 110.0;

    final rows = <pw.Widget>[];
    for (var start = 0; start < photos.length; start += perRow) {
      final slice = photos.sublist(
        start,
        start + perRow > photos.length ? photos.length : start + perRow,
      );

      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < perRow; column++) ...[
                if (column > 0) pw.SizedBox(width: 10),
                // Les colonnes vides de fin de rangée gardent leur place :
                // c'est ce qui aligne les « après » sous les « avant ».
                pw.Expanded(
                  child: column < slice.length
                      ? PdfStyle.photoCard(
                          slice[column],
                          images[slice[column].id]!,
                          height: height,
                          // La photo entière, sans rognage : un cadrage
                          // automatique couperait justement ce que
                          // l'intervenant a voulu montrer.
                          fit: pw.BoxFit.contain,
                          // La rangée annonce déjà le moment ; une pastille
                          // sur chaque photo ne ferait que le répéter.
                          showStage: false,
                        )
                      : pw.SizedBox(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // L'intitulé part avec sa première rangée : « Après » seul en bas d'une
    // page ne voudrait rien dire. Sans Inseparable, une colonne se coupe entre
    // ses enfants et c'est exactement là que la page se serait tournée.
    return <pw.Widget>[
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: _stageLabel(title),
            ),
            rows.first,
          ],
        ),
      ),
      ...rows.skip(1),
    ];
  }

}
