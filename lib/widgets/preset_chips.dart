import 'package:flutter/material.dart';

import '../theme.dart';

/// Liste de cases à cocher rapides (matériel, constats, actions).
///
/// L'intervenant coche ce qu'il a fait plutôt que de le rédiger, et le bouton
/// « Autre… » lui laisse toujours la possibilité de saisir un cas particulier.
/// La valeur saisie librement peut être mémorisée pour les rapports suivants
/// via [onCustomAdded].
class PresetChips extends StatelessWidget {
  const PresetChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.onCustomAdded,
    this.addLabel = 'Autre…',
    this.dialogTitle = 'Ajouter',
  });

  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  /// Appelé quand l'utilisateur saisit une valeur qui n'était pas proposée.
  final ValueChanged<String>? onCustomAdded;

  final String addLabel;
  final String dialogTitle;

  @override
  Widget build(BuildContext context) {
    // Les valeurs saisies librement s'affichent à la suite des propositions.
    final extras = selected
        .where((value) => !options.any((option) => option == value))
        .toList();
    final all = <String>[...options, ...extras];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in all)
          FilterChip(
            label: Text(option),
            selected: selected.contains(option),
            showCheckmark: true,
            checkmarkColor: AppColors.brandDark,
            labelStyle: TextStyle(
              fontSize: 13.5,
              color: selected.contains(option)
                  ? AppColors.brandDark
                  : const Color(0xFF35414D),
              fontWeight: selected.contains(option)
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
            onSelected: (isSelected) {
              final next = [...selected];
              if (isSelected) {
                next.add(option);
              } else {
                next.remove(option);
              }
              onChanged(next);
            },
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18, color: AppColors.brandDark),
          label: Text(addLabel),
          labelStyle: const TextStyle(
            fontSize: 13.5,
            color: AppColors.brandDark,
            fontWeight: FontWeight.w600,
          ),
          onPressed: () => _addCustom(context),
        ),
      ],
    );
  }

  Future<void> _addCustom(BuildContext context) async {
    final value = await showTextInputDialog(
      context,
      title: dialogTitle,
      hint: 'Saisissez votre texte',
    );
    if (value == null || value.isEmpty) return;
    if (!selected.contains(value)) {
      onChanged([...selected, value]);
    }
    onCustomAdded?.call(value);
  }
}

/// Petite boîte de dialogue de saisie, réutilisée par plusieurs écrans.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String? hint,
  String initialValue = '',
  int maxLines = 1,
}) async {
  final controller = TextEditingController(text: initialValue);

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: maxLines == 1
            ? (value) => Navigator.of(dialogContext).pop(value.trim())
            : null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
          child: const Text('Valider'),
        ),
      ],
    ),
  );

  controller.dispose();
  return result;
}
