import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/company.dart';
import '../../models/report.dart';
import '../../state/settings_provider.dart';
import '../../theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/preset_chips.dart';
import '../../widgets/question_block.dart';

/// Étape 1 — client, adresse d'intervention, type d'intervention, date et
/// intervenant.
class SiteStep extends StatefulWidget {
  const SiteStep({super.key, required this.draft, required this.onChanged});

  final Report draft;
  final VoidCallback onChanged;

  @override
  State<SiteStep> createState() => _SiteStepState();
}

class _SiteStepState extends State<SiteStep> {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  /// Ces compteurs ne changent que lorsque l'application remplit elle-même un
  /// champ (recopie de l'adresse, choix d'un intervenant). Ils servent de clé
  /// aux champs concernés pour forcer leur reconstruction avec la nouvelle
  /// valeur — ce qu'une clé basée sur le texte saisi ferait à chaque frappe,
  /// en faisant perdre le focus.
  int _siteTick = 0;
  int _technicianTick = 0;

  Report get _draft => widget.draft;

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  /// Beaucoup d'interventions ont lieu au domicile du client : ce raccourci
  /// évite de saisir deux fois la même adresse.
  void _copyClientAddress() {
    _update(() {
      _draft.siteAddressLine = _draft.clientAddressLine;
      _draft.sitePostalCode = _draft.clientPostalCode;
      _draft.siteCity = _draft.clientCity;
      if (_draft.siteContact.trim().isEmpty) {
        _draft.siteContact = _draft.clientName;
      }
      _siteTick++;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.interventionDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: "Date de l'intervention",
    );
    if (picked != null) {
      _update(() => _draft.interventionDate = picked);
    }
  }

  Future<void> _pickInterventionType() async {
    final settings = context.read<SettingsProvider>();
    final value = await showTextInputDialog(
      context,
      title: "Type d'intervention",
      hint: 'Ex. : Entretien poste de relevage',
      initialValue: _draft.interventionType,
    );
    if (value == null || value.isEmpty) return;
    _update(() => _draft.interventionType = value);
    await settings.rememberPreset(PresetList.interventionTypes, value);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: 'Qui est le client ?',
          hint: 'Le nom qui apparaîtra en haut du rapport.',
          child: Column(
            children: [
              AppTextField(
                initialValue: _draft.clientName,
                hint: 'Ex. : M. Manuel BLANC',
                prefixIcon: Icons.person_outline,
                onChanged: (value) => _update(() => _draft.clientName = value),
              ),
              const SizedBox(height: 10),
              AppTextField(
                initialValue: _draft.clientAddressLine,
                hint: 'Adresse du client',
                prefixIcon: Icons.home_outlined,
                onChanged: (value) =>
                    _update(() => _draft.clientAddressLine = value),
              ),
              const SizedBox(height: 10),
              _postalRow(
                postalCode: _draft.clientPostalCode,
                city: _draft.clientCity,
                onPostalCode: (value) =>
                    _update(() => _draft.clientPostalCode = value),
                onCity: (value) => _update(() => _draft.clientCity = value),
              ),
            ],
          ),
        ),
        QuestionBlock(
          question: "Où a eu lieu l'intervention ?",
          hint: "L'adresse du chantier, si elle diffère de celle du client.",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _copyClientAddress,
                  icon: const Icon(Icons.content_copy, size: 17),
                  label: const Text("Identique à l'adresse du client"),
                ),
              ),
              const SizedBox(height: 4),
              AppTextField(
                key: ValueKey('site-address-$_siteTick'),
                initialValue: _draft.siteAddressLine,
                hint: 'Ex. : 544 Rue du Vieux Château',
                prefixIcon: Icons.place_outlined,
                onChanged: (value) =>
                    _update(() => _draft.siteAddressLine = value),
              ),
              const SizedBox(height: 10),
              _postalRow(
                key: ValueKey(
                  'site-city-$_siteTick',
                ),
                postalCode: _draft.sitePostalCode,
                city: _draft.siteCity,
                onPostalCode: (value) =>
                    _update(() => _draft.sitePostalCode = value),
                onCity: (value) => _update(() => _draft.siteCity = value),
              ),
            ],
          ),
        ),
        QuestionBlock(
          question: 'À quel endroit précis ?',
          hint: "Ex. : cuisine d'été extérieure, garage, regard côté rue.",
          optional: true,
          child: AppTextField(
            initialValue: _draft.siteLocation,
            hint: 'Localisation',
            prefixIcon: Icons.my_location_outlined,
            onChanged: (value) => _update(() => _draft.siteLocation = value),
          ),
        ),
        QuestionBlock(
          question: 'Qui vous a reçu sur place ?',
          optional: true,
          child: AppTextField(
            key: ValueKey('site-contact-$_siteTick'),
            initialValue: _draft.siteContact,
            hint: 'Contact sur place',
            prefixIcon: Icons.badge_outlined,
            onChanged: (value) => _update(() => _draft.siteContact = value),
          ),
        ),
        QuestionBlock(
          question: "Quel type d'intervention ?",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in settings.interventionTypes)
                    ChoiceChip(
                      label: Text(type),
                      selected: _draft.interventionType == type,
                      labelStyle: TextStyle(
                        fontSize: 13.5,
                        color: _draft.interventionType == type
                            ? AppColors.brandDark
                            : const Color(0xFF35414D),
                        fontWeight: _draft.interventionType == type
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      onSelected: (_) =>
                          _update(() => _draft.interventionType = type),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.edit_outlined,
                        size: 17, color: AppColors.brandDark),
                    label: const Text('Autre…'),
                    labelStyle: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.brandDark,
                      fontWeight: FontWeight.w600,
                    ),
                    onPressed: _pickInterventionType,
                  ),
                ],
              ),
              if (_draft.interventionType.isNotEmpty &&
                  !settings.interventionTypes.contains(_draft.interventionType))
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Sélectionné : ${_draft.interventionType}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.brandDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        QuestionBlock(
          question: 'Le client a-t-il donné une référence ?',
          hint: 'Numéro de devis, de commande ou de dossier du client. '
              'Il apparaît en « V/Réf » sur le rapport.',
          optional: true,
          child: AppTextField(
            initialValue: _draft.reference,
            hint: 'Ex. : DEV-2026-0148',
            prefixIcon: Icons.tag_outlined,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) => _update(() => _draft.reference = value),
          ),
        ),
        QuestionBlock(
          question: "Quand l'intervention a-t-elle eu lieu ?",
          child: OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              'Le ${_dateFormat.format(_draft.interventionDate)}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        QuestionBlock(
          question: 'Qui est intervenu ?',
          child: _technicianSelector(settings.technicians),
        ),
      ],
    );
  }

  Widget _technicianSelector(List<Technician> technicians) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (technicians.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final technician in technicians)
                ChoiceChip(
                  label: Text(technician.name),
                  selected: _draft.technicianName == technician.name,
                  labelStyle: TextStyle(
                    fontSize: 13.5,
                    color: _draft.technicianName == technician.name
                        ? AppColors.brandDark
                        : const Color(0xFF35414D),
                    fontWeight: _draft.technicianName == technician.name
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  onSelected: (_) => _update(() {
                    _draft.technicianName = technician.name;
                    _draft.technicianPhone = technician.phone;
                    _technicianTick++;
                  }),
                ),
            ],
          ),
        const SizedBox(height: 10),
        AppTextField(
          key: ValueKey('technician-$_technicianTick'),
          initialValue: _draft.technicianName,
          hint: "Nom de l'intervenant",
          prefixIcon: Icons.engineering_outlined,
          onChanged: (value) => _update(() => _draft.technicianName = value),
        ),
      ],
    );
  }

  Widget _postalRow({
    Key? key,
    required String postalCode,
    required String city,
    required ValueChanged<String> onPostalCode,
    required ValueChanged<String> onCity,
  }) {
    return Row(
      key: key,
      children: [
        SizedBox(
          // Assez large pour que « Code postal » s'affiche en entier : le
          // libellé tronqué en « Code pos… » se lisait mal.
          width: 138,
          child: AppTextField(
            initialValue: postalCode,
            hint: 'Code postal',
            keyboardType: TextInputType.number,
            onChanged: onPostalCode,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppTextField(
            initialValue: city,
            hint: 'Ville',
            textCapitalization: TextCapitalization.characters,
            onChanged: onCity,
          ),
        ),
      ],
    );
  }
}
