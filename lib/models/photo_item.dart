import 'enums.dart';

/// Une photo attachee a un rapport.
///
/// [filePath] pointe vers une copie du fichier dans le dossier de
/// l'application : la photo reste disponible meme si l'utilisateur vide sa
/// galerie.
class PhotoItem {
  PhotoItem({
    required this.id,
    required this.filePath,
    this.stage = PhotoStage.autre,
    this.caption = '',
  });

  final String id;
  String filePath;
  PhotoStage stage;
  String caption;

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'stage': stage.name,
        'caption': caption,
      };

  factory PhotoItem.fromJson(Map<String, dynamic> json) => PhotoItem(
        id: json['id'] as String,
        filePath: json['filePath'] as String,
        stage: PhotoStage.fromName(json['stage'] as String?),
        caption: json['caption'] as String? ?? '',
      );
}
