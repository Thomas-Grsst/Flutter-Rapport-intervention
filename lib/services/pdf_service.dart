import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/company.dart';
import '../models/enums.dart';
import '../models/photo_item.dart';
import '../models/report.dart';
import 'storage_service.dart';

/// Génère le PDF du rapport d'intervention.
///
/// La mise en page reprend section par section le modèle Word de référence :
/// page de garde, blocs d'identification, observations, matériel, constats et
/// actions, photographies, conclusions, points restants, récapitulatif et
/// évaluation du client. Chaque page porte le bandeau de l'entreprise en
/// pied de page ainsi que sa pagination.
class PdfService {
  PdfService(this._storage);

  final StorageService _storage;

  static final PdfColor brandDark = PdfColor.fromInt(0xFF104C7E);
  static final PdfColor brandLight = PdfColor.fromInt(0xFF8FB8E8);
  static final PdfColor paleBlue = PdfColor.fromInt(0xFFEAF2FB);
  static final PdfColor lineGrey = PdfColor.fromInt(0xFFD5DEE8);
  static final PdfColor textGrey = PdfColor.fromInt(0xFF5A6773);

  static final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');

  Future<Uint8List> buildReportPdf({
    required Report report,
    required Company company,
  }) async {
    final logo = await _image(company.logoPath);
    final clientSignature = await _image(report.clientSignaturePath);
    final technicianSignature = await _image(report.technicianSignaturePath);

    final photoImages = <String, pw.MemoryImage>{};
    for (final photo in report.photos) {
      final image = await _image(photo.filePath);
      if (image != null) photoImages[photo.id] = image;
    }

    final doc = pw.Document(
      title: 'Rapport d\'intervention ${report.reportNumber}'.trim(),
      author: company.displayName,
      subject: report.displayTitle,
    );

    doc.addPage(_coverPage(report: report, company: company, logo: logo));
    doc.addPage(
      _contentPages(
        report: report,
        company: company,
        logo: logo,
        photoImages: photoImages,
        clientSignature: clientSignature,
        technicianSignature: technicianSignature,
      ),
    );

    return doc.save();
  }

  /// Génère le PDF et l'enregistre dans le dossier "rapports" de
  /// l'application. Renvoie le fichier créé.
  Future<File> saveReportPdf({
    required Report report,
    required Company company,
  }) async {
    final bytes = await buildReportPdf(report: report, company: company);
    return _storage.writePdf(fileNameFor(report), bytes);
  }

