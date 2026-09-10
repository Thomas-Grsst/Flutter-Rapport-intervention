import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../theme.dart';

/// Pastille de statut affichée dans la liste et sur la fiche d'un rapport.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final ReportStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: compact ? 10.5 : 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: colors.foreground,
        ),
      ),
    );
  }

  static _StatusColors _colorsFor(ReportStatus status) {
    switch (status) {
      case ReportStatus.termine:
        return const _StatusColors(
          background: Color(0xFFE4F3EC),
          border: Color(0xFFB6DFCB),
          foreground: AppColors.success,
        );
      case ReportStatus.aSuivre:
        return const _StatusColors(
          background: Color(0xFFFDF1DC),
          border: Color(0xFFF0D6A6),
          foreground: AppColors.warning,
        );
      case ReportStatus.enCours:
        return const _StatusColors(
          background: AppColors.paleBlue,
          border: AppColors.brandLight,
          foreground: AppColors.brandDark,
        );
      case ReportStatus.brouillon:
        return const _StatusColors(
          background: Color(0xFFF0F2F5),
          border: Color(0xFFD5DEE8),
          foreground: Color(0xFF5A6773),
        );
    }
  }
}

class _StatusColors {
  const _StatusColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
