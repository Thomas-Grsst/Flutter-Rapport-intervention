import 'enums.dart';
import 'photo_item.dart';

/// Un lot de photos : un point precis de l'intervention, avec son avant, son
/// pendant et son apres.
///
/// Une intervention porte souvent sur plusieurs points — le poste de relevage,
/// puis les WC. Ranger toutes les photos dans trois listes « avant »,
/// « pendant » et « apres » perdait la correspondance : impossible de savoir
/// quel « apres » repond a quel « avant ». Un lot garde ce lien, et le rapport
/// imprime chaque lot sur sa propre ligne.
///
/// Un emplacement peut rester vide : tous les points ne se photographient pas
/// aux trois moments.
class PhotoGroup {
  PhotoGroup({
    required this.id,
    this.label = '',
    List<PhotoItem>? photos,
  }) : photos = photos ?? <PhotoItem>[];

  final String id;

  /// Nom donne au lot, ex. « Poste de relevage ». Facultatif : les lots sans
  /// nom sont numerotes a l'affichage.
  String label;

  final List<PhotoItem> photos;

  List<PhotoItem> ofStage(PhotoStage stage) =>
      photos.where((photo) => photo.stage == stage).toList();

  /// Les photos de la colonne [stage], telle que l'ecran de saisie et le
  /// rapport l'affichent tous les deux.
  ///
  /// Un lot n'a que trois colonnes. Les photos sans moment — il en reste dans
  /// les rapports enregistres avant les lots — rejoignent « avant » : sinon
  /// elles s'imprimeraient dans le rapport sans apparaitre nulle part a
  /// l'ecran, impossibles a corriger ou a retirer.
  List<PhotoItem> inColumn(PhotoStage stage) => photos
      .where((photo) =>
          photo.stage == stage ||
          (stage == PhotoStage.avant && photo.stage == PhotoStage.autre))
      .toList();

  bool get isEmpty => photos.isEmpty;

  /// Nombre de photos de l'emplacement le plus rempli : c'est ce qui donne sa
  /// hauteur a la ligne du lot dans le rapport.
  int get tallestStage => PhotoStage.values
      .map((stage) => ofStage(stage).length)
      .fold(0, (a, b) => a > b ? a : b);

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'photos': photos.map((photo) => photo.toJson()).toList(),
      };

  factory PhotoGroup.fromJson(Map<String, dynamic> json) => PhotoGroup(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        photos: (json['photos'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => PhotoItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
