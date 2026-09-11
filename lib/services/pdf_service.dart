import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/company.dart';
import '../models/enums.dart';
import '../models/photo_group.dart';
import '../models/photo_item.dart';
import '../models/report.dart';
import 'pdf_style.dart';
import 'relevage_pdf.dart';
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

  static const PdfColor brandDark = PdfStyle.brandDark;
  static const PdfColor brandLight = PdfStyle.brandLight;
  static const PdfColor paleBlue = PdfStyle.paleBlue;
  static const PdfColor lineGrey = PdfStyle.lineGrey;
  static const PdfColor textGrey = PdfStyle.textGrey;

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
      title: '${report.kind.documentTitle} ${report.reportNumber}'.trim(),
      author: company.displayName,
      subject: report.displayTitle,
      theme: await _theme,
    );

    // Les deux modèles partagent la page de garde : seul le contenu change.
    doc.addPage(_coverPage(report: report, company: company, logo: logo));

    if (report.kind == ReportKind.posteRelevage) {
      doc.addPage(
        _relevagePages(
          report: report,
          company: company,
          logo: logo,
          photoImages: photoImages,
        ),
      );
      return doc.save();
    }

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

  /// Le rapport d'entretien de poste de relevage : le gabarit figé, posé dans
  /// les mêmes pages que le rapport d'intervention.
  pw.MultiPage _relevagePages({
    required Report report,
    required Company company,
    required Map<String, pw.MemoryImage> photoImages,
    pw.MemoryImage? logo,
  }) {
    const layout = RelevagePdfLayout();

    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      // Marge basse un peu plus haute : le pied de page porte les
      // mentions légales sur une ou deux lignes, plus la pagination.
      margin: const pw.EdgeInsets.fromLTRB(45, 40, 45, 68),
      header: (context) => _pageHeader(company, logo),
      footer: (context) => _pageFooter(context, company),
      build: (context) => layout.build(
        report: report,
        company: company,
        photoImages: photoImages,
      ),
    );
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

  /// Le logo choisi dans les réglages, s'il y en a un.
  ///
  /// L'application ne livre aucun logo : elle appartient à qui l'installe, et
  /// un logo d'emprunt sur ses rapports serait pire que pas de logo du tout.
  /// La mise en page se passe très bien du sien.
  Future<pw.MemoryImage?> _logo(Company company) => _image(company.logoPath);

  // --- Page de garde --------------------------------------------------------

  /// Page de garde du rapport, commune aux deux modèles.
  pw.Page _coverPage({
    required Report report,
    required Company company,
    pw.MemoryImage? logo,
  }) =>
      PdfStyle.coverPage(
        title: report.kind.documentTitle,
        subtitle: _coverSubtitle(report),
        dateLine: _dateLine(report),
        company: company,
        logo: logo,
      );

  /// L'objet du rapport, sous son titre.
  ///
  /// Pour un entretien, le titre dit déjà de quoi il s'agit : la ligne du
  /// dessous nomme donc le poste lui-même, ce qui distingue deux rapports
  /// d'un même client.
  String _coverSubtitle(Report report) {
    if (report.kind != ReportKind.posteRelevage) {
      return report.displayTitle.toUpperCase();
    }
    final poste = [report.equipmentBrand.trim(), report.equipmentType.trim()]
        .where((part) => part.isNotEmpty)
        .join(' ');
    return poste.isEmpty
        ? 'POSTE DE RELEVAGE'
        : 'POSTE DE RELEVAGE — ${poste.toUpperCase()}';
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

  pw.Widget _pageHeader(Company company, pw.MemoryImage? logo) =>
      PdfStyle.pageHeader(company, logo);

  pw.Widget _pageFooter(pw.Context context, Company company) =>
      PdfStyle.pageFooter(context, company);

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

  pw.Widget _infoBox({required String title, required List<String> lines}) =>
      PdfStyle.infoBox(title: title, lines: lines);

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

  pw.Widget _sectionTitle(String title) => PdfStyle.sectionTitle(title);

  pw.Widget _paragraph(String text) => PdfStyle.paragraph(text);

  pw.Widget _label(String text) => PdfStyle.label(text);

  pw.Widget _bullet(String text) => PdfStyle.bullet(text);

  pw.Widget _keepTogether(List<pw.Widget> children) =>
      PdfStyle.keepTogether(children);

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

  // --- Photographies --------------------------------------------------------

  /// Les photos sont imprimées lot par lot : une ligne par point de
  /// l'intervention, trois colonnes — avant, pendant, après. L'« après » d'un
  /// point tombe ainsi en face de son « avant », ce qui se lit d'un coup d'œil.
  ///
  /// Chaque lot est un enfant distinct du MultiPage, pour que la coupure
  /// entre deux pages tombe entre deux lots et jamais au milieu de l'un d'eux.
  List<pw.Widget> _photoSection(
    Report report,
    Map<String, pw.MemoryImage> images,
  ) {
    bool printable(PhotoItem photo) => images.containsKey(photo.id);

    final groups = report.photoGroups
        .where((group) => group.photos.any(printable))
        .toList();
    if (groups.isEmpty) return const <pw.Widget>[];

    final rows = <pw.Widget>[
      for (var i = 0; i < groups.length; i++)
        _photoGroupRow(
          group: groups[i],
          index: i,
          images: images,
          showLabel: groups.length > 1 || groups[i].label.trim().isNotEmpty,
        ),
    ];

    // Le titre part avec le premier lot : un titre seul en bas d'une page,
    // les photos sur la suivante, se remarque tout de suite.
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

  pw.Widget _photoGroupRow({
    required PhotoGroup group,
    required int index,
    required Map<String, pw.MemoryImage> images,
    required bool showLabel,
  }) {
    const stages = [PhotoStage.avant, PhotoStage.pendant, PhotoStage.apres];

    List<PhotoItem> ofColumn(PhotoStage stage) => group
        .inColumn(stage)
        .where((photo) => images.containsKey(photo.id))
        .toList();

    final label = group.label.trim();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (showLabel)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Text(
                label.isEmpty ? 'Lot ${index + 1}' : label,
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: brandDark,
                ),
              ),
            ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final stage in stages) ...[
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (final photo in ofColumn(stage))
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 6),
                          child: _photoCard(photo, images[photo.id]!),
                        ),
                    ],
                  ),
                ),
                if (stage != stages.last) pw.SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _photoCard(PhotoItem photo, pw.MemoryImage image) =>
      PdfStyle.photoCard(photo, image);

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
    return PdfStyle.legalNotice(
      "Ce document est un rapport d'intervention établi par $name à la suite "
      "de l'intervention réalisée ${_dateLine(report).toLowerCase()}. "
      'Toute nouvelle prestation fera l\'objet d\'un nouvel ordre de service '
      "et d'un nouveau dossier.",
    );
  }
}
