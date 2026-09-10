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
    this.logoPath,
  });

  final String legalForm;
  final String name;
  final String addressLine;
  final String postalCode;
  final String city;
  final String phone;
  final String email;

  /// Chemin local du logo (copie dans le dossier de l'application).
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

  /// Ligne affichee en pied de chaque page du PDF.
  String get footerLine {
    final parts = <String>[
      if (displayName.isNotEmpty) displayName,
      if (addressOneLine.isNotEmpty) addressOneLine,
      if (phone.isNotEmpty) 'Tel. : $phone',
      if (email.isNotEmpty) 'Mail : $email',
    ];
    return parts.join('  -  ');
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
