import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/company.dart';
import '../models/enums.dart';
import '../models/photo_item.dart';
import '../models/relevage_template.dart';
import '../models/report.dart';

/// Met en page le rapport d'entretien de poste de relevage.
///
/// La mise en page suit le modèle de référence au plus près : le logo de part
/// et d'autre des coordonnées en tête de la première page, le bandeau bleu du
/// contrat, le bloc client centré, puis les sections du gabarit — chacune
/// annoncée par son bandeau, suivie de ses états et de ses photos. Le document
/// ne porte ni pied de page ni pagination, comme le modèle.
class RelevagePdfLayout {
  const RelevagePdfLayout({required this.brandDark});

  final PdfColor brandDark;

  static final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');

  /// Le contenu du rapport, prêt à être posé dans un MultiPage.
  List<pw.Widget> build({
    required Report report,
    required Company company,
    required Map<String, pw.MemoryImage> photoImages,
    pw.MemoryImage? logo,
  }) {
    return <pw.Widget>[
      _header(company, logo),
      pw.SizedBox(height: 26),
      _contractBanner(report),
      pw.SizedBox(height: 26),
      _clientBlock(report),
      pw.SizedBox(height: 24),
      for (final section in relevageSections)
        ..._section(section, report, photoImages),
    ];
  }

  // --- En-tête --------------------------------------------------------------

