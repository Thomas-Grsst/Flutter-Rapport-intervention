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

Le PDF sort dans la même charte que le rapport d'intervention — même page de
garde, même en-tête, mêmes cadres d'identification, mêmes titres de section et
mêmes cadres photo. Les deux rapports sortent de la même entreprise et se
lisent l'un après l'autre : la charte est écrite une seule fois, dans
[`lib/services/pdf_style.dart`](lib/services/pdf_style.dart).

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
- **Export PDF** : aperçu, impression, téléchargement du fichier sur l'appareil
  et envoi au client par e-mail, SMS ou messagerie. Le téléchargement écrit
  dans le dossier de téléchargements du téléphone ; dans un navigateur, c'est
  lui qui reçoit le fichier. Faute de dossier de téléchargements — c'est le cas
  sur iOS —, la feuille de partage du système prend le relais, avec son
  « Enregistrer dans Fichiers ».
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
│   ├── pdf_style.dart            Charte commune aux deux rapports
│   ├── pdf_service.dart          Génération du PDF mis en page
│   ├── relevage_pdf.dart         Mise en page du poste de relevage
│   └── pdf_download.dart         Téléchargement du PDF sur l'appareil
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

L'application est distribuée en APK à l'entreprise qui l'utilise : ses valeurs
par défaut — fiche entreprise, mentions légales, intervenants, préfixe des
numéros de rapport, types d'intervention, matériel, constats, actions — sont
donc livrées remplies dans `AppSettings.defaults`
([`lib/models/app_settings.dart`](lib/models/app_settings.dart)). Le premier
rapport sort complet sans rien avoir à configurer, et tout reste modifiable
depuis l'écran Réglages.

Le logo de `assets/images/logo.png` s'imprime tant qu'aucun n'a été choisi
dans les réglages. En choisir un dans Réglages → Logo le remplace, sans
toucher au fichier livré.

**Pour une autre entreprise**, il y a trois endroits à reprendre : les valeurs
de `AppSettings.defaults`, le fichier `assets/images/logo.png`, et le nom de
paquet `fr.auservicedeleau.rapport_intervention` (dans
`android/app/build.gradle.kts`, `android/app/src/main/kotlin/…` et
`ios/Runner.xcodeproj/project.pbxproj`). Un bandeau sur l'accueil invite à
remplir Réglages → Mon entreprise si la fiche se retrouve vide ; sans préfixe,
les rapports sont numérotés `RAP-120326-MB`.

## Construire l'APK

```bash
flutter build apk --release
```

Le fichier atterrit dans `build/app/outputs/flutter-apk/app-release.apk` :
copiez-le sur le téléphone et ouvrez-le. Android demandera d'autoriser
l'installation d'applications de cette source — c'est normal en dehors du
Play Store.

Un APK par architecture, trois fois plus léger à transférer :

```bash
flutter build apk --release --split-per-abi
```

Celui qui convient à la quasi-totalité des téléphones récents est
`app-arm64-v8a-release.apk`.

### Le NDK est nécessaire

Une compilation en `--release` réclame le **NDK Android**, même si
l'application ne contient pas une ligne de code natif : le moteur Flutter
livre un `libflutter.so` de 165 Mo par architecture, que Gradle dépouille de
ses symboles de débogage avec l'outil `strip` du NDK. Sans lui, l'APK dépasse
490 Mo au lieu d'une trentaine.

Gradle l'installe tout seul la première fois. Si l'installation échoue
(« *Install NDK (Side by side) … failed* »), passez par l'interface plutôt que
par la ligne de commande : Android Studio → **Settings** → *Languages &
Frameworks* → **Android SDK** → onglet **SDK Tools** → cochez **Show Package
Details** → dépliez **NDK (Side by side)** → cochez la version que Gradle
réclame.

### Signer avec votre clé

Sans clé de publication, Flutter signe l'APK avec sa clé de débogage. Il
s'installe très bien, mais **une mise à jour ne remplace une application
installée que si elle porte la même signature** : recompiler depuis un autre
PC obligerait à désinstaller puis réinstaller, en perdant tous les rapports.
Une vraie clé règle la question une fois pour toutes.

Créez le magasin de clés, une seule fois, hors du dépôt :

```bash
keytool -genkey -v -keystore %USERPROFILE%\cle-rapport.jks ^
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias rapport
```

`keytool` est livré avec le JDK d'Android Studio ; si la commande est
introuvable, elle se trouve dans
`C:\Program Files\Android\Android Studio\jbr\bin`.

Copiez ensuite
[`android/key.properties.exemple`](android/key.properties.exemple) en
`android/key.properties` et remplissez-le. La prochaine compilation en
`--release` utilisera cette clé ; sans ce fichier, elle retombe sur la clé de
débogage.

> `key.properties` et le `.jks` ne sont pas versionnés, et ne doivent jamais
> l'être : qui les détient peut signer une mise à jour au nom de
> l'application. **Sauvegardez-les ailleurs que sur le PC de compilation** —
> une clé perdue, c'est l'impossibilité de mettre à jour les applications
> déjà installées.

L'icône de l'application est dessinée par [`tool/icone.py`](tool/icone.py),
qui la décline dans toutes les tailles d'Android, d'iOS et du web :

```bash
python3 tool/icone.py
```

Le dossier [`store/`](store/) garde de quoi publier sur Google Play le jour où
ce serait utile : [fiche à copier-coller](store/fiche-play-store.md),
[politique de confidentialité](store/confidentialite.md), icône 512 × 512 et
image mise en avant. Ces fichiers ne servent à rien pour une diffusion en APK.
