/// Les reponses proposees pour un point de controle.
enum RelevageAnswers {
  /// Les trois etats d'un equipement.
  etat(<String>['Excellent', 'Correct', 'À remplacer']),

  /// Une question fermee, comme l'alarme avant entretien.
  ouiNon(<String>['Oui', 'Non']);

  const RelevageAnswers(this.choices);

  /// Les reponses proposees d'un geste. Le champ reste libre a cote : un etat
  /// reel ne tient pas toujours dans une case.
  final List<String> choices;
}

/// Un point de controle d'une section : ce qu'on releve, et sous quelle forme.
class RelevageField {
  const RelevageField(this.label, {this.answers = RelevageAnswers.etat});

  /// Intitule imprime dans le rapport, avant les deux-points.
  final String label;

  final RelevageAnswers answers;
}

/// Le gabarit du rapport d'entretien de poste de relevage.
///
/// Ce rapport-la ne varie jamais : les memes sections, dans le meme ordre,
/// avec les memes intitules. Seuls changent le client, le lieu, les etats
/// releves et les photos. Le gabarit est donc ecrit en dur ici plutot que
/// configurable — c'est ce qui permet a l'intervenant de derouler son
/// controle sans jamais se demander quoi remplir.
class RelevageSection {
  const RelevageSection({
    required this.id,
    required this.title,
    this.fields = const <RelevageField>[],
    this.hasFreeText = false,
    this.hasPhotos = true,
  });

  /// Identifiant stable, utilise comme cle dans le rapport enregistre : il ne
  /// doit jamais changer, meme si l'intitule est retouche.
  final String id;

  /// Intitule imprime dans le bandeau bleu de la section.
  final String title;

  /// Les points a relever, dans l'ordre du rapport papier.
  final List<RelevageField> fields;

  /// Section a texte libre plutot qu'a etats : les observations.
  final bool hasFreeText;

  final bool hasPhotos;

  /// Cle sous laquelle l'etat de [field] est enregistre dans le rapport.
  String keyOf(RelevageField field) => '$id/${field.label}';
}

/// Les huit sections du rapport, dans l'ordre ou elles s'impriment.
const List<RelevageSection> relevageSections = <RelevageSection>[
  RelevageSection(id: 'environnement', title: 'Environnement'),
  RelevageSection(
    id: 'cuve',
    title: 'Cuve',
    fields: [RelevageField('Etat général avant nettoyage')],
  ),
  RelevageSection(
    id: 'clapet',
    title: 'Clapet anti-retour',
    fields: [
      RelevageField('Etat général avant nettoyage'),
      RelevageField('Fonctionnement'),
    ],
  ),
  RelevageSection(
    id: 'flotteurs',
    title: 'Flotteurs ou poires de commande',
    fields: [
      RelevageField('Etat général avant nettoyage'),
      RelevageField('Fonctionnement'),
    ],
  ),
  RelevageSection(
    id: 'pompes',
    title: 'Pompe(s)',
    fields: [
      RelevageField('Etat général avant nettoyage'),
      RelevageField('Fonctionnement'),
      RelevageField('Etat extérieur'),
      RelevageField('Hydraulique'),
    ],
  ),
  RelevageSection(
    id: 'coffret',
    title: 'Coffret ou armoire électrique',
    fields: [
      RelevageField('Etat général'),
      RelevageField('Voyants'),
      RelevageField('Presse-étoupe'),
      RelevageField('Alarme avant entretien', answers: RelevageAnswers.ouiNon),
    ],
  ),
  RelevageSection(id: 'exutoire', title: 'Exutoire'),
  RelevageSection(
    id: 'observations',
    title: 'Observations',
    hasFreeText: true,
    hasPhotos: false,
  ),
];
