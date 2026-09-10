import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/company.dart';
import '../models/enums.dart';
import '../models/photo_item.dart';
import '../models/report.dart';
import 'storage_service.dart';

/// Un PDF généré : son contenu, son nom de fichier et l'endroit où il a été
/// enregistré.
class SavedPdf {
  const SavedPdf({
    required this.path,
    required this.fileName,
    required this.bytes,
  });

  final String path;
  final String fileName;
  final Uint8List bytes;
}

/// Génère le PDF du rapport d'intervention.
///
/// La mise en page reprend section par section le modèle Word de référence :
/// page de garde, blocs d'identification, observations, matériel, constats et
/// actions, photographies, conclusions, points restants, récapitulatif et
/// évaluation du client. Chaque page porte le logo et les coordonnées de
/// l'entreprise en en-tête, ses mentions légales et la pagination en pied.
class PdfService {
  PdfService(this._storage);

  final StorageService _storage;

  static const PdfColor brandDark = PdfColor.fromInt(0xFF104C7E);
  static const PdfColor brandLight = PdfColor.fromInt(0xFF8FB8E8);
  static const PdfColor paleBlue = PdfColor.fromInt(0xFFEAF2FB);
  static const PdfColor lineGrey = PdfColor.fromInt(0xFFD5DEE8);
  static const PdfColor textGrey = PdfColor.fromInt(0xFF5A6773);

  static final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');

  /// Polices du document, chargées une fois pour toutes.
  ///
  /// Les polices intégrées au format PDF (Helvetica et consorts) ne couvrent
  /// pas tout ce qu'un rapport en français contient : le « œ » de
  /// « Matériel(s) mis en œuvre » et le tiret cadratin de l'en-tête en sont
  /// absents et seraient tout simplement omis à l'impression. Roboto est
  /// embarquée dans l'application pour que le PDF s'imprime à l'identique
  /// partout, y compris hors ligne sur un chantier.
  Future<pw.ThemeData> get _theme async => _themeFuture ??= _loadTheme();
  Future<pw.ThemeData>? _themeFuture;

  Future<pw.ThemeData> _loadTheme() async => pw.ThemeData.withFont(
        base: await _font(regularFontAsset),
        bold: await _font('assets/fonts/Roboto-Bold.ttf'),
        italic: await _font('assets/fonts/Roboto-Italic.ttf'),
      );

  /// La police du corps du rapport.
  static const String regularFontAsset = 'assets/fonts/Roboto-Regular.ttf';

  /// Logo utilisé tant qu'aucun n'a été choisi dans les réglages.
  static const String defaultLogoAsset = 'assets/images/logo.png';

  Future<pw.Font> _font(String asset) async =>
      pw.Font.ttf(await rootBundle.load(asset));

