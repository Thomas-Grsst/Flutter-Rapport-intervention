import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/relevage_template.dart';
import '../models/report.dart';
import '../state/reports_provider.dart';
import '../state/settings_provider.dart';
import '../theme.dart';
import 'steps/step_relevage_client.dart';
import 'steps/step_relevage_poste.dart';
import 'steps/step_relevage_section.dart';

/// Assistant de saisie d'un rapport d'entretien de poste de relevage.
///
/// Le rapport ne varie jamais : l'assistant suit donc exactement le gabarit,
/// une étape par section, dans l'ordre où l'intervenant fait le tour de
/// l'installation — l'environnement, la cuve, le clapet, les flotteurs, les
/// pompes, le coffret, l'exutoire, puis ses observations.
class RelevageWizardScreen extends StatefulWidget {
  const RelevageWizardScreen({
    super.key,
    required this.report,
    this.isNew = false,
  });

  final Report report;
  final bool isNew;

  @override
  State<RelevageWizardScreen> createState() => _RelevageWizardScreenState();
}

class _RelevageWizardScreenState extends State<RelevageWizardScreen> {
  late final Report _draft = widget.report.clone();
  late final PageController _pageController = PageController();

  int _index = 0;
  bool _dirty = false;
  bool _savedAtLeastOnce = false;

  /// Les deux premières étapes — le client, puis le poste — précèdent les
  /// sections du gabarit.
  int get _stepCount => 2 + relevageSections.length;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _persist() async {
    final reports = context.read<ReportsProvider>();
    final settings = context.read<SettingsProvider>().settings;

    if (_draft.reportNumber.trim().isEmpty &&
        _draft.clientName.trim().isNotEmpty) {
      _draft.reportNumber = reports.generateReportNumber(_draft, settings);
    }
    if (_draft.status == ReportStatus.brouillon && _draft.checklist.isNotEmpty) {
      _draft.status = ReportStatus.enCours;
    }

    await reports.save(_draft);
    _savedAtLeastOnce = true;
    _dirty = false;
  }

  /// Enregistre sans quitter l'assistant.
  ///
  /// Le rapport est déjà enregistré à chaque changement d'étape, mais rien ne
  /// le disait : sur un chantier, on veut pouvoir ranger son téléphone au
  /// milieu d'une saisie en étant sûr de ne rien perdre.
  Future<void> _saveNow() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);

    await _persist();
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Rapport enregistré')),
    );
  }

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= _stepCount) return;
    FocusScope.of(context).unfocus();
    await _persist();
    if (!mounted) return;
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    FocusScope.of(context).unfocus();
    await _persist();
    if (!mounted) return;
    Navigator.of(context).pop(_draft);
  }

  Future<void> _handleBack() async {
    final hasContent = _draft.clientName.trim().isNotEmpty ||
        _draft.checklist.isNotEmpty ||
        _draft.photos.isNotEmpty;

    if (!_dirty && !hasContent && !_savedAtLeastOnce) {
      Navigator.of(context).pop();
      return;
    }
    if (!_dirty && _savedAtLeastOnce) {
      Navigator.of(context).pop(_draft);
      return;
    }

    final choice = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quitter le rapport ?'),
        content: const Text(
          'Vous pouvez enregistrer ce rapport comme brouillon et le terminer '
          'plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Continuer'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (!mounted || choice != true) return;
    await _persist();
    if (!mounted) return;
    Navigator.of(context).pop(_draft);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _stepCount - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
          title: Text(widget.isNew
              ? 'Entretien poste de relevage'
              : 'Modifier le rapport'),
          actions: [
            TextButton(
              onPressed: _saveNow,
              child: const Text(
                'Enregistrer',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_index + 1) / _stepCount,
              minHeight: 4,
              backgroundColor: AppColors.brandDark,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.brandLight),
            ),
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _page(
              step: 0,
              title: 'Le client',
              subtitle: 'À qui appartient le poste ?',
              child: RelevageClientStep(draft: _draft, onChanged: _markDirty),
            ),
            _page(
              step: 1,
              title: 'Le poste',
              subtitle: 'Le contrat, la marque et le modèle.',
              child: RelevagePosteStep(draft: _draft, onChanged: _markDirty),
            ),
            for (var i = 0; i < relevageSections.length; i++)
              _page(
                step: 2 + i,
                title: relevageSections[i].title,
                subtitle: _subtitleFor(relevageSections[i]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RelevageSectionStep(
                      draft: _draft,
                      section: relevageSections[i],
                      onChanged: _markDirty,
                    ),
                    // La dernière section porte le rappel de ce qui manque.
                    if (i == relevageSections.length - 1) ...[
                      const SizedBox(height: 8),
                      RelevageReadyBanner(report: _draft),
                    ],
                  ],
                ),
              ),
          ],
        ),
        bottomNavigationBar: _bottomBar(isLast),
      ),
    );
  }

  static String _subtitleFor(RelevageSection section) {
    if (section.hasFreeText) return 'Ce que le client doit savoir.';
    if (section.fields.isEmpty) return 'Quelques photos suffisent.';
    return "L'état relevé, puis les photos.";
  }

  Widget _page({
    required int step,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Étape ${step + 1} sur $_stepCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.brandLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF6B7785)),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _bottomBar(bool isLast) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          if (_index > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _goTo(_index - 1),
                child: const Text('Précédent'),
              ),
            ),
          if (_index > 0) const SizedBox(width: 12),
          Expanded(
            flex: _index > 0 ? 1 : 2,
            child: FilledButton(
              onPressed: isLast ? _finish : () => _goTo(_index + 1),
              child: Text(isLast ? 'Terminer' : 'Suivant'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rappel de ce qui manque, affiché sur la dernière étape.
class RelevageReadyBanner extends StatelessWidget {
  const RelevageReadyBanner({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final missing = report.missingSections;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            missing.isEmpty ? const Color(0xFFE4F3EC) : const Color(0xFFFDF1DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                missing.isEmpty
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                size: 20,
                color: missing.isEmpty ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  missing.isEmpty
                      ? 'Le rapport est complet'
                      : 'Il reste ${missing.length} information(s) à compléter',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color:
                        missing.isEmpty ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            missing.isEmpty
                ? 'Appuyez sur « Terminer » pour l\'enregistrer, puis générez '
                    'le PDF depuis la fiche du rapport.'
                : '${missing.join(' • ')}.\nVous pouvez tout de même '
                    'enregistrer et compléter plus tard.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
