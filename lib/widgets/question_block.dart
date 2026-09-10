import 'package:flutter/material.dart';

import '../theme.dart';

/// Un bloc « question → réponse ».
///
/// L'assistant de saisie ne doit pas ressembler à un formulaire Word : chaque
/// champ est présenté comme une question courte posée à l'intervenant, avec
/// éventuellement une phrase d'aide en dessous.
class QuestionBlock extends StatelessWidget {
  const QuestionBlock({
    super.key,
    required this.question,
    required this.child,
    this.hint,
    this.optional = false,
  });

  final String question;
  final String? hint;
  final bool optional;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandDark,
                    height: 1.25,
                  ),
                ),
              ),
              if (optional)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 3),
                  child: Text(
                    'facultatif',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF8A97A3)),
                  ),
                ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7785)),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

