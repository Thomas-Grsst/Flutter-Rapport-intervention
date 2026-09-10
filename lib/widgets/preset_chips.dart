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
  return showDialog<String>(
    context: context,
    builder: (_) => _TextInputDialog(
      title: title,
      hint: hint,
      initialValue: initialValue,
      maxLines: maxLines,
    ),
  );
}

/// Contenu de [showTextInputDialog].
///
/// La boîte de dialogue est un widget à état pour que le contrôleur de saisie
/// vive exactement aussi longtemps que le champ qui l'utilise. Le détruire dès
/// le retour de `showDialog` le libérait trop tôt : la boîte est encore à
/// l'écran pendant son animation de fermeture, et le champ s'en servait après
/// coup — ce qui faisait planter l'application juste après « Valider ».
class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.hint,
    required this.initialValue,
    required this.maxLines,
  });

  final String title;
  final String? hint;
  final String initialValue;
  final int maxLines;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: widget.maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: widget.maxLines == 1 ? (_) => _submit() : null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Valider')),
      ],
    );
  }
}
