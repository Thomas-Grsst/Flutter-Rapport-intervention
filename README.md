# Rapport d'intervention

Application mobile Flutter qui permet à un intervenant de saisir un rapport
d'intervention depuis son téléphone, sur le chantier, et d'en générer le PDF
mis en page — sans passer par Word.

Le PDF produit reprend la structure du modèle papier de référence : page de
garde, blocs client / entreprise / adresse d'intervention, observations,
matériel mis en œuvre, constats et actions, photographies, conclusions,
points restants, récapitulatif d'intervention, évaluation du client et
signatures.

## Le principe

L'intervenant ne remplit pas un document : il répond à une série de questions
courtes, réparties en sept étapes.

| Étape | Ce qu'on demande |
|---|---|
| 1. Le chantier | Client, adresse d'intervention, localisation, type d'intervention, date, intervenant |
| 2. Observations | Contexte de l'intervention et contraintes d'accès |
| 3. Matériel | Cases à cocher (camion hydrocureur, tuyaux, caméra…) |
| 4. Constats et actions | Constats cochés + précisions libres, actions cochées |
| 5. Photos | Avant / pendant / après, avec légende |
| 6. Conclusion | Statut, conclusion, points restants, horaires |
| 7. Validation | Évaluation du client et signatures tactiles |

L'application se charge ensuite de la mise en page, du logo, des coordonnées,
du pied de page et de la pagination.

## Fonctionnalités

- **Saisie guidée** en sept étapes, enregistrée automatiquement à chaque
  changement d'étape : un rapport peut être commencé sur le chantier et
  terminé plus tard.
- **Cases à cocher configurables** pour le matériel, les constats et les
  actions. Une saisie libre (« Autre… ») est mémorisée et proposée sur les
  rapports suivants.
- **Proposition de conclusion** composée à partir du type d'intervention, des
  constats et des actions. Le texte reste entièrement modifiable.
- **Photos** prises depuis l'appareil ou choisies dans la galerie, classées en
  avant / pendant / après, redimensionnées à l'import pour que le PDF reste
  envoyable en 4G.
- **Signatures tactiles** de l'intervenant et du client.
- **Numérotation automatique** des rapports (`ASE-120326-MB`).
- **Export PDF** : aperçu, impression, et envoi au client par e-mail, SMS ou
  messagerie.
- **Recherche et filtres** par client, adresse, numéro de rapport et statut
  (en cours / à suivre / terminés).
- **Fiche entreprise** (nom, adresse, téléphone, e-mail, logo) et liste des
  intervenants saisies une seule fois, puis pré-remplies sur chaque rapport.
- **100 % hors ligne** : tout est stocké sur le téléphone, aucun compte ni
  connexion n'est nécessaire sur un chantier.

## Démarrage

```bash
git clone https://github.com/Thomas-Grsst/Flutter-Rapport-intervention.git
cd Flutter-Rapport-intervention
flutter pub get
flutter run
```

Android et iOS sont configurés, permissions caméra et galerie comprises.

Développé et vérifié avec Flutter 3.47.3 / Dart 3.13.3. La plateforme visée
est le mobile : `path_provider` n'ayant pas d'implémentation web, l'application
ne tourne pas dans un navigateur.

### Vérifications

```bash
flutter analyze
flutter test
```

## Organisation du code

```
lib/
├── main.dart                  Point d'entrée, injection des dépendances
├── app.dart                   MaterialApp, chargement initial
├── theme.dart                 Charte graphique (bleu #104C7E / #8FB8E8)
├── models/                    Report, PhotoItem, Company, AppSettings
├── services/
│   ├── storage_service.dart   Fichiers JSON, photos, signatures, PDF
│   └── pdf_service.dart       Génération du PDF mis en page
├── state/                     ReportsProvider, SettingsProvider
├── screens/
│   ├── home_screen.dart       Liste, recherche, filtres
│   ├── report_wizard_screen.dart   Assistant de saisie
│   ├── report_detail_screen.dart   Fiche et export PDF
│   ├── settings_screen.dart   Entreprise, intervenants, listes
│   └── steps/                 Les sept étapes de l'assistant
└── widgets/                   Composants réutilisables
```

### Stockage

Les données sont enregistrées dans le dossier documents de l'application :

- `reports.json` — les rapports (écriture atomique)
- `settings.json` — la fiche entreprise et les listes de choix
- `media/` — photos, logo et signatures
- `rapports/` — les PDF générés

## Personnalisation

Les valeurs livrées par défaut (entreprise, intervenant, types
d'intervention, matériel, constats, actions) sont définies dans
`AppSettings.defaults`, dans [`lib/models/app_settings.dart`](lib/models/app_settings.dart).
Elles servent de point de départ et sont toutes modifiables depuis l'écran
Réglages de l'application.