  /// "Rapport_ASE-120326-MB_BLANC.pdf"
  String fileNameFor(Report report) {
    String clean(String value) => value
        .replaceAll(RegExp(r'[^A-Za-z0-9\-_ ]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');

    final parts = <String>[
      'Rapport',
      if (report.reportNumber.trim().isNotEmpty) clean(report.reportNumber),
      if (report.clientName.trim().isNotEmpty) clean(report.clientName),
      if (report.reportNumber.trim().isEmpty)
        _dayFormat.format(report.interventionDate).replaceAll('/', ''),
    ];
    return '${parts.where((part) => part.isNotEmpty).join('_')}.pdf';
  }

  Future<pw.MemoryImage?> _image(String? path) async {
    final bytes = await _storage.readBytes(path);
    return bytes == null ? null : pw.MemoryImage(bytes);
  }

  // --- Page de garde --------------------------------------------------------

  pw.Page _coverPage({
    required Report report,
    required Company company,
    pw.MemoryImage? logo,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (context) {
        return pw.Stack(
          children: [
            // Bandeau bleu vertical à gauche.
            pw.Positioned(
              left: 0,
              top: 0,
              child: pw.Container(
                width: 18,
                height: PdfPageFormat.a4.height,
                color: brandLight,
              ),
            ),
            // Largeur et hauteur explicites : la colonne ci-dessous utilise
            // des Spacer, qui ont besoin de contraintes bornées.
            pw.Container(
              width: PdfPageFormat.a4.width,
              height: PdfPageFormat.a4.height,
              padding: const pw.EdgeInsets.fromLTRB(60, 70, 45, 45),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logo != null)
                    pw.Container(
                      height: 110,
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    ),
                  pw.Spacer(),
                  pw.Text(
                    "Rapport d'intervention",
                    style: pw.TextStyle(
                      fontSize: 34,
                      fontWeight: pw.FontWeight.bold,
                      color: brandDark,
                    ),
                  ),
                  pw.SizedBox(height: 14),
                  pw.Container(width: 120, height: 3, color: brandLight),
                  pw.SizedBox(height: 22),
                  pw.Text(
                    report.displayTitle.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 18,
                      color: brandDark,
                      letterSpacing: 0.6,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Le ${_dayFormat.format(report.interventionDate)}',
                    style: pw.TextStyle(fontSize: 14, color: textGrey),
                  ),
                  pw.Spacer(),
                  if (company.name.isNotEmpty)
                    pw.Text(
                      company.name.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: brandDark,
                      ),
                    ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    company.footerLine,
                    style: pw.TextStyle(fontSize: 9.5, color: textGrey),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Pages de contenu -----------------------------------------------------

  pw.MultiPage _contentPages({
    required Report report,
    required Company company,
    required Map<String, pw.MemoryImage> photoImages,
    pw.MemoryImage? logo,
    pw.MemoryImage? clientSignature,
    pw.MemoryImage? technicianSignature,
  }) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(45, 40, 45, 55),
      header: (context) => _pageHeader(report, logo),
      footer: (context) => _pageFooter(context, company),
      build: (context) => <pw.Widget>[
        ..._identificationBlocks(report, company),
        ..._textSection('Observations', _observationsText(report)),
        ..._textSection(
          'Matériel(s) mis en œuvre',
          report.materials.isEmpty ? '' : '${report.materials.join(', ')}.',
        ),
        ..._findingsAndActions(report),
        ..._photoSection(report, photoImages),
        ..._conclusionSection(report),
        ..._interventionRecap(report),
        ..._evaluationSection(
          report: report,
          company: company,
          clientSignature: clientSignature,
          technicianSignature: technicianSignature,
        ),
        pw.SizedBox(height: 24),
        _legalNotice(report, company),
      ],
    );
  }

  pw.Widget _pageHeader(Report report, pw.MemoryImage? logo) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: brandLight, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          if (logo != null)
            pw.Container(height: 30, width: 60, child: pw.Image(logo, fit: pw.BoxFit.contain))
          else
            pw.SizedBox(width: 60),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                "Rapport d'intervention",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: brandDark,
                ),
              ),
              pw.Text(
                '${report.displayTitle} — ${_dayFormat.format(report.interventionDate)}',
                style: pw.TextStyle(fontSize: 8.5, color: textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pageFooter(pw.Context context, Company company) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: lineGrey)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              company.footerLine,
              style: pw.TextStyle(fontSize: 7.5, color: textGrey),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 7.5, color: textGrey),
          ),
        ],
      ),
    );
  }

  // --- Blocs d'identification ----------------------------------------------

  List<pw.Widget> _identificationBlocks(Report report, Company company) {
    return [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _infoBox(
              title: "Adresse d'intervention",
              lines: [
                report.siteAddressLine,
                report.siteCityLine,
                if (report.siteLocation.trim().isNotEmpty)
                  'Localisation : ${report.siteLocation}',
                if (report.siteContact.trim().isNotEmpty)
                  'Contact : ${report.siteContact}',
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: _infoBox(
              title: company.name.isEmpty ? 'Entreprise' : company.name,
              lines: [
                if (company.addressLine.isNotEmpty)
                  'Siège social : ${company.addressLine}',
                company.cityLine,
                if (company.phone.isNotEmpty) 'Tél. : ${company.phone}',
                if (company.email.isNotEmpty) 'E-mail : ${company.email}',
                '',
                'Intervenant : ${report.technicianName}',
                if (report.technicianPhone.trim().isNotEmpty)
                  'Tél. : ${report.technicianPhone}',
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _infoBox(
              title: 'Client',
              lines: [
                report.clientName,
                report.clientAddressLine,
                report.clientCityLine,
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: _infoBox(
              title: 'Référence',
              lines: [
                if (report.reportNumber.trim().isNotEmpty)
                  'N° rapport : ${report.reportNumber}',
                if (report.reference.trim().isNotEmpty)
                  'V/Réf : ${report.reference}',
                'Intervention du ${_dayFormat.format(report.interventionDate)}',
                if (_scheduleLine(report).isNotEmpty) _scheduleLine(report),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 22),
    ];
  }

  pw.Widget _infoBox({required String title, required List<String> lines}) {
    final visible = lines.map((line) => line.trim()).toList();
    // On retire les lignes vides en fin de bloc mais on garde les séparateurs
    // internes, qui aèrent le bloc "Entreprise".
    while (visible.isNotEmpty && visible.last.isEmpty) {
      visible.removeLast();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: paleBlue,
        border: pw.Border.all(color: lineGrey),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: brandDark,
            ),
          ),
          pw.SizedBox(height: 6),
          for (final line in visible)
            line.isEmpty
                ? pw.SizedBox(height: 6)
                : pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 1.5),
                    child: pw.Text(
                      line,
                      style: const pw.TextStyle(fontSize: 9.5),
                    ),
                  ),
        ],
      ),
    );
  }

  String _scheduleLine(Report report) {
    if (report.startTime.isEmpty && report.endTime.isEmpty) return '';
    if (report.endTime.isEmpty) return 'À partir de ${report.startTime}';
    if (report.startTime.isEmpty) return "Jusqu'à ${report.endTime}";
    return '${report.startTime} - ${report.endTime}';
  }

  // --- Sections de texte ----------------------------------------------------

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: brandDark,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(width: 60, height: 2, color: brandLight),
        ],
      ),
    );
  }

  pw.Widget _paragraph(String text) => pw.Paragraph(
        text: text,
        style: const pw.TextStyle(fontSize: 10, lineSpacing: 2.5),
        margin: const pw.EdgeInsets.only(bottom: 6),
      );

  /// Renvoie une section complète, ou rien du tout si le contenu est vide :
  /// un rapport ne doit pas afficher de titre orphelin.
  List<pw.Widget> _textSection(String title, String content) {
    if (content.trim().isEmpty) return const <pw.Widget>[];
    return [
      _sectionTitle(title),
      _paragraph(content.trim()),
      pw.SizedBox(height: 14),
    ];
  }

  String _observationsText(Report report) {
    final parts = <String>[
      if (report.observations.trim().isNotEmpty) report.observations.trim(),
      if (report.accessConstraints.trim().isNotEmpty)
        "Contrainte d'accès : ${report.accessConstraints.trim()}",
    ];
    return parts.join('\n\n');
  }

  List<pw.Widget> _findingsAndActions(Report report) {
    if (report.occupant.trim().isEmpty &&
        report.findings.trim().isEmpty &&
        report.findingTags.isEmpty &&
        report.actions.isEmpty) {
      return const <pw.Widget>[];
    }

    return [
      _sectionTitle('Constats et Actions'),
      if (report.occupant.trim().isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            'Occupant : ${report.occupant.trim()}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      if (report.findingTags.isNotEmpty || report.findings.trim().isNotEmpty)
        _label('Constat :'),
      if (report.findingTags.isNotEmpty) ...[
        pw.SizedBox(height: 4),
        for (final tag in report.findingTags) _bullet(tag),
        pw.SizedBox(height: 4),
      ],
      if (report.findings.trim().isNotEmpty) _paragraph(report.findings.trim()),
      if (report.actions.isNotEmpty) ...[
        pw.SizedBox(height: 4),
        _label('Actions :'),
        pw.SizedBox(height: 4),
        for (final action in report.actions) _bullet(action),
      ],
      pw.SizedBox(height: 14),
    ];
  }

  pw.Widget _label(String text) => pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          color: brandDark,
        ),
      );

  pw.Widget _bullet(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4, left: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 4,
              height: 4,
              margin: const pw.EdgeInsets.only(top: 4, right: 7),
              decoration: pw.BoxDecoration(
                color: brandDark,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                text,
                style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
              ),
            ),
          ],
        ),
      );

  // --- Photographies --------------------------------------------------------

  /// Les photos sont posées deux par ligne. Chaque ligne est un enfant
  /// distinct du MultiPage pour que la coupure entre deux pages tombe
  /// toujours entre deux lignes, jamais au milieu d'une image.
  List<pw.Widget> _photoSection(
    Report report,
    Map<String, pw.MemoryImage> images,
  ) {
    final printable =
        report.photos.where((photo) => images.containsKey(photo.id)).toList();
    if (printable.isEmpty) return const <pw.Widget>[];

    // On respecte l'ordre logique avant / pendant / après.
    final ordered = <PhotoItem>[
      ...printable.where((p) => p.stage == PhotoStage.avant),
      ...printable.where((p) => p.stage == PhotoStage.pendant),
      ...printable.where((p) => p.stage == PhotoStage.apres),
      ...printable.where((p) => p.stage == PhotoStage.autre),
    ];

    final rows = <pw.Widget>[];
    for (var i = 0; i < ordered.length; i += 2) {
      final left = ordered[i];
      final right = i + 1 < ordered.length ? ordered[i + 1] : null;
      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _photoCard(left, images[left.id]!)),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: right == null
                    ? pw.SizedBox()
                    : _photoCard(right, images[right.id]!),
              ),
            ],
          ),
        ),
      );
    }

    return [
      _sectionTitle("Photographies de l'intervention"),
      pw.SizedBox(height: 4),
      ...rows,
      pw.SizedBox(height: 8),
    ];
  }

  pw.Widget _photoCard(PhotoItem photo, pw.MemoryImage image) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 165,
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: lineGrey),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 3,
            verticalRadius: 3,
            child: pw.Image(image, fit: pw.BoxFit.cover),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (photo.stage != PhotoStage.autre)
              pw.Container(
                margin: const pw.EdgeInsets.only(right: 6),
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: pw.BoxDecoration(
                  color: brandDark,
                  borderRadius: pw.BorderRadius.circular(2),
                ),
                child: pw.Text(
                  photo.stage.label.toUpperCase(),
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.white),
                ),
              ),
            pw.Expanded(
              child: pw.Text(
                photo.caption,
                style: pw.TextStyle(fontSize: 8.5, color: textGrey),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Conclusions ----------------------------------------------------------

  List<pw.Widget> _conclusionSection(Report report) {
    if (report.conclusions.trim().isEmpty &&
        report.remainingPoints.trim().isEmpty) {
      return const <pw.Widget>[];
    }

    return [
      _sectionTitle('Conclusions'),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(
          color: report.status == ReportStatus.termine ? brandDark : brandLight,
          borderRadius: pw.BorderRadius.circular(3),
        ),
        child: pw.Text(
          report.status.label,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: report.status == ReportStatus.termine
                ? PdfColors.white
                : brandDark,
          ),
        ),
      ),
      pw.SizedBox(height: 10),
      if (report.conclusions.trim().isNotEmpty) ...[
        _label('Conclusions :'),
        _paragraph(report.conclusions.trim()),
      ],
      if (report.remainingPoints.trim().isNotEmpty) ...[
        pw.SizedBox(height: 6),
        _label('Points restants :'),
        _paragraph(report.remainingPoints.trim()),
      ],
      pw.SizedBox(height: 14),
    ];
  }

  // --- Récapitulatif d'intervention ----------------------------------------

  List<pw.Widget> _interventionRecap(Report report) {
    final rows = <List<String>>[
      [
        "Date d'intervention :",
        [
          _dayFormat.format(report.interventionDate),
          if (_scheduleLine(report).isNotEmpty) _scheduleLine(report),
        ].join('   '),
      ],
      if (report.interventionLabel.trim().isNotEmpty)
        ['Action :', report.interventionLabel.trim()],
      if (report.documentsToTransmit.trim().isNotEmpty)
        ['À transmettre :', report.documentsToTransmit.trim()],
    ];

    return [
      _sectionTitle('Intervention'),
      pw.Table(
        columnWidths: const {
          0: pw.FixedColumnWidth(120),
          1: pw.FlexColumnWidth(),
        },
        border: pw.TableBorder.all(color: lineGrey),
        children: [
          for (final row in rows)
            pw.TableRow(
              children: [
                pw.Container(
                  color: paleBlue,
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    row[0],
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      color: brandDark,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    row[1],
                    style: const pw.TextStyle(fontSize: 9.5),
                  ),
                ),
              ],
            ),
        ],
      ),
      pw.SizedBox(height: 18),
    ];
  }

  // --- Évaluation et signatures --------------------------------------------

  List<pw.Widget> _evaluationSection({
    required Report report,
    required Company company,
    pw.MemoryImage? clientSignature,
    pw.MemoryImage? technicianSignature,
  }) {
    return [
      _sectionTitle('Évaluation du client'),
      if (report.clientEvaluation.trim().isNotEmpty)
        _paragraph(report.clientEvaluation.trim())
      else
        pw.Container(
          height: 40,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: lineGrey)),
        ),
      pw.SizedBox(height: 18),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _signatureBox(
              title: "Signature de l'intervenant",
              caption: [
                report.technicianName,
                company.name,
                'Le : ${_dayFormat.format(report.interventionDate)}',
              ].where((line) => line.trim().isNotEmpty).join('\n'),
              signature: technicianSignature,
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: _signatureBox(
              title: 'Signature du client',
              caption: report.clientName,
              signature: clientSignature,
            ),
          ),
        ],
      ),
    ];
  }

  pw.Widget _signatureBox({
    required String title,
    required String caption,
    pw.MemoryImage? signature,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: brandDark,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Container(
          height: 70,
          width: double.infinity,
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: lineGrey)),
          child: signature == null
              ? pw.SizedBox()
              : pw.Image(signature, fit: pw.BoxFit.contain),
        ),
        pw.SizedBox(height: 5),
        pw.Text(caption, style: pw.TextStyle(fontSize: 8.5, color: textGrey)),
      ],
    );
  }

  pw.Widget _legalNotice(Report report, Company company) {
    final name = company.name.isEmpty ? "l'entreprise" : company.name;
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: lineGrey)),
      ),
      child: pw.Text(
        "Ce document est un rapport d'intervention établi par $name à la suite "
        "de l'intervention réalisée le ${_dayFormat.format(report.interventionDate)}. "
        "Toute nouvelle prestation fera l'objet d'un nouvel ordre de service et "
        "d'un nouveau dossier.",
        style: pw.TextStyle(
          fontSize: 7.5,
          color: textGrey,
          fontStyle: pw.FontStyle.italic,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }
}
