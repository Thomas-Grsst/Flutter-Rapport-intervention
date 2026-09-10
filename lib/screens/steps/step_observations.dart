import 'package:flutter/material.dart';

import '../../models/report.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/question_block.dart';

/// Étape 2 — observations générales et contraintes d'accès.
class ObservationsStep extends StatelessWidget {
  const ObservationsStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final Report draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: "Dans quel cadre l'intervention a-t-elle eu lieu ?",
          hint: 'Le contexte : intervention programmée, appel en urgence, '
              'demande du syndic…',
          child: AppTextField(
            initialValue: draft.observations,
            maxLines: 6,
            hint: 'Ex. : Intervention programmée le jeudi matin pour le '
                "pompage et l'entretien du poste de relevage.",
            onChanged: (value) {
              draft.observations = value;
              onChanged();
            },
          ),
        ),
        QuestionBlock(
          question: "Y a-t-il eu une contrainte d'accès ?",
          hint: 'Distance, absence d\'accès véhicule, portail, hauteur… '
              'Ces précisions justifient le temps passé.',
          optional: true,
          child: AppTextField(
            initialValue: draft.accessConstraints,
            maxLines: 4,
            hint: 'Ex. : prévoir 50 à 70 mètres de tuyaux, le poste étant en '
                'partie basse du terrain, sans accès véhicule direct.',
            onChanged: (value) {
              draft.accessConstraints = value;
              onChanged();
            },
          ),
        ),
      ],
    );
  }
}
