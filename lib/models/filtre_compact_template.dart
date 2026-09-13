/// Les reponses proposees pour un point de controle.
///
/// Chaque point du rapport papier a ses propres cases a cocher : « Oui / Non /
/// Sans objet » pour un nettoyage, « Conforme / A surveiller / ... » pour un
/// regard, « OK / NOK / N/A » pour les controles complementaires. Elles sont
/// reprises telles quelles, parce que c'est ce que le client lit.
class FiltreAnswers {
  const FiltreAnswers(this.choices);

  final List<String> choices;

  static const FiltreAnswers fait =
      FiltreAnswers(<String>['Oui', 'Non', 'Sans objet']);

  static const FiltreAnswers conformite = FiltreAnswers(
      <String>['Conforme', 'À surveiller', 'Non conforme', 'Non accessible']);

  static const FiltreAnswers okNok = FiltreAnswers(<String>['OK', 'NOK', 'N/A']);

  static const FiltreAnswers etatInstallation = FiltreAnswers(
      <String>['Satisfaisant', 'À surveiller', 'Intervention nécessaire']);

  static const FiltreAnswers pompe =
      FiltreAnswers(<String>['Conforme', 'Non conforme', 'Sans objet']);

  static const FiltreAnswers anomalie = FiltreAnswers(
      <String>['Non', 'Oui, précisée dans le rapport']);
}

/// Ce qu'une section demande comme photos.
enum FiltrePhotos {
  /// Un avant et un apres, cote a cote dans le rapport.
  avantApres,

  /// Une seule photo : les regards des tranchees ne se nettoient pas, ils se
  /// constatent.
  unique,

  /// Aucune : les controles complementaires tiennent dans un tableau.
  aucune,
}

/// Un point a relever dans une section.
class FiltreField {
  const FiltreField(
    this.label, {
    this.answers = FiltreAnswers.fait,
    this.hasObservations = false,
  });

  /// Intitule imprime dans le rapport, avant les deux-points.
  final String label;

  final FiltreAnswers answers;

  /// Le point porte son propre champ d'observations, a droite de sa reponse.
  final bool hasObservations;
}

/// Une section du rapport d'entretien de filtre compact.
class FiltreSection {
  const FiltreSection({
    required this.id,
    required this.title,
    this.fields = const <FiltreField>[],
    this.photos = FiltrePhotos.avantApres,
    this.hasStateBefore = true,
  });

  /// Identifiant stable, utilise comme cle dans le rapport enregistre : il ne
  /// doit jamais changer, meme si l'intitule est retouche.
  final String id;

  /// Intitule imprime en tete de la section.
  final String title;

  final List<FiltreField> fields;

  final FiltrePhotos photos;

  /// La section commence par « Etat avant intervention », en texte libre.
  final bool hasStateBefore;

  /// Cle sous laquelle l'etat avant intervention est enregistre.
  String get stateKey => '$id/etat';

  /// Cle sous laquelle la reponse de [field] est enregistree.
  String keyOf(FiltreField field) => '$id/${field.label}';

  /// Cle sous laquelle les observations de [field] sont enregistrees.
  String observationsKeyOf(FiltreField field) => '$id/${field.label}/obs';
}

/// La synthese de tete, imprimee en premiere page sous les identifiants.
///
/// Elle resume la visite avant le detail : c'est ce que le client regarde en
/// premier, et souvent la seule chose qu'il retient.
const List<FiltreField> filtreSummaryFields = <FiltreField>[
  FiltreField("État général de l'installation",
      answers: FiltreAnswers.etatInstallation),
  FiltreField('Fonctionnement de la pompe', answers: FiltreAnswers.pompe),
  FiltreField('Anomalie ou réserve', answers: FiltreAnswers.anomalie),
];

/// Cle sous laquelle une reponse de la synthese de tete est enregistree.
String filtreSummaryKey(FiltreField field) => 'synthese/${field.label}';

