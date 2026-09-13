import 'company.dart';
import 'enums.dart';
import 'photo_group.dart';
import 'photo_item.dart';

/// Un rapport d'intervention.
///
/// La structure suit section par section le rapport Word de reference :
/// page de garde, adresse d'intervention / entreprise / client, observations,
/// materiel, constats et actions, photographies, conclusions, points restants,
/// recapitulatif d'intervention et evaluation du client.
///
/// Les champs sont mutables : un rapport est un brouillon que l'intervenant
/// remplit progressivement sur le chantier, souvent en plusieurs fois.
class Report {
  Report({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.kind = ReportKind.intervention,
    this.reportNumber = '',
    this.reference = '',
    this.interventionType = '',
    DateTime? interventionDate,
    this.interventionEndDate,
    this.startTime = '',
    this.endTime = '',
    this.clientName = '',
    this.clientAddressLine = '',
    this.clientPostalCode = '',
    this.clientCity = '',
    this.clientPhone = '',
    this.clientEmail = '',
    this.contractDate,
    this.equipmentBrand = '',
    this.equipmentType = '',
    this.serialNumber = '',
    this.lastMaintenanceDate,
    Map<String, String>? checklist,
    this.siteAddressLine = '',
    this.sitePostalCode = '',
    this.siteCity = '',
    this.siteLocation = '',
    this.siteContact = '',
    List<Technician>? technicians,
    this.observations = '',
    this.accessConstraints = '',
    List<String>? materials,
    this.occupant = '',
    List<String>? findingTags,
    this.findings = '',
    List<String>? actions,
    List<PhotoGroup>? photoGroups,
    this.status = ReportStatus.brouillon,
    this.conclusions = '',
    this.remainingPoints = '',
    this.interventionLabel = '',
    this.documentsToTransmit = '',
    this.clientEvaluation = '',
    this.clientSignaturePath,
    this.technicianSignaturePath,
    this.lastPdfPath,
  })  : interventionDate = interventionDate ?? DateTime.now(),
        technicians = technicians ?? <Technician>[],
        materials = materials ?? <String>[],
        findingTags = findingTags ?? <String>[],
        actions = actions ?? <String>[],
        checklist = checklist ?? <String, String>{},
        photoGroups = photoGroups ?? <PhotoGroup>[];

  final String id;
  final DateTime createdAt;
  DateTime updatedAt;

  /// Ce que le rapport raconte : une intervention ponctuelle, ou l'entretien
  /// d'un poste de relevage. Chaque sorte a son assistant et son PDF.
  final ReportKind kind;

  // --- Identification -------------------------------------------------------
  String reportNumber;
  String reference;
  String interventionType;
  DateTime interventionDate;

  /// Dernier jour, quand l'intervention s'etale sur plusieurs jours.
  /// Null pour une intervention d'une seule journee, le cas courant.
  DateTime? interventionEndDate;

  String startTime;
  String endTime;

  // --- Client ---------------------------------------------------------------
  String clientName;
  String clientAddressLine;
  String clientPostalCode;
  String clientCity;
  String clientPhone;
  String clientEmail;

  // --- Entretiens sous contrat ----------------------------------------------
  //
  // Renseignes seulement sur un rapport d'entretien — poste de relevage ou
  // filtre compact.

  /// Date du contrat de maintenance.
  DateTime? contractDate;

  /// Numero de serie de l'installation, releve sur sa plaque.
  String serialNumber;

  /// Date du dernier entretien, telle qu'elle figure au contrat.
  DateTime? lastMaintenanceDate;

  String equipmentBrand;
  String equipmentType;

  /// Les etats releves, section par section, ranges sous les cles du gabarit
  /// (voir RelevageSection.keyOf). Le texte libre des observations y figure
  /// sous la cle de sa section.
  Map<String, String> checklist;

  // --- Adresse d'intervention ----------------------------------------------
  String siteAddressLine;
  String sitePostalCode;
  String siteCity;
  String siteLocation;
  String siteContact;

