import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/report.dart';
import '../state/reports_provider.dart';
import '../state/settings_provider.dart';
import '../theme.dart';
import 'steps/step_conclusion.dart';
import 'steps/step_findings.dart';
import 'steps/step_materials.dart';
import 'steps/step_observations.dart';
import 'steps/step_photos.dart';
import 'steps/step_signature.dart';
import 'steps/step_site.dart';

/// Assistant de saisie d'un rapport.
///
/// Le rapport est découpé en sept étapes courtes plutôt qu'en un formulaire
/// unique : sur un chantier, on répond à quelques questions à la fois, souvent
/// avec une main occupée. Chaque frappe est écrite dans le brouillon, et le
/// brouillon est enregistré à chaque changement d'étape.
class ReportWizardScreen extends StatefulWidget {
  const ReportWizardScreen({
    super.key,
    required this.report,
    this.isNew = false,
    this.initialStep = 0,
  });

  final Report report;
  final bool isNew;
  final int initialStep;

  @override
  State<ReportWizardScreen> createState() => _ReportWizardScreenState();
}

class _ReportWizardScreenState extends State<ReportWizardScreen> {
  late final Report _draft = widget.report.clone();
  late final PageController _pageController =
      PageController(initialPage: widget.initialStep);

  late int _index = widget.initialStep;
  bool _dirty = false;
  bool _savedAtLeastOnce = false;

  static const List<_StepInfo> _steps = [
    _StepInfo(
      title: 'Le chantier',
      subtitle: 'Chez qui intervenez-vous, et pour quoi ?',
    ),
    _StepInfo(
      title: 'Observations',
      subtitle: "Ce que vous avez constaté en arrivant.",
    ),
    _StepInfo(
      title: 'Matériel',
      subtitle: 'Ce que vous avez mis en œuvre.',
    ),
    _StepInfo(
      title: 'Constats et actions',
      subtitle: 'Le problème et ce que vous avez fait.',
    ),
    _StepInfo(
      title: 'Photos',
      subtitle: 'Avant, pendant, après.',
    ),
    _StepInfo(
      title: 'Conclusion',
      subtitle: "Où en est l'intervention ?",
    ),
    _StepInfo(
      title: 'Validation',
      subtitle: 'Évaluation du client et signatures.',
    ),
  ];

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

    // Le numéro de rapport est attribué dès que le nom du client est connu,
    // pour qu'il apparaisse sur le PDF sans saisie supplémentaire.
    if (_draft.reportNumber.trim().isEmpty &&
        _draft.clientName.trim().isNotEmpty) {
      _draft.reportNumber = reports.generateReportNumber(_draft, settings);
    }
    if (_draft.status == ReportStatus.brouillon &&
        (_draft.findings.trim().isNotEmpty || _draft.findingTags.isNotEmpty)) {
      _draft.status = ReportStatus.enCours;
    }

    await reports.save(_draft);
    _savedAtLeastOnce = true;
    _dirty = false;
  }

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= _steps.length) return;
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

  /// Quitter l'assistant : on ne perd jamais une saisie sans le demander.
  Future<void> _handleBack() async {
    final hasContent = _draft.clientName.trim().isNotEmpty ||
        _draft.findings.trim().isNotEmpty ||
        _draft.photos.isNotEmpty ||
        _draft.observations.trim().isNotEmpty;

    if (!_dirty && !hasContent && !_savedAtLeastOnce) {
      Navigator.of(context).pop();
      return;
    }

    if (!_dirty && _savedAtLeastOnce) {
      Navigator.of(context).pop(_draft);
      return;
    }

    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quitter le rapport ?'),
        content: const Text(
          'Vous pouvez enregistrer ce rapport comme brouillon et le terminer '
          'plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ExitChoice.continueEditing),
            child: const Text('Continuer'),
          ),
          if (widget.isNew && !_savedAtLeastOnce)
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_ExitChoice.discard),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Abandonner'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(_ExitChoice.save),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (!mounted || choice == null || choice == _ExitChoice.continueEditing) {
      return;
    }

    if (choice == _ExitChoice.save) {
      await _persist();
      if (!mounted) return;
      Navigator.of(context).pop(_draft);
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _steps.length - 1;

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
          title: Text(widget.isNew ? 'Nouveau rapport' : 'Modifier le rapport'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_index + 1) / _steps.length,
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
            _page(0, SiteStep(draft: _draft, onChanged: _markDirty)),
            _page(1, ObservationsStep(draft: _draft, onChanged: _markDirty)),
            _page(2, MaterialsStep(draft: _draft, onChanged: _markDirty)),
            _page(3, FindingsStep(draft: _draft, onChanged: _markDirty)),
            _page(4, PhotosStep(draft: _draft, onChanged: _markDirty)),
            _page(5, ConclusionStep(draft: _draft, onChanged: _markDirty)),
            _page(6, SignatureStep(draft: _draft, onChanged: _markDirty)),
          ],
        ),
        bottomNavigationBar: _bottomBar(isLast),
      ),
    );
  }

  Widget _page(int index, Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeaderFor(index: index, steps: _steps),
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

class _StepHeaderFor extends StatelessWidget {
  const _StepHeaderFor({required this.index, required this.steps});

  final int index;
  final List<_StepInfo> steps;

  @override
  Widget build(BuildContext context) {
    final step = steps[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Étape ${index + 1} sur ${steps.length}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.brandLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.subtitle,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7785)),
          ),
        ],
      ),
    );
  }
}

class _StepInfo {
  const _StepInfo({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

enum _ExitChoice { continueEditing, save, discard }
