import 'enums.dart';

/// Un client du carnet d'adresses.
///
/// Les clients sous contrat reviennent tous les ans : les retaper a chaque
/// visite, adresse et courriel compris, fait perdre du temps et finit par
/// produire deux orthographes du meme nom dans deux rapports. Le carnet les
/// garde une fois pour toutes.
class Client {
  const Client({
    required this.id,
    this.name = '',
    this.addressLine = '',
    this.postalCode = '',
    this.city = '',
    this.phone = '',
    this.email = '',
    this.contracts = const <ReportKind>{},
  });

  final String id;
  final String name;
  final String addressLine;
  final String postalCode;
  final String city;
  final String phone;
  final String email;

  /// Les contrats de ce client. Sert a proposer d'abord les bons clients
  /// quand on cree un rapport : un contrat de poste de relevage n'amene pas
  /// les memes gens qu'un contrat de filtre compact.
  final Set<ReportKind> contracts;

  /// "1, Avenue du General Leclerc, 69480 ANSE"
  String get oneLine => [
        addressLine.trim(),
        [postalCode.trim(), city.trim()]
            .where((part) => part.isNotEmpty)
            .join(' '),
      ].where((part) => part.isNotEmpty).join(', ');

  /// Tout ce sur quoi la recherche du carnet porte.
  String get searchText =>
      [name, addressLine, postalCode, city, phone, email].join(' ');

  Client copyWith({
    String? name,
    String? addressLine,
    String? postalCode,
    String? city,
    String? phone,
    String? email,
    Set<ReportKind>? contracts,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      addressLine: addressLine ?? this.addressLine,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      contracts: contracts ?? this.contracts,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'addressLine': addressLine,
        'postalCode': postalCode,
        'city': city,
        'phone': phone,
        'email': email,
        'contracts': contracts.map((kind) => kind.name).toList(),
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        addressLine: json['addressLine'] as String? ?? '',
        postalCode: json['postalCode'] as String? ?? '',
        city: json['city'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        contracts: (json['contracts'] as List<dynamic>? ?? const <dynamic>[])
            .map((name) => ReportKind.fromName(name as String?))
            .toSet(),
      );
}
