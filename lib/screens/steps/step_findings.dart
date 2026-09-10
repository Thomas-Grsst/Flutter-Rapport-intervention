import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/report.dart';
import '../../state/settings_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/preset_chips.dart';
import '../../widgets/question_block.dart';

/// Étape 4 — le cœur du rapport : ce qui a été constaté et ce qui a été fait.
///
/// Les constats et les actions se cochent dans une liste. C'est ce qui rend
/// la saisie tenable sur un chantier : l'intervenant coche, et le rapport se
/// rédige tout seul en puces.
class FindingsStep extends StatefulWidget {
  const FindingsStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final Report draft;
  final VoidCallback onChanged;

  @override
  State<FindingsStep> createState() => _FindingsStepState();
}

class _FindingsStepState extends State<FindingsStep> {
  Report get _draft => widget.draft;

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: 'Qui occupait les lieux ?',
          optional: true,
          child: AppTextField(
            initialValue: _draft.occupant,
            hint: 'Ex. : M. BLANC',
            prefixIcon: Icons.people_outline,
            onChanged: (value) => _update(() => _draft.occupant = value),
          ),
        ),
        QuestionBlock(
          question: 'Qu\'avez-vous constaté ?',
          hint: 'Cochez les constats. Ils apparaîtront en puces dans le '
              'rapport.',
          child: PresetChips(
            options: settings.settings.findingPresets,
            selected: _draft.findingTags,
            dialogTitle: 'Ajouter un constat',
            onChanged: (values) => _update(() => _draft.findingTags = values),
            onCustomAdded: (value) =>
                settings.rememberPreset(PresetList.findings, value),
          ),
        ),
        QuestionBlock(
          question: 'Souhaitez-vous préciser le constat ?',
          hint: 'Quelques phrases si la situation demande une explication.',
          optional: true,
          child: AppTextField(
            initialValue: _draft.findings,
            maxLines: 5,
            hint: "Ex. : L'intervention a porté sur l'entretien d'une fosse de "
                'relevage. Un débouchage de la canalisation des WC a également '
                'été réalisé.',
            onChanged: (value) => _update(() => _draft.findings = value),
          ),
        ),
        QuestionBlock(
          question: 'Qu\'avez-vous réalisé ?',
          hint: 'Chaque action cochée devient une puce du rapport. Utilisez '
              '« Autre… » pour détailler (métrage, méthode…).',
          child: PresetChips(
            options: settings.settings.actionPresets,
            selected: _draft.actions,
            dialogTitle: 'Ajouter une action',
            onChanged: (values) => _update(() => _draft.actions = values),
            onCustomAdded: (value) =>
                settings.rememberPreset(PresetList.actions, value),
          ),
        ),
        if (_draft.actions.isNotEmpty) _actionsPreview(),
      ],
    );
  }

  Widget _actionsPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dans le rapport',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF104C7E),
            ),
          ),
          const SizedBox(height: 8),
          for (final action in _draft.actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      action,
                      style: const TextStyle(fontSize: 14, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