  // --- Intervenants ---------------------------------------------------------

  /// Les personnes intervenues sur le chantier. Une intervention se fait
  /// souvent a deux, et le rapport doit toutes les nommer.
  List<Technician> technicians;

  // --- Contenu du rapport ---------------------------------------------------
  String observations;
  String accessConstraints;
  List<String> materials;
  String occupant;

  /// Constats cochés dans la liste rapide, imprimés en puces sous « Constat ».
  List<String> findingTags;

  /// Constat rédigé librement, imprimé sous les puces.
  String findings;

  List<String> actions;

  /// Les photos, rangees par lot : un lot par point de l'intervention.
  List<PhotoGroup> photoGroups;

  // --- Conclusions ----------------------------------------------------------
  ReportStatus status;
  String conclusions;
  String remainingPoints;
  String interventionLabel;
  String documentsToTransmit;

  // --- Validation -----------------------------------------------------------
  String clientEvaluation;
  String? clientSignaturePath;
  String? technicianSignaturePath;

  /// Chemin du dernier PDF genere, pour le repartager sans le regenerer.
  String? lastPdfPath;

  // --- Champs derives -------------------------------------------------------

  String get displayTitle {
    if (interventionType.trim().isNotEmpty) return interventionType.trim();
    if (kind == ReportKind.filtreCompact) {
      final filtre = [equipmentBrand.trim(), equipmentType.trim()]
          .where((part) => part.isNotEmpty)
          .join(' ');
      return filtre.isEmpty ? 'Entretien filtre compact' : filtre;
    }
    if (kind == ReportKind.posteRelevage) {
      final poste = [equipmentBrand.trim(), equipmentType.trim()]
          .where((part) => part.isNotEmpty)
          .join(' ');
      return poste.isEmpty ? 'Entretien poste de relevage' : poste;
    }
    return 'Rapport sans intitule';
  }

  String get displayClient =>
      clientName.trim().isNotEmpty ? clientName.trim() : 'Client non renseigne';

  /// "Thierry GROSSAT et Marc DUPONT"
  String get techniciansLine {
    final names = technicians
        .map((technician) => technician.name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.length <= 1) return names.join();
    return '${names.sublist(0, names.length - 1).join(', ')} et ${names.last}';
  }

  bool get isMultiDay =>
      interventionEndDate != null &&
      !_isSameDay(interventionEndDate!, interventionDate);

  String get clientCityLine => _cityLine(clientPostalCode, clientCity);

  String get siteCityLine => _cityLine(sitePostalCode, siteCity);

  /// Adresse du chantier sur une ligne, utilisee dans la liste des rapports.
  String get siteOneLine => [siteAddressLine, siteCityLine]
      .where((part) => part.trim().isNotEmpty)
      .join(', ');

  /// Toutes les photos du rapport, lot par lot et dans l'ordre.
  ///
  /// Non modifiable : une photo s'ajoute ou se retire dans son lot. Y écrire
  /// directement ne toucherait qu'une copie, sans que rien ne le signale.
  List<PhotoItem> get photos => List.unmodifiable(
        [for (final group in photoGroups) ...group.photos],
      );

  List<PhotoItem> photosOfStage(PhotoStage stage) =>
      photos.where((photo) => photo.stage == stage).toList();

  /// Les lots qui contiennent au moins une photo.
  List<PhotoGroup> get filledPhotoGroups =>
      photoGroups.where((group) => !group.isEmpty).toList();

  // --- Poste de relevage ----------------------------------------------------

  /// L'etat releve pour un champ du gabarit, vide tant qu'il n'a rien recu.
  String checklistValue(String key) => checklist[key]?.trim() ?? '';

  void setChecklistValue(String key, String value) {
    if (value.trim().isEmpty) {
      checklist.remove(key);
    } else {
      checklist[key] = value.trim();
    }
  }

