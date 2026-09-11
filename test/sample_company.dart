import 'package:rapport_intervention/models/company.dart';

/// Une fiche entreprise complete, pour les tests.
///
/// L'application est livree sans entreprise : elle appartient a qui
/// l'installe. Les tests qui ont besoin d'un en-tete et d'un pied de page
/// remplis se donnent donc la leur, inventee de toutes pieces.
const Company sampleCompany = Company(
  legalForm: 'SASU',
  name: 'MARTIN ASSAINISSEMENT',
  addressLine: '12, Rue des Ateliers',
  postalCode: '01000',
  city: 'BOURG-EN-BRESSE',
  phone: '04 74 00 00 00',
  email: 'contact@martin-assainissement.fr',
  siret: '12345678900012',
  ape: '3700Z',
  rcs: 'BOURG EN BRESSE B 123 456 789',
  vatNumber: 'FR00123456789',
  capital: '5 000,00 €',
);
