import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/report.dart';
import '../theme.dart';
import 'media_image.dart';
import 'status_chip.dart';

/// Ligne de la liste des rapports : vignette, client, type d'intervention,
/// adresse et statut.
class ReportCard extends StatelessWidget {
  ReportCard({super.key, required this.report, required this.onTap});

  final Report report;
  final VoidCallback onTap;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _thumbnail(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.displayClient,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF35414D),
                      ),
                    ),
                    if (report.siteOneLine.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: Color(0xFF8A97A3),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              report.siteOneLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF6B7785),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusChip(status: report.status, compact: true),
                        const SizedBox(width: 8),
                        Text(
                          _dateFormat.format(report.interventionDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A97A3),
                          ),
                        ),
                        if (report.photos.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.photo_camera_outlined,
                            size: 13,
                            color: Color(0xFF8A97A3),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${report.photos.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A97A3),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() {
    final photo = report.photos.isNotEmpty ? report.photos.first : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 66,
        height: 66,
        child: MediaImage(
          path: photo?.filePath,
          placeholder: Container(
            color: AppColors.paleBlue,
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.brandLight,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
