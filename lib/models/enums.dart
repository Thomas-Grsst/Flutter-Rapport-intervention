/// Les sortes de rapports que l'application produit.
///
/// Elles ne se remplissent pas de la meme facon : l'intervention est libre —
/// on decrit ce qu'on a trouve et ce qu'on a fait —, tandis que les deux
/// entretiens sous contrat suivent un controle immuable, section par section.
enum ReportKind {
  intervention("Rapport d'intervention", 'Intervention'),
  posteRelevage(
    "Rapport d'entretien",
    'Entretien poste de relevage',
  ),
  filtreCompact(
    "Rapport d'entretien",
    'Entretien filtre compact',
  );

  const ReportKind(this.documentTitle, this.label);

  /// Titre du document imprime.
  final String documentTitle;

  /// Intitule propose dans l'application.
  final String label;

  static ReportKind fromName(String? name) => ReportKind.values.firstWhere(
        (kind) => kind.name == name,
        orElse: () => ReportKind.intervention,
      );
}

/// Statut d'avancement d'un rapport, tel qu'il apparait dans la section
/// "Conclusions" du rapport papier (TERMINE / A SUIVRE / ...).
enum ReportStatus {
  brouillon('BROUILLON'),
  enCours('EN COURS'),
  aSuivre('À SUIVRE'),
  termine('TERMINÉ');

  const ReportStatus(this.label);

  /// Libelle affiche dans l'application et imprime dans le PDF.
  final String label;

  static ReportStatus fromName(String? name) {
    return ReportStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => ReportStatus.brouillon,
    );
  }
}

/// Moment de prise de vue d'une photo. Le rapport papier regroupe toutes les
/// photos dans une seule section, mais l'intervenant a besoin de les qualifier
/// au moment de la prise de vue.
enum PhotoStage {
  avant('Avant'),
  pendant('Pendant'),
  apres('Après'),
  autre('Autre');

  const PhotoStage(this.label);

  final String label;

  static PhotoStage fromName(String? name) {
    return PhotoStage.values.firstWhere(
      (stage) => stage.name == name,
      orElse: () => PhotoStage.autre,
    );
  }
}
