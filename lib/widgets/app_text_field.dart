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
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Le champ suit une valeur changée de l'extérieur — un client repris du
    // carnet, une réponse rapide cochée. Sans cela, le brouillon était bien
    // rempli mais l'écran continuait d'afficher l'ancien texte.
    //
    // Tant qu'il a le focus, en revanche, le champ est maître de son contenu
    // et rien ne le réécrit. Ce que le brouillon renvoie pendant la frappe
    // n'est pas toujours ce qui a été tapé — il élague les espaces de fin —,
    // et le recopier ramenait le curseur au début du texte : les lettres
    // suivantes s'inséraient alors n'importe où.
    if (!_focusNode.hasFocus && widget.initialValue != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection:
            TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
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
