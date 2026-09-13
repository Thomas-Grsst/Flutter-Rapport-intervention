import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/company.dart';
import '../models/enums.dart';
import '../models/filtre_compact_template.dart';
import '../models/photo_item.dart';
import '../models/report.dart';
import 'pdf_photo_rows.dart';
import 'pdf_style.dart';

/// Met en page le rapport d'entretien de filtre compact.
///
/// Le document suit le modèle papier point par point — identification,
/// synthèse de tête, les douze sections dans l'ordre, la synthèse finale puis
/// les signatures — dans la charte des autres rapports de l'entreprise.
class FiltreCompactPdfLayout {
  const FiltreCompactPdfLayout();

  static final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');

  /// Le contenu du rapport, prêt à être posé dans un MultiPage.
  List<pw.Widget> build({
    required Report report,
    required Company company,
    required Map<String, pw.MemoryImage> photoImages,
    pw.MemoryImage? clientSignature,
    pw.MemoryImage? technicianSignature,
  }) {
    return <pw.Widget>[
      ..._identificationBlocks(report, company),
      ..._summary(report),
      ..._purpose(),
      for (var i = 0; i < filtreSections.length; i++)
        ..._section(filtreSections[i], i + 1, report, photoImages),
      ..._closingSummary(report),
      ..._validation(report, company, clientSignature, technicianSignature),
      pw.SizedBox(height: 10),
      _legalNotice(report, company),
    ];
  }

  // --- Blocs d'identification -----------------------------------------------

