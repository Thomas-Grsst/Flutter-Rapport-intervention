import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/company.dart';
import '../models/enums.dart';
import '../models/photo_item.dart';
import '../models/relevage_template.dart';
import '../models/report.dart';
import 'pdf_photo_rows.dart';
import 'pdf_style.dart';

/// Met en page le rapport d'entretien de poste de relevage.
///
/// Le document reprend la charte du rapport d'intervention — même page de
/// garde, même en-tête, mêmes cadres d'identification, mêmes titres de section
/// et mêmes cadres photo : les deux rapports sortent de la même entreprise et
/// se lisent l'un après l'autre. Seul le contenu diffère, et il ne varie
/// jamais : les huit sections du gabarit, dans l'ordre, avec leurs états
/// relevés et leurs photos.
class RelevagePdfLayout {
  const RelevagePdfLayout();

  static final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');

  /// Le contenu du rapport, prêt à être posé dans un MultiPage.
  List<pw.Widget> build({
    required Report report,
    required Company company,
    required Map<String, pw.MemoryImage> photoImages,
  }) {
    return <pw.Widget>[
      ..._identificationBlocks(report, company),
      for (final section in relevageSections)
        ..._section(section, report, photoImages),
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
              title: 'Poste de relevage',
              lines: [
                if (report.equipmentBrand.trim().isNotEmpty)
                  'Marque : ${report.equipmentBrand.trim()}',
                if (report.equipmentType.trim().isNotEmpty)
                  'Type : ${report.equipmentType.trim()}',
                if (report.contractDate != null)
                  'Contrat de maintenance du '
                      '${_dayFormat.format(report.contractDate!)}',
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
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: PdfStyle.infoBox(
              title: 'Référence',
              lines: [
                if (report.reportNumber.trim().isNotEmpty)
                  'N° rapport : ${report.reportNumber}',
                'Entretien du '
                    '${_dayFormat.format(report.interventionDate)}',
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 22),
    ];
  }

  // --- Sections -------------------------------------------------------------

  /// Une section : son titre, ses états relevés, puis ses photos.
  ///
  /// Le titre part avec ce qui le suit — un titre seul en bas d'une page se
  /// remarque tout de suite. Les rangées de photos suivantes sont des enfants
  /// distincts, pour que la coupure entre deux pages tombe entre deux rangées
  /// et jamais au milieu d'une image.
  List<pw.Widget> _section(
    RelevageSection section,
    Report report,
    Map<String, pw.MemoryImage> images,
  ) {
    final states = <List<String>>[
      for (final field in section.fields)
        if (report.checklistValue(section.keyOf(field)).isNotEmpty)
          [field.label, report.checklistValue(section.keyOf(field))],
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
    if (states.isEmpty && freeText.isEmpty && avant.isEmpty && apres.isEmpty) {
      return const <pw.Widget>[];
    }

    final rows = const PhotoRows().build(avant, apres, images);

    return <pw.Widget>[
      PdfStyle.keepTogether([
        PdfStyle.sectionTitle(section.title),
        for (final state in states) PdfStyle.bullet(state[0], value: state[1]),
        if (freeText.isNotEmpty) ...[
          if (states.isNotEmpty) pw.SizedBox(height: 4),
          PdfStyle.paragraph(freeText),
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

  // --- Mention de bas de document -------------------------------------------

  pw.Widget _legalNotice(Report report, Company company) {
    final name = company.name.isEmpty ? "l'entreprise" : company.name;
    return PdfStyle.legalNotice(
      "Ce document est un rapport d'entretien de poste de relevage établi par "
      '$name à la suite de la visite réalisée le '
      '${_dayFormat.format(report.interventionDate)}. '
      "Toute nouvelle prestation fera l'objet d'un nouvel ordre de service et "
      "d'un nouveau dossier.",
    );
  }
}
