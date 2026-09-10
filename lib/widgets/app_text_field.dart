import 'package:flutter/material.dart';

/// Champ de saisie qui gère lui-même son contrôleur.
///
/// Les étapes de l'assistant écrivent directement dans le brouillon à chaque
/// frappe : rien n'est perdu si l'intervenant quitte l'écran ou si le
/// téléphone se met en veille au milieu d'une saisie.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.hint,
    this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.prefixIcon,
    this.autofocus = false,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? hint;
  final String? label;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final IconData? prefixIcon;
  final bool autofocus;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      maxLines: widget.maxLines,
      minLines: widget.maxLines > 1 ? widget.maxLines : null,
      keyboardType: widget.keyboardType ??
          (widget.maxLines > 1 ? TextInputType.multiline : null),
      textCapitalization: widget.textCapitalization,
      autofocus: widget.autofocus,
      textInputAction:
          widget.maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        hintText: widget.hint,
        labelText: widget.label,
        alignLabelWithHint: widget.maxLines > 1,
        prefixIcon:
            widget.prefixIcon == null ? null : Icon(widget.prefixIcon, size: 20),
      ),
    );
  }
}