  Future<Uint8List> buildReportPdf({
    required Report report,
    required Company company,
  }) async {
    final logo = await _logo(company);
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
      theme: await _theme,
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
  /// l'application.
  ///
  /// Renvoie le PDF et son emplacement : l'écran qui l'a demandé doit pouvoir
  /// l'imprimer et l'envoyer dans la foulée sans avoir à le relire.
  Future<SavedPdf> saveReportPdf({
    required Report report,
    required Company company,
  }) async {
    final bytes = await buildReportPdf(report: report, company: company);
    final fileName = fileNameFor(report);
    final path = await _storage.writePdf(fileName, bytes);
    return SavedPdf(path: path, fileName: fileName, bytes: bytes);
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

  /// Le logo choisi dans les réglages, sinon celui livré avec l'application.
  Future<pw.MemoryImage?> _logo(Company company) async {
    final chosen = await _image(company.logoPath);
    if (chosen != null) return chosen;
    final asset = await rootBundle.load(defaultLogoAsset);
    return pw.MemoryImage(asset.buffer.asUint8List());
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
                    style: const pw.TextStyle(
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
                    style: const pw.TextStyle(
                      fontSize: 18,
                      color: brandDark,
                      letterSpacing: 0.6,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    _dateLine(report),
                    style: const pw.TextStyle(fontSize: 14, color: textGrey),
                  ),
                  pw.Spacer(),
                  if (company.name.isNotEmpty)
                    pw.Text(
                      company.name.toUpperCase(),
                      style: const pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: brandDark,
                      ),
                    ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    company.contactLine,
                    style: const pw.TextStyle(fontSize: 9.5, color: textGrey),
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
      // Marge basse un peu plus haute : le pied de page porte les
      // mentions légales sur une ou deux lignes, plus la pagination.
      margin: const pw.EdgeInsets.fromLTRB(45, 40, 45, 68),
      header: (context) => _pageHeader(company, logo),
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

  /// En-tête de chaque page : le logo à gauche, les coordonnées de
  /// l'entreprise à droite, comme sur le modèle papier.
  pw.Widget _pageHeader(Company company, pw.MemoryImage? logo) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: brandLight, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logo != null)
            pw.Container(
              height: 46,
              width: 90,
              alignment: pw.Alignment.centerLeft,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            )
          else
            pw.SizedBox(width: 90),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (company.displayName.isNotEmpty)
                pw.Text(
                  company.displayName,
                  style: const pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: brandDark,
                  ),
                ),
              for (final line in company.contactLines)
                pw.Text(
                  line,
                  style: const pw.TextStyle(fontSize: 8, color: textGrey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Pied de page : les mentions légales de l'entreprise et la pagination.
  ///
  /// Les mentions sont centrées sur toute la largeur et la pagination passe
  /// en dessous : mises côte à côte, une raison sociale un peu longue passait
  /// à la ligne et le numéro de page se retrouvait au milieu du texte.
  pw.Widget _pageFooter(pw.Context context, Company company) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: lineGrey)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            company.legalLine,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 6.5, color: textGrey),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7.5, color: textGrey),
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
                report.technicians.length > 1
                    ? 'Intervenants : ${report.techniciansLine}'
                    : 'Intervenant : ${report.techniciansLine}',
                for (final technician in report.technicians)
                  if (technician.phone.trim().isNotEmpty)
                    report.technicians.length > 1
                        ? '${technician.name} — ${technician.phone}'
                        : 'Tél. : ${technician.phone}',
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
                report.isMultiDay
                    ? 'Intervention ${_dateLine(report).toLowerCase()}'
                    : 'Intervention du ${_dayFormat.format(report.interventionDate)}',
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
            style: const pw.TextStyle(
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

  /// "Le 12/03/2026" ou "Du 12/03/2026 au 14/03/2026".
  String _dateLine(Report report) {
    if (!report.isMultiDay) {
      return 'Le ${_dayFormat.format(report.interventionDate)}';
    }
    return 'Du ${_dayFormat.format(report.interventionDate)} '
        'au ${_dayFormat.format(report.interventionEndDate!)}';
  }

  /// Les mêmes dates, sans article, pour un tableau ou un libellé.
  String _dateRange(Report report) {
    if (!report.isMultiDay) return _dayFormat.format(report.interventionDate);
    return '${_dayFormat.format(report.interventionDate)} '
        '— ${_dayFormat.format(report.interventionEndDate!)}';
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
            style: const pw.TextStyle(
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

  /// Regroupe des éléments pour que la coupure entre deux pages ne tombe
  /// jamais entre eux.
  ///
  /// Sert à ne pas laisser un titre de section seul en bas d'une page, son
  /// contenu commençant sur la suivante. À n'utiliser que sur des blocs dont
  /// la hauteur est bornée : un bloc insécable plus haut qu'une page ne
  /// pourrait être posé nulle part.
  pw.Widget _keepTogether(List<pw.Widget> children) => pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: children,
        ),
      );

  /// Au-delà de cette longueur, un paragraphe remplit de toute façon le bas de
  /// la page et se poursuit sur la suivante : son titre n'y reste pas seul, et
  /// le rendre insécable ferait un bloc trop haut pour tenir sur une page.
  static const int _keepWithTitleLimit = 900;

  /// Renvoie une section complète, ou rien du tout si le contenu est vide :
  /// un rapport ne doit pas afficher de titre orphelin.
  List<pw.Widget> _textSection(String title, String content) {
    final text = content.trim();
    if (text.isEmpty) return const <pw.Widget>[];

    return [
      if (text.length <= _keepWithTitleLimit)
        _keepTogether([_sectionTitle(title), _paragraph(text)])
      else ...[
        _sectionTitle(title),
        _paragraph(text),
      ],
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

    final hasConstat =
        report.findingTags.isNotEmpty || report.findings.trim().isNotEmpty;

    return [
      // Le titre reste avec l'occupant et l'intitulé « Constat : », qui
      // n'auraient aucun sens séparés de lui.
      _keepTogether([
        _sectionTitle('Constats et Actions'),
        if (report.occupant.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              'Occupant : ${report.occupant.trim()}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        if (hasConstat) _label('Constat :'),
        if (report.findingTags.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          _bullet(report.findingTags.first),
        ],
      ]),
      if (report.findingTags.isNotEmpty) ...[
        for (final tag in report.findingTags.skip(1)) _bullet(tag),
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
        style: const pw.TextStyle(
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
              decoration: const pw.BoxDecoration(
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

    // Le titre part avec la première ligne de photos : un titre seul en bas
    // d'une page, les photos sur la suivante, se remarque tout de suite.
    return [
      _keepTogether([
        _sectionTitle("Photographies de l'intervention"),
        pw.SizedBox(height: 4),
        rows.first,
      ]),
      ...rows.skip(1),
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
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.white,
                  ),
                ),
              ),
            pw.Expanded(
              child: pw.Text(
                photo.caption,
                style: const pw.TextStyle(fontSize: 8.5, color: textGrey),
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

    final conclusions = report.conclusions.trim();
    final remaining = report.remainingPoints.trim();

    final header = <pw.Widget>[
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
    ];

    final conclusionBlock = <pw.Widget>[
      if (conclusions.isNotEmpty) ...[
        _label('Conclusions :'),
        _paragraph(conclusions),
      ],
    ];

    return [
      // Le statut de l'intervention et le début de la conclusion partent avec
      // le titre : c'est le passage que le client lit en premier.
      if (conclusions.length <= _keepWithTitleLimit)
        _keepTogether([...header, ...conclusionBlock])
      else ...[
        _keepTogether(header),
        ...conclusionBlock,
      ],
      if (remaining.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        if (remaining.length <= _keepWithTitleLimit)
          _keepTogether([_label('Points restants :'), _paragraph(remaining)])
        else ...[
          _label('Points restants :'),
          _paragraph(remaining),
        ],
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
          _dateRange(report),
          if (_scheduleLine(report).isNotEmpty) _scheduleLine(report),
        ].join('   '),
      ],
      if (report.interventionLabel.trim().isNotEmpty)
        ['Action :', report.interventionLabel.trim()],
      if (report.documentsToTransmit.trim().isNotEmpty)
        ['À transmettre :', report.documentsToTransmit.trim()],
    ];

    // Le tableau récapitulatif fait au plus trois lignes : il tient avec son
    // titre sur n'importe quelle page.
    return [
      _keepTogether([
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
                      style: const pw.TextStyle(
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
      ]),
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
    final evaluation = report.clientEvaluation.trim();

    final signatures = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _stampBox(
            report: report,
            company: company,
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
    );

    final header = <pw.Widget>[
      _sectionTitle('Évaluation du client'),
      if (evaluation.isNotEmpty)
        _paragraph(evaluation)
      else
        pw.Container(
          height: 40,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: lineGrey)),
        ),
      pw.SizedBox(height: 18),
    ];

    // Le titre reste avec l'évaluation, et les cadres — cachet et signature
    // du client — forment un bloc à part qui ne se coupe pas en deux. Les
    // garder tous ensemble laissait une demi-page vide dès que l'ensemble ne
    // tenait plus dans le bas de la page.
    return [
      if (evaluation.length <= _keepWithTitleLimit)
        _keepTogether(header)
      else
        ...header,
      pw.Inseparable(child: signatures),
    ];
  }

  /// Le cachet de l'entreprise, signé par l'intervenant.
  ///
  /// C'est ce que porte le rapport papier en fin de document : le tampon de
  /// la société, la signature tracée par-dessus, puis le nom de qui est
  /// intervenu et la date. Le tampon est composé à partir de la fiche
  /// entreprise, il ne peut donc pas dater par rapport à l'en-tête.
  pw.Widget _stampBox({
    required Report report,
    required Company company,
    pw.MemoryImage? signature,
  }) {
    final lines = company.stampLines;
    final date = report.interventionEndDate ?? report.interventionDate;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          report.technicians.length > 1
              ? 'Cachet et signatures des intervenants'
              : "Cachet et signature de l'intervenant",
          style: const pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: brandDark,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Container(
          height: 90,
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: lineGrey)),
          child: pw.Stack(
            alignment: pw.Alignment.center,
            children: [
              pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < lines.length; i++)
                    pw.Text(
                      lines[i],
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: i == 0 ? 8.5 : 7,
                        fontWeight:
                            i == 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
                        lineSpacing: 1.5,
                      ),
                    ),
                ],
              ),
              // La signature se pose par-dessus le cachet, comme sur papier.
              if (signature != null)
                pw.Positioned.fill(
                  child: pw.Image(signature, fit: pw.BoxFit.contain),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          [
            report.techniciansLine,
            'Le : ${_dayFormat.format(date)}',
          ].where((line) => line.trim().isNotEmpty).join('\n'),
          style: const pw.TextStyle(fontSize: 8.5, color: textGrey),
        ),
      ],
    );
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
          style: const pw.TextStyle(
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
        pw.Text(caption, style: const pw.TextStyle(fontSize: 8.5, color: textGrey)),
      ],
    );
  }

  pw.Widget _legalNotice(Report report, Company company) {
    final name = company.name.isEmpty ? "l'entreprise" : company.name;
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: lineGrey)),
      ),
      child: pw.Text(
        "Ce document est un rapport d'intervention établi par $name à la suite "
        "de l'intervention réalisée ${_dateLine(report).toLowerCase()}. "
        "Toute nouvelle prestation fera l'objet d'un nouvel ordre de service et "
        "d'un nouveau dossier.",
        style: const pw.TextStyle(
          fontSize: 7.5,
          color: textGrey,
          fontStyle: pw.FontStyle.italic,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }
}
