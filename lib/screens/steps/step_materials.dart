import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/report.dart';
import '../../state/settings_provider.dart';
import '../../widgets/preset_chips.dart';
import '../../widgets/question_block.dart';

/// Étape 3 — matériel mis en œuvre, coché dans une liste plutôt que rédigé.
class MaterialsStep extends StatefulWidget {
  const MaterialsStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final Report draft;
  final VoidCallback onChanged;

  @override
  State<MaterialsStep> createState() => _MaterialsStepState();
}

class _MaterialsStepState extends State<MaterialsStep> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: 'Quel matériel avez-vous utilisé ?',
          hint: 'Cochez ce qui a servi. Le rapport en fera une phrase.',
          child: PresetChips(
            options: settings.settings.materialPresets,
            selected: widget.draft.materials,
            dialogTitle: 'Ajouter un matériel',
            onChanged: (values) {
              setState(() => widget.draft.materials = values);
              widget.onChanged();
            },
            onCustomAdded: (value) =>
                settings.rememberPreset(PresetList.materials, value),
          ),
        ),
        if (widget.draft.materials.isNotEmpty)
          _preview(widget.draft.materials.join(', ')),
      ],
    );
  }

  /// Montre à l'intervenant la phrase qui apparaîtra dans le PDF : il voit
  /// tout de suite le résultat de ses cases cochées.
  Widget _preview(String text) {
    return Container(
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
          const SizedBox(height: 6),
          Text(
            '$text.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}
