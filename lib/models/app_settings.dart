import 'company.dart';

/// Reglages de l'application : fiche entreprise, intervenants et listes de
/// choix rapides. Tout ce qui se trouve ici sert a eviter que l'intervenant
/// ait a retaper la meme chose sur chaque chantier.
class AppSettings {
  const AppSettings({
    this.company = const Company(),
    this.technicians = const <Technician>[],
    this.interventionTypes = const <String>[],
    this.materialPresets = const <String>[],
    this.findingPresets = const <String>[],
    this.actionPresets = const <String>[],
    this.reportNumberPrefix = '',
  });

  final Company company;
  final List<Technician> technicians;

  /// "Entretien poste de relevage", "Debouchage canalisation", ...
  final List<String> interventionTypes;

  /// Materiel coche dans l'etape "Materiel(s) mis en oeuvre".
  final List<String> materialPresets;

  /// Constats proposes en cases a cocher.
  final List<String> findingPresets;

  /// Actions proposees en cases a cocher.
  final List<String> actionPresets;

  /// Prefixe des numeros de rapport, ex. "ASE" -> ASE-120326-MB.
  final String reportNumberPrefix;

  /// Reglages livres avec l'application.
  ///
  /// L'application est distribuee en APK a l'entreprise qui l'utilise, et non
  /// par une boutique : sa fiche, ses intervenants et son prefixe de
  /// numerotation sont donc livres remplis, et le premier rapport sort
  /// complet sans rien avoir a configurer. Tout reste modifiable depuis les
  /// reglages.
  ///
  /// Le jour ou l'application serait publiee pour d'autres entreprises, c'est
  /// ici qu'il faudrait vider ces valeurs — et retirer le logo de
  /// `assets/images/`.
  static AppSettings get defaults => const AppSettings(
        company: Company(
          legalForm: 'SASU',
          name: "AU SERVICE DE L'EAU",
          addressLine: '164, Route de Lyon',
          postalCode: '01600',
          city: 'TREVOUX',
          phone: '06 50 36 50 00',
          email: 'contact@auservicedeleau.fr',
          siret: '91345781800015',
          ape: '3700Z',
          rcs: 'BOURG EN BRESSE B 913 457 818',
          vatNumber: 'FR82913457818',
          capital: '2 000,00 €',
        ),
        technicians: <Technician>[
          Technician(name: 'Thierry GROSSAT', phone: '06 50 36 50 00'),
        ],
        interventionTypes: <String>[
          'Entretien poste de relevage',
          'Débouchage canalisation',
          'Curage haute pression',
          'Vidange fosse septique',
          'Inspection caméra',
          'Recherche de fuite',
          'Intervention assainissement',
        ],
        materialPresets: <String>[
          'Camion hydrocureur',
          'Tuyaux de pompage',
          'Tuyaux de curage haute pression',
          'Pompe immergée',
          "Caméra d'inspection",
          'Furet électrique',
          'Matériel de nettoyage',
          'Équipements de protection individuelle',
        ],
        findingPresets: <String>[
          'Canalisation bouchée',
          'Fosse de relevage encrassée',
          'Pompe défectueuse',
          'Suspicion de contre-pente',
          'Fuite constatée',
          'Racines dans la canalisation',
          "Regard difficile d'accès",
        ],
        actionPresets: <String>[
          'Pompage de la fosse',
          'Nettoyage de la fosse de relevage',
          'Désengorgement par curage haute pression',
          'Débouchage des WC',
          'Contrôle du bon écoulement',
          'Remise en service de la pompe',
          'Rinçage des canalisations',
        ],
        reportNumberPrefix: 'ASE',
      );

  AppSettings copyWith({
    Company? company,
    List<Technician>? technicians,
    List<String>? interventionTypes,
    List<String>? materialPresets,
    List<String>? findingPresets,
    List<String>? actionPresets,
    String? reportNumberPrefix,
  }) {
    return AppSettings(
      company: company ?? this.company,
      technicians: technicians ?? this.technicians,
      interventionTypes: interventionTypes ?? this.interventionTypes,
      materialPresets: materialPresets ?? this.materialPresets,
      findingPresets: findingPresets ?? this.findingPresets,
      actionPresets: actionPresets ?? this.actionPresets,
      reportNumberPrefix: reportNumberPrefix ?? this.reportNumberPrefix,
    );
  }

  Map<String, dynamic> toJson() => {
        'company': company.toJson(),
        'technicians': technicians.map((t) => t.toJson()).toList(),
        'interventionTypes': interventionTypes,
        'materialPresets': materialPresets,
        'findingPresets': findingPresets,
        'actionPresets': actionPresets,
        'reportNumberPrefix': reportNumberPrefix,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        (json[key] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => e.toString())
            .toList();

    return AppSettings(
      company: Company.fromJson(
        (json['company'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      technicians: (json['technicians'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => Technician.fromJson(e as Map<String, dynamic>))
          .toList(),
      interventionTypes: strings('interventionTypes'),
      materialPresets: strings('materialPresets'),
      findingPresets: strings('findingPresets'),
      actionPresets: strings('actionPresets'),
      reportNumberPrefix: json['reportNumberPrefix'] as String? ?? '',
    );
  }
}