  pw.Widget _header(Company company, pw.MemoryImage? logo) {
    pw.Widget mark() => logo == null
        ? pw.SizedBox(width: 110)
        : pw.Container(
            width: 110,
            height: 62,
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          );

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        mark(),
        pw.Expanded(
          child: pw.Column(
            children: [
              for (final line in <String>[
                company.addressOneLine,
                if (company.phone.isNotEmpty) 'Téléphone : ${company.phone}',
                if (company.email.isNotEmpty) 'Mail : ${company.email}',
              ])
                if (line.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      line,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
            ],
          ),
        ),
        mark(),
      ],
    );
  }

  // --- Bandeau du contrat ---------------------------------------------------

  pw.Widget _contractBanner(Report report) {
    final lines = <String>[
      if (report.contractDate != null)
        'Contrat de maintenance poste de relevage en date du '
            '${_dayFormat.format(report.contractDate!)}',
      if (report.equipmentBrand.trim().isNotEmpty)
        'Marque du poste de relevage : ${report.equipmentBrand.trim()}',
      if (report.equipmentType.trim().isNotEmpty)
        'Type de poste de relevage : ${report.equipmentType.trim()}',
    ];
    if (lines.isEmpty) return pw.SizedBox();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: pw.BoxDecoration(
        color: brandDark,
        borderRadius: pw.BorderRadius.circular(22),
      ),
      child: pw.Column(
        children: [
          for (final line in lines)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                line,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.white,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Bloc client ----------------------------------------------------------

  pw.Widget _clientBlock(Report report) {
    final lines = <String>[
      if (report.clientName.trim().isNotEmpty)
        'Client : ${report.clientName.trim()}',
      if (report.clientAddressLine.trim().isNotEmpty)
        'Adresse : ${report.clientAddressLine.trim()}',
      if (report.clientPostalCode.trim().isNotEmpty)
        'Code postal : ${report.clientPostalCode.trim()}',
      if (report.clientCity.trim().isNotEmpty)
        'Commune : ${report.clientCity.trim()}',
      if (report.clientPhone.trim().isNotEmpty)
        'Téléphone : ${report.clientPhone.trim()}',
      if (report.clientEmail.trim().isNotEmpty)
        'E-Mail : « ${report.clientEmail.trim()} »',
    ];

    // Pleine largeur : une colonne se resserre par defaut sur sa ligne la plus
    // longue, et le bloc entier se posait alors a gauche de la page — centre
    // sur lui-meme, mais pas sur la feuille.
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        children: [
          for (final line in lines)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Text(
                line,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Sections -------------------------------------------------------------

  /// Une section : son bandeau, ses états, puis ses photos.
  ///
  /// Le bandeau part avec les états qui le suivent — un titre seul en bas
  /// d'une page se remarque tout de suite. Les lignes de photos sont ensuite
  /// des enfants distincts, pour que la coupure entre deux pages tombe entre
  /// deux lignes et jamais au milieu d'une image.
  List<pw.Widget> _section(
    RelevageSection section,
    Report report,
    Map<String, pw.MemoryImage> images,
  ) {
    final values = <String>[
      for (final field in section.fields)
        if (report.checklistValue(section.keyOf(field)).isNotEmpty)
          '${field.label} : '
              '${report.checklistValue(section.keyOf(field))}',
    ];
    final freeText =
        section.hasFreeText ? report.checklistValue(section.id) : '';

    final avant = <PhotoItem>[];
    final apres = <PhotoItem>[];
    for (final group in report.photoGroups) {
      if (group.id != section.id) continue;
      // Une photo dont le fichier a disparu ne compte pas : l'imprimer
      // laisserait un cadre vide au milieu de la section.
      avant.addAll(group
          .inColumn(PhotoStage.avant)
          .where((photo) => images.containsKey(photo.id)));
      apres.addAll(group
          .ofStage(PhotoStage.apres)
          .where((photo) => images.containsKey(photo.id)));
    }

    // Une section entièrement vide n'est pas imprimée : elle ne dirait rien.
    if (values.isEmpty && freeText.isEmpty && avant.isEmpty && apres.isEmpty) {
      return const <pw.Widget>[];
    }

    final rows = photoRows(avant, apres, images);

    return <pw.Widget>[
      pw.Inseparable(
        child: pw.Column(
          children: [
            _sectionBanner(section.title),
            pw.SizedBox(height: 10),
            for (final value in values)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                child: pw.Text(
                  value,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10.5),
                ),
              ),
            if (freeText.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  freeText,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 2.5),
                ),
              ),
            if (rows.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              rows.first,
            ],
          ],
        ),
      ),
      ...rows.skip(1),
      pw.SizedBox(height: 22),
    ];
  }

  pw.Widget _sectionBanner(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: pw.BoxDecoration(
        color: brandDark,
        borderRadius: pw.BorderRadius.circular(18),
      ),
      child: pw.Text(
        title,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(
          fontSize: 13,
          color: PdfColors.white,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  /// Au plus trois photos par ligne : au-delà, chacune devient trop petite
  /// pour qu'on y distingue quoi que ce soit.
  static const int _maxPerRow = 3;

  /// Les photos d'une section : la rangée des « avant », puis celle des
  /// « après » juste en dessous.
  ///
  /// Les deux rangées partagent le même nombre de colonnes, celui de la plus
  /// fournie. Une photo d'après tombe ainsi sous une photo d'avant de même
  /// largeur, même quand il y en a moins — et l'une des deux rangées peut
  /// manquer tout à fait : tout ne se photographie pas deux fois.
  @visibleForTesting
  List<pw.Widget> photoRows(
    List<PhotoItem> avant,
    List<PhotoItem> apres,
    Map<String, pw.MemoryImage> images,
  ) {
    if (avant.isEmpty && apres.isEmpty) return const <pw.Widget>[];

    final perRow =
        (avant.length > apres.length ? avant.length : apres.length)
            .clamp(1, _maxPerRow);

    return <pw.Widget>[
      ..._stageRows('Avant', avant, perRow, images),
      ..._stageRows('Après', apres, perRow, images),
    ];
  }

  /// Les lignes d'un moment — « Avant » ou « Après » — précédées de son titre.
  List<pw.Widget> _stageRows(
    String title,
    List<PhotoItem> photos,
    int perRow,
    Map<String, pw.MemoryImage> images,
  ) {
    if (photos.isEmpty) return const <pw.Widget>[];

    final height = perRow == 1
        ? 195.0
        : perRow == 2
            ? 150.0
            : 115.0;

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
                if (column > 0) pw.SizedBox(width: 8),
                // Les colonnes vides de fin de ligne gardent leur place :
                // c'est ce qui aligne les « après » sous les « avant ».
                pw.Expanded(
                  child: column < slice.length
                      ? _photo(slice[column], images[slice[column].id]!, height)
                      : pw.SizedBox(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Le titre part avec sa première rangée : « Après » seul en bas d'une page
    // ne voudrait rien dire. Sans Inseparable, une colonne se coupe entre ses
    // enfants et c'est exactement là que la page se serait tournée.
    return <pw.Widget>[
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: brandDark,
                ),
              ),
            ),
            rows.first,
          ],
        ),
      ),
      ...rows.skip(1),
    ];
  }

  pw.Widget _photo(PhotoItem photo, pw.MemoryImage image, double height) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // La photo entière, sans rognage : un cadrage automatique couperait
        // justement ce que l'intervenant a voulu montrer.
        pw.Container(
          height: height,
          width: double.infinity,
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
        if (photo.caption.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Text(
              photo.caption.trim(),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8.5),
            ),
          ),
      ],
    );
  }
}
