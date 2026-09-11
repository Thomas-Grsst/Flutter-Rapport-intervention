import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/photo_group.dart';
import '../models/photo_item.dart';
import '../services/storage_service.dart';
import '../state/reports_provider.dart';
import '../theme.dart';
import 'media_image.dart';
import 'preset_chips.dart';

/// Les photos d'une section, en simple grille.
///
/// Contrairement aux lots d'un rapport d'intervention, le rapport d'entretien
/// de poste de relevage ne classe pas ses photos en avant / pendant / apres :
/// chaque section a les siennes, dans l'ordre ou elles ont ete prises.
class SectionPhotos extends StatefulWidget {
  const SectionPhotos({
    super.key,
    required this.group,
    required this.onChanged,
    this.label = 'Photos',
  });

  final PhotoGroup group;
  final VoidCallback onChanged;
  final String label;

  @override
  State<SectionPhotos> createState() => _SectionPhotosState();
}

class _SectionPhotosState extends State<SectionPhotos> {
  static const int _maxWidth = 1600;
  static const int _quality = 82;

  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  Future<void> _addPhotos(ImageSource source) async {
    final storage = context.read<StorageService>();
    final reports = context.read<ReportsProvider>();

    setState(() => _busy = true);
    try {
      final picked = <XFile>[];
      if (source == ImageSource.camera) {
        final shot = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: _maxWidth.toDouble(),
          imageQuality: _quality,
        );
        if (shot != null) picked.add(shot);
      } else {
        picked.addAll(
          await _picker.pickMultiImage(
            maxWidth: _maxWidth.toDouble(),
            imageQuality: _quality,
          ),
        );
      }

      for (final file in picked) {
        final stored = await storage.importMedia(file.path, prefix: 'photo');
        widget.group.photos.add(
          reports.buildPhoto(stored, PhotoStage.autre),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Impossible d'ajouter la photo : $error")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onChanged();
      }
    }
  }

  Future<void> _pickSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null && mounted) await _addPhotos(source);
  }

  Future<void> _editPhoto(PhotoItem photo) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Ajouter une légende'),
              subtitle: photo.caption.isEmpty ? null : Text(photo.caption),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final caption = await showTextInputDialog(
                  context,
                  title: 'Légende de la photo',
                  hint: 'Ex. : panier dégrilleur',
                  initialValue: photo.caption,
                );
                if (caption != null) _update(() => photo.caption = caption);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Supprimer la photo',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _deletePhoto(photo);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto(PhotoItem photo) async {
    final storage = context.read<StorageService>();
    _update(
      () => widget.group.photos.removeWhere((item) => item.id == photo.id),
    );
    await storage.deleteFileIfExists(photo.filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.group.photos.length}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF8A97A3)),
            ),
            if (_busy) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final photo in widget.group.photos) _thumbnail(photo),
            _addTile(),
          ],
        ),
      ],
    );
  }

  Widget _thumbnail(PhotoItem photo) {
    return GestureDetector(
      onTap: () => _editPhoto(photo),
      child: SizedBox(
        width: 96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 96,
                height: 96,
                child: MediaImage(path: photo.filePath),
              ),
            ),
            if (photo.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  photo.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 11.5, color: Color(0xFF6B7785)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _addTile() {
    return Semantics(
      button: true,
      label: 'Ajouter une photo — ${widget.label}',
      child: InkWell(
        onTap: _busy ? null : _pickSource,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.brandLight, width: 1.4),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined,
                  color: AppColors.brandDark, size: 24),
              SizedBox(height: 4),
              Text('Ajouter',
                  style: TextStyle(fontSize: 11.5, color: AppColors.brandDark)),
            ],
          ),
        ),
      ),
    );
  }
}
