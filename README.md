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
| 1. Le chantier | Client, adresse d'intervention, localisation, type d'intervention, dates, intervenants |
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
- **Plusieurs intervenants** par rapport : on coche ceux qui étaient sur le
  chantier, et on ajoute un renfort au passage s'il n'est pas dans la liste.
- **Interventions sur plusieurs jours** : une date de fin facultative, imprimée
  en « Du … au … » sur le rapport.
- **En-tête et pied de page** repris du modèle papier : logo et coordonnées de
  l'entreprise en haut de chaque page, mentions légales (SIRET, APE, RCS, TVA,
  capital) en bas.
- **Numérotation automatique** des rapports (`ASE-120326-MB`).
- **Export PDF** : aperçu, impression, et envoi au client par e-mail, SMS ou
  messagerie.
- **Recherche et filtres** par client, adresse, numéro de rapport et statut
  (en cours / à suivre / terminés).
- **Fiche entreprise** (nom, adresse, téléphone, e-mail, mentions légales,
  logo) et liste des intervenants saisies une seule fois, puis pré-remplies sur
  chaque rapport.
- **100 % hors ligne** : tout est stocké sur l'appareil, aucun compte ni
  connexion n'est nécessaire sur un chantier. La police du PDF est embarquée,
  rien n'est téléchargé au moment de générer un rapport.

## Démarrage

```bash
git clone https://github.com/Thomas-Grsst/Flutter-Rapport-intervention.git
cd Flutter-Rapport-intervention
flutter pub get
```

Sur un téléphone ou un émulateur — c'est la cible de l'application, avec
l'appareil photo et les signatures au doigt :

```bash
flutter run
```

Dans un navigateur, pour la montrer sans rien installer :

```bash
flutter run -d chrome
```

Android et iOS sont configurés, permissions caméra et galerie comprises.
Développé et vérifié avec Flutter 3.47.3 / Dart 3.13.3.

### Vérifications

```bash
flutter analyze
flutter test
```

### Version web

L'application vise le mobile, mais elle tourne aussi dans un navigateur pour
pouvoir être essayée sans téléphone. Le dossier documents y est remplacé par
le stockage local du navigateur (voir
[`lib/services/storage_service.dart`](lib/services/storage_service.dart)) ;
tout le reste — assistant, photos, signatures, PDF — est identique.

Deux limites propres au navigateur : le stockage local est plafonné à quelques
mégaoctets, et les données restent attachées au navigateur utilisé. Pour un
usage réel sur le terrain, c'est la version mobile qu'il faut installer.

```bash
flutter build web --release --no-web-resources-cdn
```

`--no-web-resources-cdn` embarque le moteur de rendu dans le build au lieu de
le charger depuis un CDN : la page s'ouvre alors même sans connexion.

## Organisation du code

```
lib/
├── main.dart                  Point d'entrée, injection des dépendances
├── app.dart                   MaterialApp, chargement initial
├── theme.dart                 Charte graphique (bleu #104C7E / #8FB8E8)
├── models/                    Report, PhotoItem, Company, AppSettings
├── services/
│   ├── storage_service.dart      Interface de stockage
│   ├── storage_service_io.dart   Fichiers, sur téléphone
│   ├── storage_service_web.dart  Stockage du navigateur
│   └── pdf_service.dart          Génération du PDF mis en page
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

Dans un navigateur, ces mêmes entrées sont enregistrées dans le stockage local
plutôt que sur disque : les écrans manipulent des chemins sans savoir où les
fichiers atterrissent réellement.

## Personnalisation

Les valeurs livrées par défaut (entreprise, mentions légales, intervenant,
types d'intervention, matériel, constats, actions) sont définies dans
`AppSettings.defaults`, dans [`lib/models/app_settings.dart`](lib/models/app_settings.dart).
Elles servent de point de départ et sont toutes modifiables depuis l'écran
Réglages de l'application.

Le logo de `assets/images/logo.png` est celui qui s'imprime tant qu'aucun
n'a été choisi dans les réglages. En choisir un dans Réglages → Logo le
remplace, sans toucher au fichier livré.