  List<pw.Widget> _identificationBlocks(Report report, Company company) {
    return [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: PdfStyle.infoBox(
              title: 'Client',
              lines: [
                report.clientName,
                report.clientAddressLine,
                report.clientCityLine,
                if (report.clientPhone.trim().isNotEmpty)
                  'Tél. : ${report.clientPhone.trim()}',
                if (report.clientEmail.trim().isNotEmpty)
                  'E-mail : ${report.clientEmail.trim()}',
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: PdfStyle.infoBox(
              title: 'Installation',
              lines: [
                if (report.equipmentBrand.trim().isNotEmpty)
                  'Marque : ${report.equipmentBrand.trim()}',
                if (report.equipmentType.trim().isNotEmpty)
                  'Modèle : ${report.equipmentType.trim()}',
                if (report.reference.trim().isNotEmpty)
                  'Référence : ${report.reference.trim()}',
                if (report.serialNumber.trim().isNotEmpty)
                  'N° de série : ${report.serialNumber.trim()}',
                if (report.lastMaintenanceDate != null)
                  'Dernier entretien : '
                      '${_dayFormat.format(report.lastMaintenanceDate!)}',
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
            child: PdfStyle.infoBox(
              title: company.name.isEmpty ? 'Entreprise' : company.name,
              lines: [
                if (company.addressLine.isNotEmpty)
                  'Siège social : ${company.addressLine}',
                company.cityLine,
                if (company.phone.isNotEmpty) 'Tél. : ${company.phone}',
                if (company.email.isNotEmpty) 'E-mail : ${company.email}',
                '',
                report.technicians.length > 1
                    ? 'Techniciens : ${report.techniciansLine}'
                    : 'Technicien : ${report.techniciansLine}',
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: PdfStyle.infoBox(
              title: 'Référence',
              lines: [
                if (report.reportNumber.trim().isNotEmpty)
                  'N° rapport : ${report.reportNumber}',
                'Entretien du ${_dayFormat.format(report.interventionDate)}',
                if (report.checklistValue(filtreNextVisitKey).isNotEmpty)
                  'Prochaine visite : '
                      '${report.checklistValue(filtreNextVisitKey)}',
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 22),
    ];
  }

  // --- Synthèse de tête -----------------------------------------------------

  /// L'état de l'installation en trois lignes, avant le détail.
  ///
  /// C'est ce que le client regarde en premier, et souvent la seule chose
  /// qu'il retient : elle est posée en évidence, dans un cadre.
  List<pw.Widget> _summary(Report report) {
    final answered = <List<String>>[
      for (final field in filtreSummaryFields)
        if (report.checklistValue(filtreSummaryKey(field)).isNotEmpty)
          [field.label, report.checklistValue(filtreSummaryKey(field))],
    ];
    if (answered.isEmpty) return const <pw.Widget>[];

    return [
      PdfStyle.keepTogether([
        PdfStyle.sectionTitle("État de l'installation"),
        // Pleine largeur : un cadre se resserre sinon sur sa ligne la plus
        // longue, et le résumé se retrouvait tassé dans un coin de la page.
        pw.Container(
          width: double.infinity,
          child: PdfStyle.infoBox(
            title: 'En résumé',
            lines: [for (final line in answered) '${line[0]} : ${line[1]}'],
          ),
        ),
      ]),
      pw.SizedBox(height: 14),
    ];
  }

  List<pw.Widget> _purpose() {
    return [
      PdfStyle.keepTogether([
        PdfStyle.sectionTitle('Objet du rapport'),
        PdfStyle.paragraph(
          "Le présent rapport décrit les opérations d'entretien, de nettoyage "
          "et de vérification réalisées sur l'installation d'assainissement "
          'non collectif. Les photographies avant et après intervention ainsi '
          'que les observations du technicien permettent d\'assurer la '
          'traçabilité de la visite.',
        ),
      ]),
      pw.SizedBox(height: 14),
    ];
  }

  // --- Sections -------------------------------------------------------------

  List<pw.Widget> _section(
    FiltreSection section,
    int number,
    Report report,
    Map<String, pw.MemoryImage> images,
  ) {
    final stateBefore =
        section.hasStateBefore ? report.checklistValue(section.stateKey) : '';

    final answered = <List<String>>[
      for (final field in section.fields)
        if (report.checklistValue(section.keyOf(field)).isNotEmpty ||
            report.checklistValue(section.observationsKeyOf(field)).isNotEmpty)
          [
            field.label,
            report.checklistValue(section.keyOf(field)),
            report.checklistValue(section.observationsKeyOf(field)),
          ],
    ];

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
    if (stateBefore.isEmpty &&
        answered.isEmpty &&
        avant.isEmpty &&
        apres.isEmpty) {
      return const <pw.Widget>[];
    }

    final rows = const PhotoRows().build(avant, apres, images);

    return <pw.Widget>[
      PdfStyle.keepTogether([
        PdfStyle.sectionTitle('$number. ${section.title}'),
        if (stateBefore.isNotEmpty) ...[
          PdfStyle.label('État avant intervention'),
          pw.SizedBox(height: 3),
          PdfStyle.paragraph(stateBefore),
        ],
        for (final line in answered) ...[
          PdfStyle.bullet(line[0], value: line[1]),
          if (line[2].isNotEmpty) _observations(line[2]),
        ],
        if (rows.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          rows.first,
        ],
      ]),
      ...rows.skip(1),
      pw.SizedBox(height: 14),
    ];
  }

  /// Les observations d'un point, en retrait sous sa réponse.
  pw.Widget _observations(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 15, bottom: 5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 9,
          color: PdfStyle.textGrey,
          lineSpacing: 1.5,
        ),
      ),
    );
  }

  // --- Synthèse finale ------------------------------------------------------

  List<pw.Widget> _closingSummary(Report report) {
    final blocks = <List<String>>[
      ['Travaux réalisés', report.checklistValue(filtreWorkKey)],
      ['Anomalies constatées', report.checklistValue(filtreAnomaliesKey)],
      [
        'Préconisations et travaux à prévoir',
        report.checklistValue(filtreAdviceKey),
      ],
    ].where((block) => block[1].isNotEmpty).toList();

    if (blocks.isEmpty) return const <pw.Widget>[];

    return [
      PdfStyle.keepTogether([
        PdfStyle.sectionTitle("Synthèse de l'intervention"),
        PdfStyle.label(blocks.first[0]),
        pw.SizedBox(height: 3),
        PdfStyle.paragraph(blocks.first[1]),
      ]),
      for (final block in blocks.skip(1))
        PdfStyle.keepTogether([
          PdfStyle.label(block[0]),
          pw.SizedBox(height: 3),
          PdfStyle.paragraph(block[1]),
        ]),
      pw.SizedBox(height: 14),
    ];
  }

  // --- Validation -----------------------------------------------------------

  List<pw.Widget> _validation(
    Report report,
    Company company,
    pw.MemoryImage? clientSignature,
    pw.MemoryImage? technicianSignature,
  ) {
    final comment = report.clientEvaluation.trim();
    final date = _dayFormat.format(report.interventionDate);

    return [
      PdfStyle.keepTogether([
        PdfStyle.sectionTitle('Validation'),
        if (comment.isNotEmpty) ...[
          PdfStyle.label('Commentaire du client'),
          pw.SizedBox(height: 3),
          PdfStyle.paragraph(comment),
          pw.SizedBox(height: 6),
        ],
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: PdfStyle.signatureBox(
                title: company.name.isEmpty
                    ? 'Technicien'
                    : 'Technicien ${company.name}',
                caption: [
                  if (report.techniciansLine.isNotEmpty)
                    report.techniciansLine,
                  'Le $date',
                ].join(' — '),
                signature: technicianSignature,
              ),
            ),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: PdfStyle.signatureBox(
                title: 'Client ou représentant',
                caption: [
                  if (report.clientName.trim().isNotEmpty)
                    report.clientName.trim(),
                  'Le $date',
                ].join(' — '),
                signature: clientSignature,
              ),
            ),
          ],
        ),
      ]),
    ];
  }

  // --- Mention de bas de document -------------------------------------------

  pw.Widget _legalNotice(Report report, Company company) {
    final name = company.name.isEmpty ? "l'entreprise" : company.name;
    return PdfStyle.legalNotice(
      "Ce document est un rapport d'entretien de filtre compact établi par "
      '$name à la suite de la visite réalisée le '
      '${_dayFormat.format(report.interventionDate)}. '
      "Toute nouvelle prestation fera l'objet d'un nouvel ordre de service et "
      "d'un nouveau dossier.",
    );
  }
}
