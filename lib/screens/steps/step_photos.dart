import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/photo_item.dart';
import '../../models/report.dart';
import '../../services/storage_service.dart';
import '../../state/reports_provider.dart';
import '../../theme.dart';
import '../../widgets/media_image.dart';
import '../../widgets/preset_chips.dart';
import '../../widgets/question_block.dart';

/// Étape 5 — les photos, regroupées par moment de prise de vue.
///
/// Les photos sont redimensionnées à la prise de vue : un rapport de dix
/// photos doit rester envoyable par e-mail depuis un chantier, parfois en
/// 4G faible.
class PhotosStep extends StatefulWidget {
  const PhotosStep({super.key, required this.draft, required this.onChanged});

  final Report draft;
  final VoidCallback onChanged;

  @override
  State<PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends State<PhotosStep> {
  static const int _maxWidth = 1600;
  static const int _quality = 82;

  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  Report get _draft => widget.draft;

  Future<void> _addPhotos(PhotoStage stage, ImageSource source) async {
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
        final stored = await storage.importMedia(file.path, prefix: stage.name);
        _draft.photos.add(reports.buildPhoto(stored, stage));
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

  Future<void> _pickSource(PhotoStage stage) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null && mounted) {
      await _addPhotos(stage, source);
    }
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
                  hint: 'Ex. : fosse avant pompage',
                  initialValue: photo.caption,
                );
                if (caption != null) {
                  setState(() => photo.caption = caption);
                  widget.onChanged();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Changer le moment'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _changeStage(photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppColors.danger),
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

  Future<void> _changeStage(PhotoItem photo) async {
    final stage = await showModalBottomSheet<PhotoStage>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final stage in PhotoStage.values)
              ListTile(
                title: Text(stage.label),
                trailing: photo.stage == stage
                    ? const Icon(Icons.check, color: AppColors.brandDark)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(stage),
              ),
          ],
        ),
      ),
    );

    if (stage != null) {
      setState(() => photo.stage = stage);
      widget.onChanged();
    }
  }

  Future<void> _deletePhoto(PhotoItem photo) async {
    final storage = context.read<StorageService>();
    setState(() => _draft.photos.removeWhere((item) => item.id == photo.id));
    widget.onChanged();
    await storage.deleteFileIfExists(photo.filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: 'Ajoutez vos photos',
          hint: 'Classez-les en avant, pendant et après : le rapport les '
              'présentera dans cet ordre.',
          child: Column(
            children: [
              for (final stage in const [
                PhotoStage.avant,
                PhotoStage.pendant,
                PhotoStage.apres,
                PhotoStage.autre,
              ])
                _stageSection(stage),
            ],
          ),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Import en cours…',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7785))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _stageSection(PhotoStage stage) {
    final photos = _draft.photosOfStage(stage);

    // Le groupe « Autre » n'apparaît que s'il contient déjà des photos : on ne
    // propose pas une catégorie fourre-tout par défaut.
    if (stage == PhotoStage.autre && photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                stage.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${photos.length}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF8A97A3)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final photo in photos) _thumbnail(photo),
              _addTile(stage),
            ],
          ),
        ],
      ),
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
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B7785),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _addTile(PhotoStage stage) {
    return InkWell(
      onTap: _busy ? null : () => _pickSource(stage),
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
            Text(
              'Ajouter',
              style: TextStyle(fontSize: 11.5, color: AppColors.brandDark),
            ),
          ],
        ),
      ),
    );
  }
}
