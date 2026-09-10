import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/photo_group.dart';
import '../../models/photo_item.dart';
import '../../models/report.dart';
import '../../services/storage_service.dart';
import '../../state/reports_provider.dart';
import '../../theme.dart';
import '../../widgets/media_image.dart';
import '../../widgets/preset_chips.dart';
import '../../widgets/question_block.dart';

/// Étape 5 — les photos, rangées par lot.
///
/// Un lot correspond à un point de l'intervention : le poste de relevage, puis
/// les WC. Chaque lot a sa case avant, sa case pendant et sa case après, et
/// n'importe laquelle peut rester vide. C'est ce qui garde le lien entre un
/// « avant » et l'« après » qui lui répond — un classement à plat par moment
/// de prise de vue le perdait dès qu'il y avait plus d'un point.
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

  /// Les trois moments proposés dans un lot, dans l'ordre du rapport.
  static const List<PhotoStage> _stages = [
    PhotoStage.avant,
    PhotoStage.pendant,
    PhotoStage.apres,
  ];

  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  Report get _draft => widget.draft;

  @override
  void initState() {
    super.initState();
    // Un rapport neuf s'ouvre sur un lot vide : sans cela l'étape n'offrirait
    // qu'un bouton « Ajouter un lot », sans montrer à quoi elle sert.
    if (_draft.photoGroups.isEmpty) {
      _draft.photoGroups.add(context.read<ReportsProvider>().buildPhotoGroup());
    }
  }

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  // --- Lots -----------------------------------------------------------------

  void _addGroup() {
    _update(() =>
        _draft.photoGroups.add(context.read<ReportsProvider>().buildPhotoGroup()));
  }

  Future<void> _renameGroup(PhotoGroup group, int index) async {
    final label = await showTextInputDialog(
      context,
      title: 'Nom du lot ${index + 1}',
      hint: 'Ex. : poste de relevage',
      initialValue: group.label,
    );
    if (label == null) return;
    _update(() => group.label = label);
  }

  Future<void> _deleteGroup(PhotoGroup group) async {
    final storage = context.read<StorageService>();
    final paths = group.photos.map((photo) => photo.filePath).toList();

    _update(() => _draft.photoGroups.remove(group));
    for (final path in paths) {
      await storage.deleteFileIfExists(path);
    }
  }

  // --- Photos ---------------------------------------------------------------

  Future<void> _addPhotos(
    PhotoGroup group,
    PhotoStage stage,
    ImageSource source,
  ) async {
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
        group.photos.add(reports.buildPhoto(stored, stage));
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

  Future<void> _pickSource(PhotoGroup group, PhotoStage stage) async {
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

    if (source != null && mounted) {
      await _addPhotos(group, stage, source);
    }
  }

  Future<void> _editPhoto(PhotoGroup group, PhotoItem photo) async {
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
                if (caption != null) _update(() => photo.caption = caption);
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
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Supprimer la photo',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _deletePhoto(group, photo);
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
            for (final stage in _stages)
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

    if (stage != null) _update(() => photo.stage = stage);
  }

  Future<void> _deletePhoto(PhotoGroup group, PhotoItem photo) async {
    final storage = context.read<StorageService>();
    _update(() => group.photos.removeWhere((item) => item.id == photo.id));
    await storage.deleteFileIfExists(photo.filePath);
  }

  // --- Affichage ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: 'Ajoutez vos photos',
          hint: 'Un lot par point de l\'intervention : le poste, puis les WC. '
              'Chaque lot a son avant, son pendant et son après, et le rapport '
              'les imprime en face les uns des autres.',
          child: Column(
            children: [
              for (var i = 0; i < _draft.photoGroups.length; i++)
                _groupCard(_draft.photoGroups[i], i),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _addGroup,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter un lot'),
                ),
              ),
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

  Widget _groupCard(PhotoGroup group, int index) {
    final title = group.label.trim().isEmpty
        ? 'Lot ${index + 1}'
        : '${index + 1}. ${group.label.trim()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5DEE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _renameGroup(group, index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_outlined,
                            size: 15, color: Color(0xFF8A97A3)),
                      ],
                    ),
                  ),
                ),
              ),
              // Le dernier lot ne se supprime pas : l'étape resterait sans
              // aucun emplacement où déposer une photo.
              if (_draft.photoGroups.length > 1)
                IconButton(
                  tooltip: 'Supprimer le lot',
                  icon: const Icon(Icons.close, size: 19),
                  color: const Color(0xFF8A97A3),
                  onPressed: () => _deleteGroup(group),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final stage in _stages) ...[
                Expanded(child: _stageColumn(group, stage, index)),
                if (stage != _stages.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _stageColumn(PhotoGroup group, PhotoStage stage, int groupIndex) {
    final photos = group.ofStage(stage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stage.label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7785),
          ),
        ),
        const SizedBox(height: 6),
        for (final photo in photos)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _thumbnail(group, photo),
          ),
        _addTile(group, stage, groupIndex),
      ],
    );
  }

  Widget _thumbnail(PhotoGroup group, PhotoItem photo) {
    return GestureDetector(
      onTap: () => _editPhoto(group, photo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 1,
              child: MediaImage(path: photo.filePath),
            ),
          ),
          if (photo.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                photo.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7785)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _addTile(PhotoGroup group, PhotoStage stage, int groupIndex) {
    // La case ne porte qu'une icône, faute de place sur trois colonnes : le
    // libellé passe par la sémantique, pour que la commande reste annonçable
    // et qu'on sache de quel moment de quel lot il s'agit.
    return Semantics(
      button: true,
      label: 'Ajouter une photo ${stage.label} au lot ${groupIndex + 1}',
      child: InkWell(
        onTap: _busy ? null : () => _pickSource(group, stage),
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brandLight, width: 1.4),
            ),
            child: const Center(
              child: Icon(Icons.add_a_photo_outlined,
                  color: AppColors.brandDark, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
