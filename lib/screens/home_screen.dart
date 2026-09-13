import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/report.dart';
import '../state/reports_provider.dart';
import '../state/settings_provider.dart';
import '../theme.dart';
import '../widgets/report_card.dart';
import 'report_detail_screen.dart';
import 'filtre_compact_wizard_screen.dart';
import 'relevage_wizard_screen.dart';
import 'report_wizard_screen.dart';
import 'settings_screen.dart';

/// Écran d'accueil : recherche, filtres et liste des rapports.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Demande d'abord quelle sorte de rapport : les deux ne se remplissent pas
  /// de la même façon, et l'assistant n'est pas le même.
  Future<void> _createReport() async {
    final kind = await showModalBottomSheet<ReportKind>(
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
                  'Quel rapport ?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.water_drop_outlined),
              title: Text(ReportKind.posteRelevage.label),
              subtitle: const Text('Contrôle complet, section par section'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ReportKind.posteRelevage),
            ),
            ListTile(
              leading: const Icon(Icons.filter_alt_outlined),
              title: Text(ReportKind.filtreCompact.label),
              subtitle: const Text('Fosse, préfiltre, média filtrant, pompe'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ReportKind.filtreCompact),
            ),
            ListTile(
              leading: const Icon(Icons.build_outlined),
              title: Text(ReportKind.intervention.label),
              subtitle: const Text('Débouchage, curage, dépannage ponctuel'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ReportKind.intervention),
            ),
          ],
        ),
      ),
    );

    if (kind == null || !mounted) return;

    final settings = context.read<SettingsProvider>().settings;
    final reports = context.read<ReportsProvider>();
    final draft = reports.createDraft(settings, kind: kind);

    final saved = await Navigator.of(context).push<Report>(
      MaterialPageRoute(
        builder: (_) => switch (kind) {
          ReportKind.posteRelevage =>
            RelevageWizardScreen(report: draft, isNew: true),
          ReportKind.filtreCompact =>
            FiltreCompactWizardScreen(report: draft, isNew: true),
          ReportKind.intervention =>
            ReportWizardScreen(report: draft, isNew: true),
        },
      ),
    );

    if (saved != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReportDetailScreen(reportId: saved.id),
        ),
      );
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportsProvider>();
    final visible = reports.visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes rapports"),
        actions: [
          IconButton(
            tooltip: 'Réglages',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createReport,
        backgroundColor: AppColors.brandDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau rapport'),
      ),
      body: Column(
        children: [
          _searchBar(reports),
          _filterBar(reports),
          _setupBanner(),
          Expanded(
            child: visible.isEmpty
                ? _emptyState(reports)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final report = visible[index];
                      return ReportCard(
                        report: report,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ReportDetailScreen(reportId: report.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Invitation à renseigner l'entreprise, tant qu'elle ne l'est pas.
  ///
  /// L'application est livrée vide : sans cette fiche, les rapports sortiraient
  /// sans en-tête, sans logo et sans mentions légales — et on ne s'en
  /// apercevrait qu'au moment d'envoyer le PDF au client.
  Widget _setupBanner() {
    final company = context.watch<SettingsProvider>().company;
    if (company.name.trim().isNotEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: const Color(0xFFFDF1DC),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _openSettings,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.business_outlined,
                    color: AppColors.warning, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Renseignez votre entreprise',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Nom, adresse, logo et mentions légales : ils '
                        'apparaîtront sur tous vos rapports.',
                        style: TextStyle(fontSize: 13, height: 1.35),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.warning),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar(ReportsProvider reports) {
    return Container(
      color: AppColors.brandDark,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: reports.setQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Client, adresse, n° de rapport…',
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: reports.query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    reports.setQuery('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }

  Widget _filterBar(ReportsProvider reports) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          for (final filter in ReportFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${filter.label} (${reports.countFor(filter)})'),
                selected: reports.filter == filter,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: reports.filter == filter
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: reports.filter == filter
                      ? AppColors.brandDark
                      : const Color(0xFF5A6773),
                ),
                onSelected: (_) => reports.setFilter(filter),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(ReportsProvider reports) {
    final isFiltered =
        reports.query.isNotEmpty || reports.filter != ReportFilter.tous;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered ? Icons.search_off : Icons.assignment_outlined,
              size: 56,
              color: AppColors.brandLight,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'Aucun rapport ne correspond'
                  : 'Aucun rapport pour le moment',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Essayez un autre nom de client ou changez de filtre.'
                  : 'Appuyez sur « Nouveau rapport » pour créer votre premier '
                      "rapport d'intervention.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7785)),
            ),
          ],
        ),
      ),
    );
  }
}