  /// Le lot de photos d'une section du gabarit, cree au besoin.
  ///
  /// Les sections reutilisent les lots de photos, avec l'identifiant de la
  /// section comme identifiant de lot : le rapport de poste de relevage n'a
  /// donc pas de rangement a lui.
  PhotoGroup photoGroupFor(String sectionId, {required String title}) {
    for (final group in photoGroups) {
      if (group.id == sectionId) return group;
    }
    final group = PhotoGroup(id: sectionId, label: title);
    photoGroups.add(group);
    return group;
  }

  /// Sections encore vides, affichees comme rappel avant de generer le PDF.
  List<String> get missingSections {
    final missing = <String>[];
    if (clientName.trim().isEmpty) missing.add('Nom du client');

    if (kind == ReportKind.posteRelevage) {
      if (clientAddressLine.trim().isEmpty) missing.add('Adresse du client');
      if (equipmentType.trim().isEmpty) missing.add('Type de poste');
      if (techniciansLine.isEmpty) missing.add('Intervenant');
      if (checklist.isEmpty) missing.add('États relevés');
      if (photos.isEmpty) missing.add('Photos');
      return missing;
    }

    if (kind == ReportKind.filtreCompact) {
      if (clientAddressLine.trim().isEmpty) missing.add('Adresse du client');
      if (techniciansLine.isEmpty) missing.add('Intervenant');
      if (checklist.isEmpty) missing.add('Points relevés');
      if (photos.isEmpty) missing.add('Photos');
      return missing;
    }

    if (siteAddressLine.trim().isEmpty) missing.add("Adresse d'intervention");
    if (interventionType.trim().isEmpty) missing.add("Type d'intervention");
    if (techniciansLine.isEmpty) missing.add('Intervenant');
    if (findings.trim().isEmpty && findingTags.isEmpty && actions.isEmpty) {
      missing.add('Constats et actions');
    }
    if (conclusions.trim().isEmpty) missing.add('Conclusions');
    return missing;
  }

  bool get isReadyToExport => missingSections.isEmpty;

