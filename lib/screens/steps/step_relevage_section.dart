import 'package:flutter/material.dart';

import '../../models/relevage_template.dart';
import '../../models/report.dart';
import '../../theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/question_block.dart';
import '../../widgets/section_photos.dart';

/// Une section du gabarit : ses états à relever, puis ses photos.
///
/// La section est la même pour tous les rapports : l'intervenant n'a jamais à
/// se demander quoi remplir, seulement à constater.
class RelevageSectionStep extends StatefulWidget {
  const RelevageSectionStep({
    super.key,
    required this.draft,
    required this.section,
    required this.onChanged,
  });

  final Report draft;
  final RelevageSection section;
  final VoidCallback onChanged;

  @override
  State<RelevageSectionStep> createState() => _RelevageSectionStepState();
}

class _RelevageSectionStepState extends State<RelevageSectionStep> {
  /// Incrémenté quand une réponse rapide remplit un champ, pour que celui-ci
  /// se reconstruise avec la nouvelle valeur sans perdre le focus à chaque
  /// frappe — ce que ferait une clé fondée sur le texte saisi.
  final Map<String, int> _ticks = <String, int>{};

  Report get _draft => widget.draft;
  RelevageSection get _section => widget.section;

  void _setValue(String key, String value) {
    setState(() => _draft.setChecklistValue(key, value));
    widget.onChanged();
  }

  void _applyQuickAnswer(String key, String value) {
    setState(() {
      _draft.setChecklistValue(key, value);
      _ticks[key] = (_ticks[key] ?? 0) + 1;
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final group = _draft.photoGroupFor(_section.id, title: _section.title);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final field in _section.fields) _fieldBlock(field),
        if (_section.hasFreeText)
          QuestionBlock(
            question: 'Quelque chose à signaler ?',
            hint: 'Ce paragraphe s\'imprime tel quel sous « Observations ».',
            optional: true,
            child: AppTextField(
              initialValue: _draft.checklistValue(_section.id),
              maxLines: 6,
              hint: 'Ex. : prévoir le remplacement du clapet avant l\'hiver.',
              onChanged: (value) => _setValue(_section.id, value),
            ),
          ),
        if (_section.hasPhotos)
          QuestionBlock(
            question: 'Photos de ${_section.title.toLowerCase()}',
            optional: true,
            child: SectionPhotos(
              group: group,
              label: _section.title,
              onChanged: widget.onChanged,
            ),
          ),
      ],
    );
  }

  Widget _fieldBlock(RelevageField field) {
    final key = _section.keyOf(field);

    return QuestionBlock(
      question: '${field.label} ?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
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
                  onSelected: (_) => _applyQuickAnswer(key, answer),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AppTextField(
            key: ValueKey('$key-${_ticks[key] ?? 0}'),
            initialValue: _draft.checklistValue(key),
            maxLines: 2,
            hint: 'Ou décrivez ce que vous avez constaté',
            onChanged: (value) => _setValue(key, value),
          ),
        ],
      ),
    );
  }
}
