import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/report.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/question_block.dart';

/// Étape 2 du rapport de filtre compact — l'installation entretenue.
///
/// Ces repères identifient le matériel d'une visite à l'autre : la référence
/// du contrat, le numéro de série gravé sur la cuve, et la date du dernier
/// passage, qui dit si l'entretien annuel a bien été tenu.
class FiltreInstallationStep extends StatefulWidget {
  const FiltreInstallationStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final Report draft;
  final VoidCallback onChanged;

  @override
  State<FiltreInstallationStep> createState() => _FiltreInstallationStepState();
}

class _FiltreInstallationStepState extends State<FiltreInstallationStep> {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  Report get _draft => widget.draft;

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  Future<void> _pickLastMaintenance() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.lastMaintenanceDate ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
      helpText: 'Date du dernier entretien',
    );
    if (picked != null) _update(() => _draft.lastMaintenanceDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final derniere = _draft.lastMaintenanceDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: 'Quel filtre compact entretenez-vous ?',
          hint: 'Pré-rempli avec le modèle sous contrat, modifiable.',
          child: Column(
            children: [
              AppTextField(
                initialValue: _draft.equipmentBrand,
                label: 'Marque',
                hint: 'Ex. : Premier Tech',
                onChanged: (value) =>
                    _update(() => _draft.equipmentBrand = value),
              ),
              const SizedBox(height: 10),
              AppTextField(
                initialValue: _draft.equipmentType,
                label: 'Modèle',
                hint: 'Ex. : Ecoflo Pack 5 EH sortie haute',
                onChanged: (value) =>
                    _update(() => _draft.equipmentType = value),
              ),
            ],
          ),
        ),
        QuestionBlock(
          question: 'Comment est-elle identifiée ?',
          optional: true,
          child: Column(
            children: [
              AppTextField(
                initialValue: _draft.reference,
                label: 'Référence installation',
                hint: 'Celle du contrat',
                onChanged: (value) => _update(() => _draft.reference = value),
              ),
              const SizedBox(height: 10),
              AppTextField(
                initialValue: _draft.serialNumber,
                label: 'N° de série',
                hint: 'Gravé sur la cuve',
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) => _update(() => _draft.serialNumber = value),
              ),
            ],
          ),
        ),
        QuestionBlock(
          question: 'Quand a eu lieu le dernier entretien ?',
          optional: true,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickLastMaintenance,
                  icon: const Icon(Icons.history),
                  label: Text(
                    derniere == null
                        ? 'Choisir la date'
                        : 'Le ${_dateFormat.format(derniere)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                child: derniere == null
                    ? null
                    : IconButton(
                        tooltip: 'Retirer la date',
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () =>
                            _update(() => _draft.lastMaintenanceDate = null),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
