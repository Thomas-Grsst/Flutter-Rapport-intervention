import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/report.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/question_block.dart';

/// Étape 2 du rapport de poste de relevage — le contrat de maintenance et le
/// matériel, qui forment le bandeau bleu en tête du rapport.
class RelevagePosteStep extends StatefulWidget {
  const RelevagePosteStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final Report draft;
  final VoidCallback onChanged;

  @override
  State<RelevagePosteStep> createState() => _RelevagePosteStepState();
}

class _RelevagePosteStepState extends State<RelevagePosteStep> {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  Report get _draft => widget.draft;

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  Future<void> _pickContractDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.contractDate ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Date du contrat de maintenance',
    );
    if (picked != null) _update(() => _draft.contractDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final date = _draft.contractDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: 'De quand date le contrat de maintenance ?',
          optional: true,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickContractDate,
                  icon: const Icon(Icons.description_outlined),
                  label: Text(
                    date == null
                        ? 'Choisir la date'
                        : 'Du ${_dateFormat.format(date)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                child: date == null
                    ? null
                    : IconButton(
                        tooltip: 'Retirer la date',
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () =>
                            _update(() => _draft.contractDate = null),
                      ),
              ),
            ],
          ),
        ),
        QuestionBlock(
          question: 'Quel est le poste de relevage ?',
          hint: 'La marque et le modèle, tels qu\'ils figurent sur la plaque.',
          child: Column(
            children: [
              AppTextField(
                initialValue: _draft.equipmentBrand,
                label: 'Marque',
                hint: 'Ex. : Technirel',
                onChanged: (value) =>
                    _update(() => _draft.equipmentBrand = value),
              ),
              const SizedBox(height: 10),
              AppTextField(
                initialValue: _draft.equipmentType,
                label: 'Type',
                hint: 'Ex. : Maxirel 200',
                onChanged: (value) =>
                    _update(() => _draft.equipmentType = value),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
