import 'enums.dart';
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
    this.reportNumber = '',
    this.reference = '',
    this.interventionType = '',
    DateTime? interventionDate,
    this.startTime = '',
    this.endTime = '',
    this.clientName = '',
    this.clientAddressLine = '',
    this.clientPostalCode = '',
    this.clientCity = '',
    this.siteAddressLine = '',
    this.sitePostalCode = '',
    this.siteCity = '',
    this.siteLocation = '',
    this.siteContact = '',
    this.technicianName = '',
    this.technicianPhone = '',
    this.observations = '',
    this.accessConstraints = '',
    List<String>? materials,
    this.occupant = '',
    List<String>? findingTags,
    this.findings = '',
    List<String>? actions,
    List<PhotoItem>? photos,
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
        materials = materials ?? <String>[],
        findingTags = findingTags ?? <String>[],
        actions = actions ?? <String>[],
        photos = photos ?? <PhotoItem>[];

  final String id;
  final DateTime createdAt;
  DateTime updatedAt;

  // --- Identification -------------------------------------------------------
  String reportNumber;
  String reference;
  String interventionType;
  DateTime interventionDate;
  String startTime;
  String endTime;

  // --- Client ---------------------------------------------------------------
  String clientName;
  String clientAddressLine;
  String clientPostalCode;
  String clientCity;

  // --- Adresse d'intervention ----------------------------------------------
  String siteAddressLine;
  String sitePostalCode;
  String siteCity;
  String siteLocation;
  String siteContact;

  // --- Intervenant ----------------------------------------------------------
  String technicianName;
  String technicianPhone;

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
  List<PhotoItem> photos;

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

  String get displayTitle => interventionType.trim().isNotEmpty
      ? interventionType.trim()
      : 'Rapport sans intitule';

  String get displayClient =>
      clientName.trim().isNotEmpty ? clientName.trim() : 'Client non renseigne';

  String get clientCityLine => _cityLine(clientPostalCode, clientCity);

  String get siteCityLine => _cityLine(sitePostalCode, siteCity);

  /// Adresse du chantier sur une ligne, utilisee dans la liste des rapports.
  String get siteOneLine => [siteAddressLine, siteCityLine]
      .where((part) => part.trim().isNotEmpty)
      .join(', ');

  List<PhotoItem> photosOfStage(PhotoStage stage) =>
      photos.where((photo) => photo.stage == stage).toList();

  /// Sections encore vides, affichees comme rappel avant de generer le PDF.
  List<String> get missingSections {
    final missing = <String>[];
    if (clientName.trim().isEmpty) missing.add('Nom du client');
    if (siteAddressLine.trim().isEmpty) missing.add("Adresse d'intervention");
    if (interventionType.trim().isEmpty) missing.add("Type d'intervention");
    if (technicianName.trim().isEmpty) missing.add('Intervenant');
    if (findings.trim().isEmpty && findingTags.isEmpty && actions.isEmpty) {
      missing.add('Constats et actions');
    }
    if (conclusions.trim().isEmpty) missing.add('Conclusions');
    return missing;
  }

  bool get isReadyToExport => missingSections.isEmpty;

  static String _cityLine(String postalCode, String city) =>
      [postalCode, city].where((part) => part.trim().isNotEmpty).join(' ');

  // --- Serialisation --------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'reportNumber': reportNumber,
        'reference': reference,
        'interventionType': interventionType,
        'interventionDate': interventionDate.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'clientName': clientName,
        'clientAddressLine': clientAddressLine,
        'clientPostalCode': clientPostalCode,
        'clientCity': clientCity,
        'siteAddressLine': siteAddressLine,
        'sitePostalCode': sitePostalCode,
        'siteCity': siteCity,
        'siteLocation': siteLocation,
        'siteContact': siteContact,
        'technicianName': technicianName,
        'technicianPhone': technicianPhone,
        'observations': observations,
        'accessConstraints': accessConstraints,
        'materials': materials,
        'occupant': occupant,
        'findingTags': findingTags,
        'findings': findings,
        'actions': actions,
        'photos': photos.map((photo) => photo.toJson()).toList(),
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

    return Report(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      reportNumber: json['reportNumber'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      interventionType: json['interventionType'] as String? ?? '',
      interventionDate: DateTime.parse(json['interventionDate'] as String),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      clientAddressLine: json['clientAddressLine'] as String? ?? '',
      clientPostalCode: json['clientPostalCode'] as String? ?? '',
      clientCity: json['clientCity'] as String? ?? '',
      siteAddressLine: json['siteAddressLine'] as String? ?? '',
      sitePostalCode: json['sitePostalCode'] as String? ?? '',
      siteCity: json['siteCity'] as String? ?? '',
      siteLocation: json['siteLocation'] as String? ?? '',
      siteContact: json['siteContact'] as String? ?? '',
      technicianName: json['technicianName'] as String? ?? '',
      technicianPhone: json['technicianPhone'] as String? ?? '',
      observations: json['observations'] as String? ?? '',
      accessConstraints: json['accessConstraints'] as String? ?? '',
      materials: strings('materials'),
      occupant: json['occupant'] as String? ?? '',
      findingTags: strings('findingTags'),
      findings: json['findings'] as String? ?? '',
      actions: strings('actions'),
      photos: (json['photos'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => PhotoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
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
