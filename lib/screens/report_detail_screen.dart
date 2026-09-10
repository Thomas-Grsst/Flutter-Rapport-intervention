import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/enums.dart';
import '../models/report.dart';
import '../services/pdf_service.dart';
import '../state/reports_provider.dart';
import '../state/settings_provider.dart';
import '../theme.dart';
import '../widgets/media_image.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';
import 'report_wizard_screen.dart';

/// Fiche complète d'un rapport, avec génération et envoi du PDF.
class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  bool _generating = false;

  Future<void> _edit(Report report) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReportWizardScreen(report: report)),
    );
  }

  Future<void> _delete(Report report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce rapport ?'),
        content: const Text(
          'Le rapport, ses photos et ses signatures seront définitivement '
          'supprimés du téléphone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await context.read<ReportsProvider>().delete(report);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _duplicate(Report report) async {
    final reports = context.read<ReportsProvider>();
    final copy = reports.duplicate(report);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportWizardScreen(report: copy, isNew: true),
      ),
    );
  }

  /// Génère le PDF puis propose de le prévisualiser, l'imprimer ou l'envoyer.
  Future<void> _generatePdf(Report report) async {
    final pdfService = context.read<PdfService>();
    final company = context.read<SettingsProvider>().company;
    final reports = context.read<ReportsProvider>();

    setState(() => _generating = true);
    try {
      final pdf = await pdfService.saveReportPdf(
        report: report,
        company: company,
      );
      report.lastPdfPath = pdf.path;
      await reports.save(report);

      if (!mounted) return;
      await _showPdfActions(report, pdf);
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la génération du PDF : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _showPdfActions(Report report, SavedPdf pdf) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rapport généré',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Aperçu / Imprimer'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await Printing.layoutPdf(
                  onLayout: (_) async => pdf.bytes,
                  name: pdf.fileName,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.send_outlined),
              title: const Text('Envoyer au client'),
              subtitle: const Text('E-mail, SMS, WhatsApp…'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                // On partage les octets plutôt qu'un chemin : dans un
                // navigateur, le PDF n'existe pas comme fichier sur le disque.
                await Share.shareXFiles(
                  [
                    XFile.fromData(
                      pdf.bytes,
                      name: pdf.fileName,
                      mimeType: 'application/pdf',
                    ),
                  ],
                  subject: "Rapport d'intervention "
                      '${report.reportNumber} — ${report.displayTitle}',
                  text: 'Bonjour,\n\nVeuillez trouver ci-joint le rapport de '
                      "l'intervention du "
                      '${_dateFormat.format(report.interventionDate)}.\n\n'
                      'Cordialement,',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportsProvider>().byId(widget.reportId);

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rapport')),
        body: const Center(child: Text('Ce rapport a été supprimé.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(report.displayClient),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'duplicate') _duplicate(report);
              if (value == 'delete') _delete(report);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'duplicate', child: Text('Dupliquer')),
              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _summaryCard(report),
          const SizedBox(height: 12),
          _addressCard(report),
          if (report.observations.trim().isNotEmpty ||
              report.accessConstraints.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: 'Observations',
              icon: Icons.visibility_outlined,
              children: [
                InfoParagraph(text: report.observations),
                if (report.accessConstraints.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  InfoLine(
                    label: "Contrainte d'accès",
                    value: report.accessConstraints,
                  ),
                ],
              ],
            ),
          ],
          if (report.materials.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: 'Matériel mis en œuvre',
              icon: Icons.build_outlined,
              children: [InfoParagraph(text: '${report.materials.join(', ')}.')],
            ),
          ],
          const SizedBox(height: 12),
          _findingsCard(report),
          if (report.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _photosCard(report),
          ],
          const SizedBox(height: 12),
          _conclusionCard(report),
          const SizedBox(height: 12),
          _signatureCard(report),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _edit(report),
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text('Modifier'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _generating ? null : () => _generatePdf(report),
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined, size: 20),
                label: Text(_generating ? 'Génération…' : 'Générer le PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(Report report) {
    return SectionCard(
      title: report.displayTitle,
      icon: Icons.assignment_outlined,
      trailing: StatusChip(status: report.status),
      children: [
        InfoLine(
          label: 'Date',
          value: _dateFormat.format(report.interventionDate),
        ),
        InfoLine(label: 'N° rapport', value: report.reportNumber),
        InfoLine(label: 'V/Réf', value: report.reference),
        InfoLine(
          label: report.technicians.length > 1 ? 'Intervenants' : 'Intervenant',
          value: report.techniciansLine,
        ),
        InfoLine(
          label: 'Horaires',
          value: [report.startTime, report.endTime]
              .where((time) => time.isNotEmpty)
              .join(' - '),
        ),
      ],
    );
  }

  Widget _addressCard(Report report) {
    return SectionCard(
      title: 'Client et lieu',
      icon: Icons.place_outlined,
      children: [
        InfoLine(label: 'Client', value: report.clientName),
        InfoLine(
          label: 'Adresse client',
          value: [report.clientAddressLine, report.clientCityLine]
              .where((line) => line.trim().isNotEmpty)
              .join('\n'),
        ),
        InfoLine(
          label: 'Intervention',
          value: [report.siteAddressLine, report.siteCityLine]
              .where((line) => line.trim().isNotEmpty)
              .join('\n'),
        ),
        InfoLine(label: 'Localisation', value: report.siteLocation),
        InfoLine(label: 'Contact', value: report.siteContact),
      ],
    );
  }

  Widget _findingsCard(Report report) {
    return SectionCard(
      title: 'Constats et actions',
      icon: Icons.report_problem_outlined,
      children: [
        InfoLine(label: 'Occupant', value: report.occupant),
        if (report.findingTags.isNotEmpty) ...[
          const _MiniLabel('Constat'),
          for (final tag in report.findingTags) _BulletLine(text: tag),
          const SizedBox(height: 8),
        ],
        InfoParagraph(
          text: report.findings,
          emptyLabel: report.findingTags.isEmpty && report.actions.isEmpty
              ? 'Aucun constat renseigné.'
              : null,
        ),
        if (report.actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _MiniLabel('Actions'),
          for (final action in report.actions) _BulletLine(text: action),
        ],
      ],
    );
  }

  Widget _photosCard(Report report) {
    return SectionCard(
      title: 'Photographies (${report.photos.length})',
      icon: Icons.photo_camera_outlined,
      children: [
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: report.photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final photo = report.photos[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: MediaImage(path: photo.filePath),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _photoBreakdown(report),
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7785)),
        ),
      ],
    );
  }

  String _photoBreakdown(Report report) {
    final parts = <String>[];
    for (final stage in PhotoStage.values) {
      final count = report.photosOfStage(stage).length;
      if (count > 0) parts.add('${stage.label} : $count');
    }
    return parts.join('  •  ');
  }

  Widget _conclusionCard(Report report) {
    return SectionCard(
      title: 'Conclusions',
      icon: Icons.flag_outlined,
      children: [
        InfoParagraph(
          text: report.conclusions,
          emptyLabel: 'Aucune conclusion renseignée.',
        ),
        if (report.remainingPoints.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          const _MiniLabel('Points restants'),
          InfoParagraph(text: report.remainingPoints),
        ],
      ],
    );
  }

  Widget _signatureCard(Report report) {
    final client = report.clientSignaturePath;
    final technician = report.technicianSignaturePath;

    return SectionCard(
      title: 'Validation',
      icon: Icons.draw_outlined,
      children: [
        InfoParagraph(
          text: report.clientEvaluation,
          emptyLabel: 'Aucune évaluation du client.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _signaturePreview('Intervenant', technician)),
            const SizedBox(width: 12),
            Expanded(child: _signaturePreview('Client', client)),
          ],
        ),
      ],
    );
  }

  Widget _signaturePreview(String label, String? path) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7785)),
        ),
        const SizedBox(height: 4),
        Container(
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD5DEE8)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: MediaImage(
              path: path,
              fit: BoxFit.contain,
              placeholder: const Center(
                child: Text(
                  'Non signé',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8A97A3)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Color(0xFF6B7785),
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
