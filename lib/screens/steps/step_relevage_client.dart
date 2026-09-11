import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/company.dart';
import '../../models/report.dart';
import '../../state/settings_provider.dart';
import '../../theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/preset_chips.dart';
import '../../widgets/question_block.dart';

/// Étape 1 du rapport de poste de relevage — le client, tel qu'il est imprimé
/// en tête du rapport, et qui est intervenu.
class RelevageClientStep extends StatefulWidget {
  const RelevageClientStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final Report draft;
  final VoidCallback onChanged;

  @override
  State<RelevageClientStep> createState() => _RelevageClientStepState();
}

class _RelevageClientStepState extends State<RelevageClientStep> {
  Report get _draft => widget.draft;

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  bool _isSelected(Technician technician) =>
      _draft.technicians.any((item) => item.name == technician.name);

  void _toggle(Technician technician) {
    _update(() {
      if (_isSelected(technician)) {
        _draft.technicians.removeWhere((item) => item.name == technician.name);
      } else {
        _draft.technicians.add(technician);
      }
    });
  }

  Future<void> _addTechnician() async {
    final settings = context.read<SettingsProvider>();

    final name = await showTextInputDialog(
      context,
      title: 'Ajouter un intervenant',
      hint: 'Nom et prénom',
    );
    if (name == null || name.isEmpty || !mounted) return;

    final phone = await showTextInputDialog(
      context,
      title: 'Téléphone de $name',
      hint: 'Facultatif',
    );
    if (!mounted) return;

    final technician = Technician(name: name, phone: phone ?? '');
    if (!_isSelected(technician)) {
      _update(() => _draft.technicians.add(technician));
    }

    final known = settings.settings.technicians;
    if (!known.any((item) => item.name == technician.name)) {
      await settings.update(
        settings.settings.copyWith(technicians: [...known, technician]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final known = context.watch<SettingsProvider>().settings.technicians;
    final extras = _draft.technicians
        .where((item) => !known.any((k) => k.name == item.name))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: 'Qui est le client ?',
          hint: 'Le nom, puis les coordonnées telles qu\'elles figureront en '
              'tête du rapport.',
          child: Column(
            children: [
              AppTextField(
                initialValue: _draft.clientName,
                label: 'Client',
                hint: 'Ex. : Association La Roseraie',
                prefixIcon: Icons.person_outline,
                onChanged: (value) => _update(() => _draft.clientName = value),
              ),
              const SizedBox(height: 10),
              AppTextField(
                initialValue: _draft.clientAddressLine,
                label: 'Adresse',
                hint: 'Ex. : 19, Avenue Salvador Allende',
                prefixIcon: Icons.home_outlined,
                onChanged: (value) =>
                    _update(() => _draft.clientAddressLine = value),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 138,
                    child: AppTextField(
                      initialValue: _draft.clientPostalCode,
                      label: 'Code postal',
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          _update(() => _draft.clientPostalCode = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      initialValue: _draft.clientCity,
                      label: 'Commune',
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) =>
                          _update(() => _draft.clientCity = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppTextField(
                initialValue: _draft.clientPhone,
                label: 'Téléphone',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                onChanged: (value) => _update(() => _draft.clientPhone = value),
              ),
              const SizedBox(height: 10),
              AppTextField(
                initialValue: _draft.clientEmail,
                label: 'E-mail',
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                prefixIcon: Icons.mail_outline,
                onChanged: (value) => _update(() => _draft.clientEmail = value),
              ),
            ],
          ),
        ),
        QuestionBlock(
          question: "Quand l'entretien a-t-il eu lieu ?",
          child: OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              'Le ${_draft.interventionDate.day.toString().padLeft(2, '0')}/'
              '${_draft.interventionDate.month.toString().padLeft(2, '0')}/'
              '${_draft.interventionDate.year}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        QuestionBlock(
          question: 'Qui est intervenu ?',
          hint: 'Cochez tous ceux qui étaient sur place.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final technician in [...known, ...extras])
                FilterChip(
                  label: Text(technician.name),
                  selected: _isSelected(technician),
                  showCheckmark: true,
                  checkmarkColor: AppColors.brandDark,
                  labelStyle: TextStyle(
                    fontSize: 13.5,
                    color: _isSelected(technician)
                        ? AppColors.brandDark
                        : const Color(0xFF35414D),
                    fontWeight: _isSelected(technician)
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  onSelected: (_) => _toggle(technician),
                ),
              ActionChip(
                avatar: const Icon(Icons.person_add_alt,
                    size: 18, color: AppColors.brandDark),
                label: const Text('Ajouter quelqu\'un'),
                labelStyle: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.brandDark,
                  fontWeight: FontWeight.w600,
                ),
                onPressed: _addTechnician,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.interventionDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: "Date de l'entretien",
    );
    if (picked != null) _update(() => _draft.interventionDate = picked);
  }
}
