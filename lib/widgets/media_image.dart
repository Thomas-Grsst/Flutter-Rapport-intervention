import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../theme.dart';

/// Affiche une photo, un logo ou une signature enregistre par l'application.
///
/// Les images ne sont pas lues avec `Image.file` : le chemin d'un media est
/// un chemin de fichier sur telephone mais une cle de stockage dans un
/// navigateur. Passer par [StorageService.readBytes] laisse les ecrans
/// afficher un media sans savoir ou il est reellement range.
class MediaImage extends StatefulWidget {
  const MediaImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.fallbackAsset,
  });

  final String? path;
  final BoxFit fit;

  /// Affiche a la place de l'image quand le media est absent ou illisible.
  final Widget? placeholder;

  /// Image livree avec l'application, affichee quand [path] est vide.
  /// Sert au logo par defaut, avant que l'utilisateur en choisisse un.
  final String? fallbackAsset;

  @override
  State<MediaImage> createState() => _MediaImageState();
}

class _MediaImageState extends State<MediaImage> {
  late Future<Uint8List?> _bytes = _read();

  Future<Uint8List?> _read() =>
      context.read<StorageService>().readBytes(widget.path);

  @override
  void didUpdateWidget(MediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _bytes = _read();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          // Tant que la lecture est en cours, on montre un aplat plutot qu'un
          // indicateur de chargement : les vignettes sont petites et lues en
          // quelques millisecondes, un spinner ne ferait que clignoter.
          if (snapshot.connectionState != ConnectionState.done) {
            return Container(color: AppColors.paleBlue);
          }
          final fallback = widget.fallbackAsset;
          if (fallback != null) {
            return Image.asset(fallback, fit: widget.fit);
          }
          return widget.placeholder ??
              Container(
                color: AppColors.paleBlue,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.brandLight,
                ),
              );
        }
        return Image.memory(bytes, fit: widget.fit);
      },
    );
  }
}
