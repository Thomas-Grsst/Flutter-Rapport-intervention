# Rapport d'intervention

Application mobile Flutter qui permet à un intervenant de saisir un rapport
depuis son téléphone, sur le chantier, et d'en générer le PDF mis en page —
sans passer par Word.

## Deux modèles de rapport

Le type se choisit au moment de créer le rapport ; l'assistant et le PDF
s'adaptent ensuite tout seuls.

| Modèle | Quand | Ce qu'il produit |
|---|---|---|
| **Rapport d'intervention** | Une intervention ponctuelle, dont le contenu change à chaque fois | Le modèle papier de référence : blocs client / entreprise / adresse d'intervention, observations, matériel mis en œuvre, constats et actions, photographies, conclusions, points restants, récapitulatif, évaluation du client et signatures |
| **Entretien poste de relevage** | La visite d'entretien contractuelle | Un gabarit figé : bandeau du contrat, bloc client, puis les huit sections du poste, chacune avec ses états relevés et ses photos |

## Le rapport d'intervention

L'intervenant ne remplit pas un document : il répond à une série de questions
courtes, réparties en sept étapes.

| Étape | Ce qu'on demande |
|---|---|
| 1. Le chantier | Client, adresse d'intervention, localisation, type d'intervention, dates, intervenants |
| 2. Observations | Contexte de l'intervention et contraintes d'accès |
| 3. Matériel | Cases à cocher (camion hydrocureur, tuyaux, caméra…) |
| 4. Constats et actions | Constats cochés + précisions libres, actions cochées |
| 5. Photos | Un lot par point de l'intervention, avec son avant / pendant / après |
| 6. Conclusion | Statut, conclusion, points restants, horaires |
| 7. Validation | Évaluation du client et signatures tactiles |

L'application se charge ensuite de la mise en page, du logo, des coordonnées,
du pied de page et de la pagination.

## Le rapport d'entretien de poste de relevage

Celui-là ne varie jamais : les mêmes sections, dans le même ordre, avec les
mêmes intitulés. Seuls changent le client, le lieu, les états relevés et les
photos. Le gabarit est donc écrit en dur dans
[`lib/models/relevage_template.dart`](lib/models/relevage_template.dart), et
l'assistant le déroule section par section — une étape par section, dans
l'ordre où l'intervenant fait le tour de l'installation.

| Étape | Ce qu'on demande |
|---|---|
| 1. Le client | Nom, adresse, téléphone, e-mail, intervenants |
| 2. Le poste | Date du contrat de maintenance, marque et type du poste |
| 3 à 9. Les sections | Environnement, cuve, clapet anti-retour, flotteurs, pompe(s), coffret électrique, exutoire |
| 10. Observations | Ce que le client doit savoir, en texte libre |

Chaque point de contrôle se coche d'un geste — **Excellent**, **Correct** ou
**À remplacer** (**Oui** / **Non** pour l'alarme avant entretien) — et reste
précisable en toutes lettres juste à côté.

Chaque section porte ses propres photos, en deux temps : un **avant** et un
**après**, autant de photos que nécessaire dans chacun. Le rapport imprime les
« avant » sur une rangée et les « après » juste en dessous, à la même largeur,
si bien qu'une photo d'après tombe sous celle d'avant à laquelle elle répond.
L'un des deux temps peut manquer : tout ne se photographie pas deux fois.

## Fonctionnalités

- **Deux modèles de rapport**, choisis à la création : l'intervention ponctuelle
  et l'entretien de poste de relevage, qui suit un gabarit figé.
- **Saisie guidée**, enregistrée automatiquement à chaque changement d'étape :
  un rapport peut être commencé sur le chantier et terminé plus tard.
- **Cases à cocher configurables** pour le matériel, les constats et les
  actions. Une saisie libre (« Autre… ») est mémorisée et proposée sur les
  rapports suivants.
- **Proposition de conclusion** composée à partir du type d'intervention, des
  constats et des actions. Le texte reste entièrement modifiable.
- **Photos par lot** : un lot par point de l'intervention (le poste, puis les
  WC), chacun avec sa case avant, pendant et après — n'importe laquelle peut
  rester vide. Le rapport imprime chaque lot sur sa ligne, colonnes alignées,
  si bien qu'un « après » tombe toujours en face de l'« avant » auquel il
  répond. Les photos sont redimensionnées à l'import pour que le PDF reste
  envoyable en 4G.
- **Cachet et signatures** : le rapport se termine par le cachet de
  l'entreprise, composé à partir de sa fiche, avec la signature de
  l'intervenant par-dessus — plus la signature du client.
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

Les rapports et les réglages tiennent dans le stockage local, les photos,
signatures et PDF dans IndexedDB — le stockage local plafonne à 5 Mo, soit une
vingtaine de photos de téléphone pour l'ensemble des rapports. La limite qui
reste est que les données appartiennent au navigateur utilisé : pour un usage
réel sur le terrain, c'est la version mobile qu'il faut installer.

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
├── models/                    Report, PhotoGroup, PhotoItem, Company, AppSettings
│   └── relevage_template.dart Le gabarit figé du poste de relevage
├── services/
│   ├── storage_service.dart      Interface de stockage
│   ├── storage_service_io.dart   Fichiers, sur téléphone
│   ├── storage_service_web.dart  Stockage du navigateur
│   ├── media_store_web.dart      Photos du navigateur (IndexedDB)
│   ├── pdf_service.dart          Génération du PDF mis en page
│   └── relevage_pdf.dart         Mise en page du poste de relevage
├── state/                     ReportsProvider, SettingsProvider
├── screens/
│   ├── home_screen.dart       Liste, recherche, filtres, choix du modèle
│   ├── report_wizard_screen.dart     Assistant du rapport d'intervention
│   ├── relevage_wizard_screen.dart   Assistant du poste de relevage
│   ├── report_detail_screen.dart     Fiche et export PDF
│   ├── settings_screen.dart   Entreprise, intervenants, listes
│   └── steps/                 Les étapes des deux assistants
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