  static String _cityLine(String postalCode, String city) =>
      [postalCode, city].where((part) => part.trim().isNotEmpty).join(' ');

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // --- Serialisation --------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'reportNumber': reportNumber,
        'reference': reference,
        'interventionType': interventionType,
        'interventionDate': interventionDate.toIso8601String(),
        'interventionEndDate': interventionEndDate?.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'clientName': clientName,
        'clientAddressLine': clientAddressLine,
        'clientPostalCode': clientPostalCode,
        'clientCity': clientCity,
        'clientPhone': clientPhone,
        'clientEmail': clientEmail,
        'kind': kind.name,
        'contractDate': contractDate?.toIso8601String(),
        'equipmentBrand': equipmentBrand,
        'equipmentType': equipmentType,
        'serialNumber': serialNumber,
        'lastMaintenanceDate': lastMaintenanceDate?.toIso8601String(),
        'checklist': checklist,
        'siteAddressLine': siteAddressLine,
        'sitePostalCode': sitePostalCode,
        'siteCity': siteCity,
        'siteLocation': siteLocation,
        'siteContact': siteContact,
        'technicians': technicians.map((t) => t.toJson()).toList(),
        'observations': observations,
        'accessConstraints': accessConstraints,
        'materials': materials,
        'occupant': occupant,
        'findingTags': findingTags,
        'findings': findings,
        'actions': actions,
        'photoGroups': photoGroups.map((group) => group.toJson()).toList(),
        'status': status.name,
        'conclusions': conclusions,
        'remainingPoints': remainingPoints,
        'interventionLabel': interventionLabel,
        'documentsToTransmit': documentsToTransmit,
        'clientEvaluation': clientEvaluation,
        'clientSignaturePath': clientSignaturePath,
        'technicianSignaturePath': technicianSignaturePath,
        'lastPdfPath': lastPdfPath,
      };

  factory Report.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        (json[key] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => e.toString())
            .toList();

    // Les rapports enregistres avant les lots rangeaient leurs photos a plat :
    // on les regroupe en un lot unique plutot que de les perdre.
    final photoGroups = json.containsKey('photoGroups')
        ? (json['photoGroups'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => PhotoGroup.fromJson(e as Map<String, dynamic>))
            .toList()
        : <PhotoGroup>[
            for (final legacy in <List<PhotoItem>>[
              (json['photos'] as List<dynamic>? ?? const <dynamic>[])
                  .map((e) => PhotoItem.fromJson(e as Map<String, dynamic>))
                  .toList(),
            ])
              if (legacy.isNotEmpty)
                PhotoGroup(id: '${json['id']}-lot-1', photos: legacy),
          ];

    // Les rapports enregistres avant la saisie de plusieurs intervenants
    // portaient un seul nom : on le relit pour ne perdre aucun rapport deja
    // sur le telephone.
    final technicians = json.containsKey('technicians')
        ? (json['technicians'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => Technician.fromJson(e as Map<String, dynamic>))
            .toList()
        : <Technician>[
            if ((json['technicianName'] as String? ?? '').trim().isNotEmpty)
              Technician(
                name: json['technicianName'] as String,
                phone: json['technicianPhone'] as String? ?? '',
              ),
          ];

    return Report(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      reportNumber: json['reportNumber'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      interventionType: json['interventionType'] as String? ?? '',
      interventionDate: DateTime.parse(json['interventionDate'] as String),
      interventionEndDate: json['interventionEndDate'] == null
          ? null
          : DateTime.parse(json['interventionEndDate'] as String),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      clientAddressLine: json['clientAddressLine'] as String? ?? '',
      clientPostalCode: json['clientPostalCode'] as String? ?? '',
      clientCity: json['clientCity'] as String? ?? '',
      clientPhone: json['clientPhone'] as String? ?? '',
      clientEmail: json['clientEmail'] as String? ?? '',
      kind: ReportKind.fromName(json['kind'] as String?),
      contractDate: json['contractDate'] == null
          ? null
          : DateTime.parse(json['contractDate'] as String),
      equipmentBrand: json['equipmentBrand'] as String? ?? '',
      equipmentType: json['equipmentType'] as String? ?? '',
      serialNumber: json['serialNumber'] as String? ?? '',
      lastMaintenanceDate: json['lastMaintenanceDate'] == null
          ? null
          : DateTime.parse(json['lastMaintenanceDate'] as String),
      checklist: (json['checklist'] as Map<String, dynamic>? ??
              const <String, dynamic>{})
          .map((key, value) => MapEntry(key, value.toString())),
      siteAddressLine: json['siteAddressLine'] as String? ?? '',
      sitePostalCode: json['sitePostalCode'] as String? ?? '',
      siteCity: json['siteCity'] as String? ?? '',
      siteLocation: json['siteLocation'] as String? ?? '',
      siteContact: json['siteContact'] as String? ?? '',
      technicians: technicians,
      observations: json['observations'] as String? ?? '',
      accessConstraints: json['accessConstraints'] as String? ?? '',
      materials: strings('materials'),
      occupant: json['occupant'] as String? ?? '',
      findingTags: strings('findingTags'),
      findings: json['findings'] as String? ?? '',
      actions: strings('actions'),
      photoGroups: photoGroups,
      status: ReportStatus.fromName(json['status'] as String?),
      conclusions: json['conclusions'] as String? ?? '',
      remainingPoints: json['remainingPoints'] as String? ?? '',
      interventionLabel: json['interventionLabel'] as String? ?? '',
      documentsToTransmit: json['documentsToTransmit'] as String? ?? '',
      clientEvaluation: json['clientEvaluation'] as String? ?? '',
      clientSignaturePath: json['clientSignaturePath'] as String?,
      technicianSignaturePath: json['technicianSignaturePath'] as String?,
      lastPdfPath: json['lastPdfPath'] as String?,
    );
  }

  /// Copie profonde, utilisee par l'assistant de saisie pour pouvoir annuler
  /// les modifications sans toucher au rapport enregistre.
  Report clone() => Report.fromJson(toJson());
}
