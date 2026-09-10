import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/report.dart';
import '../state/reports_provider.dart';
import '../state/settings_provider.dart';
import '../theme.dart';
import '../widgets/report_card.dart';
import 'report_detail_screen.dart';
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

  Future<void> _createReport() async {
    final settings = context.read<SettingsProvider>().settings;
    final reports = context.read<ReportsProvider>();
    final draft = reports.createDraft(settings);

    final saved = await Navigator.of(context).push<Report>(
      MaterialPageRoute(
        builder: (_) => ReportWizardScreen(report: draft, isNew: true),
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
