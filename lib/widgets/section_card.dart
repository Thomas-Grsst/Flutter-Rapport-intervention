import 'package:flutter/material.dart';

import '../theme.dart';

/// Carte de section utilisée sur la fiche d'un rapport et dans les réglages.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: AppColors.brandLight),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandDark,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Couple « libellé : valeur » affiché sur la fiche d'un rapport.
class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7785),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paragraphe libre (observations, constats, conclusions).
class InfoParagraph extends StatelessWidget {
  const InfoParagraph({super.key, required this.text, this.emptyLabel});

  final String text;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      if (emptyLabel == null) return const SizedBox.shrink();
      return Text(
        emptyLabel!,
        style: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFF8A97A3),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Text(
      text.trim(),
      style: const TextStyle(fontSize: 14, height: 1.45),
    );
  }
}
