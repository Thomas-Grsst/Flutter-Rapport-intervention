import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/company.dart';
import '../services/pdf_service.dart';
import '../state/settings_provider.dart';
import '../theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/media_image.dart';
import '../widgets/preset_chips.dart';
import '../widgets/section_card.dart';

/// Réglages : fiche entreprise, logo, intervenants et listes de choix rapides.
///
/// Tout ce qui est saisi ici est repris automatiquement sur chaque rapport.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _draft = context.read<SettingsProvider>().settings;
  bool _dirty = false;

  Company get _company => _draft.company;

  void _updateCompany(Company Function(Company) change) {
    setState(() {
      _draft = _draft.copyWith(company: change(_company));
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (!_dirty) return;
    await context.read<SettingsProvider>().update(_draft);
    _dirty = false;
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
    );
    if (picked == null || !mounted) return;

    // Le logo est enregistré tout de suite : c'est un fichier, pas un champ
    // texte, il n'a pas à attendre l'enregistrement du reste du formulaire.
    await _save();
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    await settings.setLogo(picked.path);
    if (!mounted) return;
    setState(() => _draft = settings.settings);
  }

  Future<void> _removeLogo() async {
    final settings = context.read<SettingsProvider>();
    await _save();
    await settings.removeLogo();
    if (!mounted) return;
    setState(() => _draft = settings.settings);
  }

  Future<void> _addTechnician() async {
    final name = await showTextInputDialog(
      context,
      title: 'Nouvel intervenant',
      hint: 'Nom et prénom',
    );
    if (name == null || name.isEmpty || !mounted) return;

    final phone = await showTextInputDialog(
      context,
      title: 'Téléphone de $name',
      hint: 'Facultatif',
    );

    setState(() {
      _draft = _draft.copyWith(
        technicians: [
          ..._draft.technicians,
          Technician(name: name, phone: phone ?? ''),
        ],
      );
      _dirty = true;
    });
  }

  void _removeTechnician(Technician technician) {
    setState(() {
      _draft = _draft.copyWith(
        technicians:
            _draft.technicians.where((item) => item != technician).toList(),
      );
      _dirty = true;
    });
  }

  Future<void> _editPresets(PresetList list) async {
    await _save();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _PresetEditorScreen(list: list)),
    );
    if (!mounted) return;
    setState(() => _draft = context.read<SettingsProvider>().settings);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _save();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Réglages'),
          actions: [
            TextButton(
              onPressed: () async {
                await _save();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Réglages enregistrés')),
                );
              },
              child: const Text(
                'Enregistrer',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _companyCard(),
            const SizedBox(height: 12),
            _legalCard(),
            const SizedBox(height: 12),
            _logoCard(),
            const SizedBox(height: 12),
            _techniciansCard(),
            const SizedBox(height: 12),
            _presetsCard(),
          ],
        ),
      ),
    );
  }

  Widget _companyCard() {
    return SectionCard(
      title: 'Mon entreprise',
      icon: Icons.business_outlined,
      children: [
        Row(
          children: [
            SizedBox(
              width: 96,
              child: AppTextField(
                initialValue: _company.legalForm,
                label: 'Forme',
                hint: 'SASU',
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) =>
                    _updateCompany((c) => c.copyWith(legalForm: value)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextField(
                initialValue: _company.name,
                label: "Nom de l'entreprise",
                hint: 'Ex. : MARTIN ASSAINISSEMENT',
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) =>
                    _updateCompany((c) => c.copyWith(name: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _company.addressLine,
          label: 'Adresse du siège',
          hint: 'Ex. : 12, Rue des Ateliers',
          prefixIcon: Icons.home_outlined,
          onChanged: (value) =>
              _updateCompany((c) => c.copyWith(addressLine: value)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              width: 138,
              child: AppTextField(
                initialValue: _company.postalCode,
                label: 'Code postal',
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _updateCompany((c) => c.copyWith(postalCode: value)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextField(
                initialValue: _company.city,
                label: 'Ville',
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) =>
                    _updateCompany((c) => c.copyWith(city: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _company.phone,
          label: 'Téléphone',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
          onChanged: (value) => _updateCompany((c) => c.copyWith(phone: value)),
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _company.email,
          label: 'E-mail',
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          prefixIcon: Icons.mail_outline,
          onChanged: (value) => _updateCompany((c) => c.copyWith(email: value)),
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _draft.reportNumberPrefix,
          label: 'Préfixe des numéros de rapport',
          hint: 'Vos initiales, ex. : MA',
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) => setState(() {
            _draft = _draft.copyWith(reportNumberPrefix: value);
            _dirty = true;
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Les numéros seront de la forme '
          '${_draft.reportNumberPrefix.isEmpty ? 'RAP' : _draft.reportNumberPrefix.toUpperCase()}-120326-MB.',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A97A3)),
        ),
      ],
    );
  }

  /// Mentions légales imprimées en pied de chaque page du rapport.
  Widget _legalCard() {
    return SectionCard(
      title: 'Mentions légales',
      icon: Icons.gavel_outlined,
      children: [
        const Text(
          'Elles apparaissent en pied de chaque page du rapport.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7785)),
        ),
        const SizedBox(height: 12),
        AppTextField(
          initialValue: _company.siret,
          label: 'SIRET',
          hint: '14 chiffres',
          keyboardType: TextInputType.number,
          onChanged: (value) => _updateCompany((c) => c.copyWith(siret: value)),
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _company.ape,
          label: 'Code APE',
          hint: 'Ex. : 3700Z — Collecte et traitement des eaux usées',
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) => _updateCompany((c) => c.copyWith(ape: value)),
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _company.rcs,
          label: 'RCS',
          hint: 'Ville et numéro d\'immatriculation',
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) => _updateCompany((c) => c.copyWith(rcs: value)),
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _company.vatNumber,
          label: 'N° TVA intracommunautaire',
          hint: 'FR + 11 caractères',
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) =>
              _updateCompany((c) => c.copyWith(vatNumber: value)),
        ),
        const SizedBox(height: 10),
        AppTextField(
          initialValue: _company.capital,
          label: 'Capital social',
          hint: 'Ex. : 2 000,00 €',
          onChanged: (value) =>
              _updateCompany((c) => c.copyWith(capital: value)),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.paleBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'En pied de page',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _company.legalLine,
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logoCard() {
    final path = _company.logoPath;
    final hasLogo = path != null && path.isNotEmpty;

    return SectionCard(
      title: 'Logo',
      icon: Icons.image_outlined,
      children: [
        Row(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD5DEE8)),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(6),
              child: MediaImage(
                path: path,
                fit: BoxFit.contain,
                fallbackAsset: PdfService.defaultLogoAsset,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Le logo apparaît sur la page de garde et en tête de '
                    'chaque page du PDF.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7785)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _pickLogo,
                        child: Text(hasLogo ? 'Changer' : 'Remplacer'),
                      ),
                      if (hasLogo)
                        TextButton(
                          onPressed: _removeLogo,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger,
                          ),
                          child: const Text('Retirer'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _techniciansCard() {
    return SectionCard(
      title: 'Intervenants',
      icon: Icons.engineering_outlined,
      trailing: IconButton(
        onPressed: _addTechnician,
        icon: const Icon(Icons.add, color: AppColors.brandDark),
        tooltip: 'Ajouter un intervenant',
      ),
      children: [
        if (_draft.technicians.isEmpty)
          const Text(
            'Aucun intervenant enregistré.',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF8A97A3)),
          ),
        for (final technician in _draft.technicians)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(technician.name),
            subtitle:
                technician.phone.isEmpty ? null : Text(technician.phone),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => _removeTechnician(technician),
            ),
          ),
      ],
    );
  }

  Widget _presetsCard() {
    return SectionCard(
      title: 'Listes de choix rapides',
      icon: Icons.checklist_outlined,
      children: [
        const Text(
          'Ce que vos intervenants cochent sur le chantier au lieu de le '
          'rédiger.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7785)),
        ),
        const SizedBox(height: 6),
        for (final list in PresetList.values)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(list.label),
            subtitle: Text('${_draft.presetsCount(list)} éléments'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editPresets(list),
          ),
      ],
    );
  }
}

extension on AppSettings {
  int presetsCount(PresetList list) {
    switch (list) {
      case PresetList.interventionTypes:
        return interventionTypes.length;
      case PresetList.materials:
        return materialPresets.length;
      case PresetList.findings:
        return findingPresets.length;
      case PresetList.actions:
        return actionPresets.length;
    }
  }
}

/// Édition d'une liste de choix rapides.
class _PresetEditorScreen extends StatefulWidget {
  const _PresetEditorScreen({required this.list});

  final PresetList list;

  @override
  State<_PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends State<_PresetEditorScreen> {
  late List<String> _values =
      [...context.read<SettingsProvider>().presetsOf(widget.list)];

  Future<void> _persist() =>
      context.read<SettingsProvider>().replacePresets(widget.list, _values);

  Future<void> _add() async {
    final value = await showTextInputDialog(
      context,
      title: 'Ajouter à « ${widget.list.label} »',
    );
    if (value == null || value.isEmpty) return;
    setState(() => _values = [..._values, value]);
    await _persist();
  }

  Future<void> _edit(int index) async {
    final value = await showTextInputDialog(
      context,
      title: 'Modifier',
      initialValue: _values[index],
    );
    if (value == null || value.isEmpty) return;
    setState(() => _values[index] = value);
    await _persist();
  }

  Future<void> _remove(int index) async {
    setState(() => _values.removeAt(index));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.list.label)),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: AppColors.brandDark,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _values.isEmpty
          ? const Center(
              child: Text(
                'Aucun élément. Appuyez sur + pour en ajouter.',
                style: TextStyle(color: Color(0xFF8A97A3)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _values.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => ListTile(
                title: Text(_values[index]),
                onTap: () => _edit(index),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _remove(index),
                ),
              ),
            ),
    );
  }
}
