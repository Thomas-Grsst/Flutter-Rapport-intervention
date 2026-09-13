import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/filtre_compact_template.dart';
import '../../models/report.dart';
import '../../theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/question_block.dart';
import '../../widgets/section_photos.dart';

/// Une section du gabarit du filtre compact : l'état avant l'intervention, le
/// geste effectué, ses observations, puis les photos.
///
/// La section est la même pour tous les rapports : l'intervenant n'a jamais à
/// se demander quoi remplir, seulement à constater.
class FiltreSectionStep extends StatefulWidget {
  const FiltreSectionStep({
    super.key,
    required this.draft,
    required this.section,
    required this.onChanged,
  });

  final Report draft;
  final FiltreSection section;
  final VoidCallback onChanged;

  @override
  State<FiltreSectionStep> createState() => _FiltreSectionStepState();
}

class _FiltreSectionStepState extends State<FiltreSectionStep> {
  Report get _draft => widget.draft;
  FiltreSection get _section => widget.section;

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
        if (_section.hasStateBefore)
          QuestionBlock(
            question: "Dans quel état l'avez-vous trouvé ?",
            optional: true,
            child: AppTextField(
              initialValue: _draft.checklistValue(_section.stateKey),
              maxLines: 3,
              hint: 'Ex. : préfiltre colmaté, dépôt important.',
              onChanged: (value) => _setValue(_section.stateKey, value),
            ),
          ),
        for (final field in _section.fields) _fieldBlock(field),
        if (_section.photos != FiltrePhotos.aucune)
          QuestionBlock(
            question: 'Photos',
            optional: true,
            child: SectionPhotos(
              group: _draft.photoGroupFor(_section.id, title: _section.title),
              label: _section.title,
              stages: _section.photos == FiltrePhotos.unique
                  ? const <PhotoStage, String>{
                      PhotoStage.avant: 'Photographie',
                    }
                  : const <PhotoStage, String>{
                      PhotoStage.avant: 'Avant',
                      PhotoStage.apres: 'Après',
                    },
              onChanged: widget.onChanged,
            ),
          ),
      ],
    );
  }

  Widget _fieldBlock(FiltreField field) {
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
                  onSelected: (_) => _pickAnswer(key, answer),
                ),
            ],
          ),
          if (field.hasObservations) ...[
            const SizedBox(height: 10),
            AppTextField(
              initialValue:
                  _draft.checklistValue(_section.observationsKeyOf(field)),
              maxLines: 2,
              hint: 'Observations',
              onChanged: (value) =>
                  _setValue(_section.observationsKeyOf(field), value),
            ),
          ],
        ],
      ),
    );
  }
}
