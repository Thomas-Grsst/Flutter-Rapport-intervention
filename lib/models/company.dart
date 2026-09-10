/// Fiche de l'entreprise qui edite les rapports.
///
/// Ces informations sont saisies une seule fois dans les reglages puis
/// pre-remplies automatiquement sur chaque rapport (en-tete, pied de page,
/// bloc "Entreprise" et mention legale finale).
class Company {
  const Company({
    this.legalForm = '',
    this.name = '',
    this.addressLine = '',
    this.postalCode = '',
    this.city = '',
    this.phone = '',
    this.email = '',
    this.siret = '',
    this.ape = '',
    this.rcs = '',
    this.vatNumber = '',
    this.capital = '',
    this.logoPath,
  });

  final String legalForm;
  final String name;
  final String addressLine;
  final String postalCode;
  final String city;
  final String phone;
  final String email;

  // --- Mentions legales -----------------------------------------------------
  //
  // Imprimees en pied de chaque page du rapport, comme sur le modele papier.

  final String siret;
  final String ape;
  final String rcs;
  final String vatNumber;

  /// Capital social, ex. "2 000,00 €".
  final String capital;

  /// Chemin local du logo (copie dans le dossier de l'application).
  ///
  /// Null tant que l'utilisateur n'en a pas choisi un : le logo livre avec
  /// l'application sert alors de valeur par defaut.
  final String? logoPath;

  /// "SASU AU SERVICE DE L'EAU"
  String get displayName =>
      [legalForm, name].where((part) => part.trim().isNotEmpty).join(' ');

  /// "01600 TREVOUX"
  String get cityLine =>
      [postalCode, city].where((part) => part.trim().isNotEmpty).join(' ');

  /// "164, Route de Lyon - 01600 TREVOUX"
  String get addressOneLine =>
      [addressLine, cityLine].where((part) => part.trim().isNotEmpty).join(' - ');

  /// Coordonnees de l'entreprise, sur une ligne.
  String get contactLine {
    final parts = <String>[
      if (displayName.isNotEmpty) displayName,
      if (addressOneLine.isNotEmpty) addressOneLine,
      if (phone.isNotEmpty) 'Tél. : $phone',
      if (email.isNotEmpty) 'Mail : $email',
    ];
    return parts.join('  -  ');
  }

  /// Coordonnees de l'en-tete du rapport, une information par ligne.
  List<String> get contactLines => <String>[
        if (addressOneLine.isNotEmpty) addressOneLine,
        if (phone.isNotEmpty) 'Tél. : $phone',
        if (email.isNotEmpty) 'Mail : $email',
      ];

  /// Mentions legales imprimees en pied de chaque page.
  ///
  /// Retombe sur les coordonnees tant qu'aucune mention n'est renseignee :
  /// un pied de page vide ferait plus mauvais effet qu'une adresse repetee.
  String get legalLine {
    final parts = <String>[
      if (displayName.isNotEmpty) displayName,
      if (siret.trim().isNotEmpty) 'SIRET : ${siret.trim()}',
      if (ape.trim().isNotEmpty) 'APE : ${ape.trim()}',
      if (rcs.trim().isNotEmpty) 'RCS ${rcs.trim()}',
      if (vatNumber.trim().isNotEmpty)
        'N° TVA intracom : ${vatNumber.trim()}',
      if (capital.trim().isNotEmpty) 'Capital : ${capital.trim()}',
    ];
    return parts.length <= 1 ? contactLine : parts.join(' - ');
  }

  bool get isEmpty => name.trim().isEmpty;

  Company copyWith({
    String? legalForm,
    String? name,
    String? addressLine,
    String? postalCode,
    String? city,
    String? phone,
    String? email,
    String? siret,
    String? ape,
    String? rcs,
    String? vatNumber,
    String? capital,
    String? logoPath,
    bool clearLogo = false,
  }) {
    return Company(
      legalForm: legalForm ?? this.legalForm,
      name: name ?? this.name,
      addressLine: addressLine ?? this.addressLine,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      siret: siret ?? this.siret,
      ape: ape ?? this.ape,
      rcs: rcs ?? this.rcs,
      vatNumber: vatNumber ?? this.vatNumber,
      capital: capital ?? this.capital,
      logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
    );
  }

  Map<String, dynamic> toJson() => {
        'legalForm': legalForm,
        'name': name,
        'addressLine': addressLine,
        'postalCode': postalCode,
        'city': city,
        'phone': phone,
        'email': email,
        'siret': siret,
        'ape': ape,
        'rcs': rcs,
        'vatNumber': vatNumber,
        'capital': capital,
        'logoPath': logoPath,
      };

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      legalForm: json['legalForm'] as String? ?? '',
      name: json['name'] as String? ?? '',
      addressLine: json['addressLine'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      siret: json['siret'] as String? ?? '',
      ape: json['ape'] as String? ?? '',
      rcs: json['rcs'] as String? ?? '',
      vatNumber: json['vatNumber'] as String? ?? '',
      capital: json['capital'] as String? ?? '',
      logoPath: json['logoPath'] as String?,
    );
  }
}

/// Un intervenant enregistre dans les reglages, propose dans une liste
/// deroulante au moment de creer un rapport.
class Technician {
  const Technician({required this.name, this.phone = ''});

  final String name;
  final String phone;

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};

  factory Technician.fromJson(Map<String, dynamic> json) => Technician(
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
      );
}
