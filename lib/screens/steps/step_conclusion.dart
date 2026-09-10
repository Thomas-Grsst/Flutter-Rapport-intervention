import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/report.dart';
import '../../theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/question_block.dart';

/// Étape 6 — statut, conclusions, points restants et horaires.
class ConclusionStep extends StatefulWidget {
  const ConclusionStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final Report draft;
  final VoidCallback onChanged;

  @override
  State<ConclusionStep> createState() => _ConclusionStepState();
}

class _ConclusionStepState extends State<ConclusionStep> {
  int _conclusionTick = 0;

  Report get _draft => widget.draft;

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = _parseTime(isStart ? _draft.startTime : _draft.endTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? TimeOfDay(hour: isStart ? 8 : 12, minute: 0),
      helpText: isStart ? 'Heure de début' : 'Heure de fin',
    );
    if (picked == null) return;

    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    _update(() {
      if (isStart) {
        _draft.startTime = formatted;
      } else {
        _draft.endTime = formatted;
      }
    });
  }

  static TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Compose une conclusion à partir de ce qui a déjà été saisi.
  ///
  /// C'est une proposition, pas une génération automatique imposée : le texte
  /// est déposé dans le champ et reste entièrement modifiable.
  void _suggestConclusion() {
    final sentences = <String>[];

    if (_draft.interventionType.trim().isNotEmpty) {
      sentences.add(
        "L'intervention a porté sur : "
        '${_lowerFirst(_draft.interventionType.trim())}.',
      );
    }
    if (_draft.findingTags.isNotEmpty) {
      sentences.add('Constats relevés : ${_enumerate(_draft.findingTags)}.');
    }
    if (_draft.actions.isNotEmpty) {
      sentences.add(
        'Les actions suivantes ont été réalisées : '
        '${_enumerate(_draft.actions)}.',
      );
    }
    if (_draft.status == ReportStatus.termine &&
        _draft.remainingPoints.trim().isEmpty) {
      sentences.add("La conformité de l'intervention est attestée.");
    }

    if (sentences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Renseignez d\'abord le type d\'intervention, les constats ou les '
            'actions.',
          ),
        ),
      );
      return;
    }

    _update(() {
      _draft.conclusions = sentences.join(' ');
      _conclusionTick++;
    });
  }

  static String _lowerFirst(String value) =>
      value.isEmpty ? value : value[0].toLowerCase() + value.substring(1);

  /// "a, b et c"
  static String _enumerate(List<String> items) {
    final cleaned =
        items.map((item) => _lowerFirst(item.trim())).where((i) => i.isNotEmpty);
    if (cleaned.length <= 1) return cleaned.join();
    final list = cleaned.toList();
    return '${list.sublist(0, list.length - 1).join(', ')} et ${list.last}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: "Où en est l'intervention ?",
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in const [
                ReportStatus.enCours,
                ReportStatus.aSuivre,
                ReportStatus.termine,
              ])
                ChoiceChip(
                  label: Text(status.label),
                  selected: _draft.status == status,
                  labelStyle: TextStyle(
                    fontSize: 13.5,
                    fontWeight: _draft.status == status
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: _draft.status == status
                        ? AppColors.brandDark
                        : const Color(0xFF35414D),
                  ),
                  onSelected: (_) => _update(() => _draft.status = status),
                ),
            ],
          ),
        ),
        QuestionBlock(
          question: 'Quelle conclusion pour le client ?',
          hint: 'Le paragraphe de synthèse qui apparaît en fin de rapport.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _suggestConclusion,
                  icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: const Text('Proposer une conclusion'),
                ),
              ),
              const SizedBox(height: 4),
              AppTextField(
                key: ValueKey('conclusion-$_conclusionTick'),
                initialValue: _draft.conclusions,
                maxLines: 7,
                hint: 'Synthèse de ce qui a été fait et de son résultat.',
                onChanged: (value) => _update(() => _draft.conclusions = value),
              ),
            ],
          ),
        ),
        QuestionBlock(
          question: 'Reste-t-il quelque chose à faire ou à surveiller ?',
          hint: 'Ce que le client doit savoir après votre départ.',
          optional: true,
          child: AppTextField(
            initialValue: _draft.remainingPoints,
            maxLines: 4,
            hint: 'Ex. : sous réserve de la surveillance de la suspicion de '
                'contre-pente signalée.',
            onChanged: (value) =>
                _update(() => _draft.remainingPoints = value),
          ),
        ),
        QuestionBlock(
          question: 'Sur quels horaires êtes-vous intervenu ?',
          optional: true,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(isStart: true),
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(
                    _draft.startTime.isEmpty ? 'Début' : _draft.startTime,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(isStart: false),
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(
                    _draft.endTime.isEmpty ? 'Fin' : _draft.endTime,
                  ),
                ),
              ),
            ],
          ),
        ),
        QuestionBlock(
          question: 'Comment résumer cette intervention en une ligne ?',
          hint: 'Apparaît dans le tableau récapitulatif du rapport.',
          optional: true,
          child: AppTextField(
            initialValue: _draft.interventionLabel,
            hint: 'Ex. : Intervention assainissement',
            onChanged: (value) =>
                _update(() => _draft.interventionLabel = value),
          ),
        ),
        QuestionBlock(
          question: 'Que devez-vous transmettre au client ?',
          optional: true,
          child: AppTextField(
            initialValue: _draft.documentsToTransmit,
            hint: "Ex. : Rapport d'intervention",
            onChanged: (value) =>
                _update(() => _draft.documentsToTransmit = value),
          ),
        ),
      ],
    );
  }
}
