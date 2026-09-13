import 'package:flutter/material.dart';

import '../../models/filtre_compact_template.dart';
import '../../models/report.dart';
import '../../theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/question_block.dart';

/// Dernière étape du rapport de filtre compact : ce que le client retient.
///
/// La synthèse s'imprime en première page, sous les identifiants — mais elle
/// se remplit en dernier, une fois l'installation vue de bout en bout.
class FiltreSyntheseStep extends StatefulWidget {
  const FiltreSyntheseStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final Report draft;
  final VoidCallback onChanged;

  @override
  State<FiltreSyntheseStep> createState() => _FiltreSyntheseStepState();
}

class _FiltreSyntheseStepState extends State<FiltreSyntheseStep> {
  Report get _draft => widget.draft;

  void _setValue(String key, String value) {
    setState(() => _draft.setChecklistValue(key, value));
    widget.onChanged();
  }

  /// Coche une réponse rapide.
  ///
  /// Le clavier se ferme d'abord : le champ libre à côté rend la main, et
  /// peut donc afficher la réponse cochée — tant qu'il a le focus, il est
  /// maître de son contenu.
  void _pickAnswer(String key, String value) {
    FocusScope.of(context).unfocus();
    _setValue(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final field in filtreSummaryFields) _summaryBlock(field),
        QuestionBlock(
          question: 'Travaux réalisés',
          hint: 'Ce qui a été fait pendant la visite.',
          child: AppTextField(
            initialValue: _draft.checklistValue(filtreWorkKey),
            maxLines: 4,
            hint: 'Ex. : pompage de la fosse, nettoyage du préfiltre et '
                'scarification du média filtrant.',
            onChanged: (value) => _setValue(filtreWorkKey, value),
          ),
        ),
        QuestionBlock(
          question: 'Anomalies constatées',
          optional: true,
          child: AppTextField(
            initialValue: _draft.checklistValue(filtreAnomaliesKey),
            maxLines: 4,
            hint: 'Ce qui ne va pas, et depuis quand si vous le savez.',
            onChanged: (value) => _setValue(filtreAnomaliesKey, value),
          ),
        ),
        QuestionBlock(
          question: 'Préconisations et travaux à prévoir',
          optional: true,
          child: AppTextField(
            initialValue: _draft.checklistValue(filtreAdviceKey),
            maxLines: 4,
            hint: 'Ce que le client doit faire, et dans quel délai.',
            onChanged: (value) => _setValue(filtreAdviceKey, value),
          ),
        ),
        QuestionBlock(
          question: 'Prochaine visite conseillée',
          optional: true,
          child: AppTextField(
            initialValue: _draft.checklistValue(filtreNextVisitKey),
            hint: 'Ex. : dans 12 mois, ou 09/2027',
            onChanged: (value) => _setValue(filtreNextVisitKey, value),
          ),
        ),
      ],
    );
  }

  Widget _summaryBlock(FiltreField field) {
    final key = filtreSummaryKey(field);

    return QuestionBlock(
      question: '${field.label} ?',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final answer in field.answers.choices)
            ChoiceChip(
              label: Text(answer),
              selected: _draft.checklistValue(key) == answer,
              labelStyle: TextStyle(
                fontSize: 13.5,
                color: _draft.checklistValue(key) == answer
                    ? AppColors.brandDark
                    : const Color(0xFF35414D),
                fontWeight: _draft.checklistValue(key) == answer
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              onSelected: (_) => _pickAnswer(key, answer),
            ),
        ],
      ),
    );
  }
}