/// Les textes de la synthese finale, ranges eux aussi dans le releve : ils
/// n'appartiennent qu'a ce rapport, inutile d'en faire des champs a part.
const String filtreWorkKey = 'synthese/travaux';
const String filtreAnomaliesKey = 'synthese/anomalies';
const String filtreAdviceKey = 'synthese/preconisations';
const String filtreNextVisitKey = 'synthese/prochaine-visite';

/// Les douze sections du rapport, dans l'ordre ou elles s'impriment.
///
/// Ce rapport-la ne varie jamais : les memes gestes, dans le meme ordre, sur
/// le meme materiel. Le gabarit est donc ecrit en dur plutot que
/// configurable — c'est ce qui permet a l'intervenant de derouler son
/// entretien sans jamais se demander quoi remplir.
const List<FiltreSection> filtreSections = <FiltreSection>[
  FiltreSection(
    id: 'environnement',
    title: "Environnement de l'installation",
    fields: [
      FiltreField('Zone accessible et sécurisée', hasObservations: true),
    ],
  ),
  FiltreSection(
    id: 'regard-amont',
    title: 'Nettoyage du regard en amont',
    fields: [FiltreField('Nettoyage effectué', hasObservations: true)],
  ),
  FiltreSection(
    id: 'fosse',
    title: 'Nettoyage de la fosse toutes eaux',
    fields: [FiltreField('Nettoyage effectué', hasObservations: true)],
  ),
  FiltreSection(
    id: 'prefiltre',
    title: 'Nettoyage du préfiltre',
    fields: [FiltreField('Nettoyage effectué', hasObservations: true)],
  ),
  FiltreSection(
    id: 'auget',
    title: "Nettoyage de l'auget du média filtrant",
    fields: [FiltreField('Nettoyage effectué', hasObservations: true)],
  ),
  FiltreSection(
    id: 'grille',
    title: 'Nettoyage de la grille de répartition',
    fields: [FiltreField('Nettoyage effectué', hasObservations: true)],
  ),
  FiltreSection(
    id: 'pompe',
    title: 'Nettoyage de la pompe de relevage',
    fields: [FiltreField('Nettoyage effectué', hasObservations: true)],
  ),
  FiltreSection(
    id: 'scarification',
    title: 'Scarification du média filtrant',
    fields: [FiltreField('Scarification effectuée', hasObservations: true)],
  ),
  FiltreSection(
    id: 'event',
    title: "Nettoyage de l'évent du média filtrant",
    fields: [FiltreField('Nettoyage effectué', hasObservations: true)],
  ),
  FiltreSection(
    id: 'regard-repartition',
    title: 'Vérification du regard de répartition des tranchées',
    fields: [
      FiltreField(
        'Écoulement et répartition',
        answers: FiltreAnswers.conformite,
        hasObservations: true,
      ),
    ],
    photos: FiltrePhotos.unique,
    hasStateBefore: false,
  ),
  FiltreSection(
    id: 'regard-bouclage',
    title: 'Vérification du regard de bouclage des tranchées',
    fields: [
      FiltreField(
        'Écoulement et absence de mise en charge',
        answers: FiltreAnswers.conformite,
        hasObservations: true,
      ),
    ],
    photos: FiltrePhotos.unique,
    hasStateBefore: false,
  ),
  FiltreSection(
    id: 'controles',
    title: 'Contrôles complémentaires',
    fields: [
      FiltreField('Niveau des boues de la fosse',
          answers: FiltreAnswers.okNok, hasObservations: true),
      FiltreField('Écoulement hydraulique général',
          answers: FiltreAnswers.okNok, hasObservations: true),
      FiltreField('Fonctionnement de la pompe et des flotteurs',
          answers: FiltreAnswers.okNok, hasObservations: true),
      FiltreField('État des couvercles et accès',
          answers: FiltreAnswers.okNok, hasObservations: true),
      FiltreField("Absence d'alarme ou de défaut visible",
          answers: FiltreAnswers.okNok, hasObservations: true),
    ],
    photos: FiltrePhotos.aucune,
    hasStateBefore: false,
  ),
];
