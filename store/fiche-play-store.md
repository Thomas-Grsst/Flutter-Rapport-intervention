# Fiche Google Play

> **L'application se diffuse aujourd'hui en APK, pas sur le Play Store.** Ce
> dossier est gardé pour le jour où elle y serait publiée — et il faudrait
> alors d'abord vider `AppSettings.defaults` et retirer `assets/images/`, sans
> quoi la fiche et le logo de l'entreprise partiraient à tous ceux qui
> l'installent. Voir la section « Personnalisation » du README.

Tout ce que la console Play demande pour publier l'application, prêt à être
copié-collé. Les visuels sont dans ce même dossier.

---

## Nom de l'application

*30 caractères maximum.*

```
Rapport d'intervention
```

## Description courte

*80 caractères maximum. C'est la ligne qui s'affiche sous le nom dans les
résultats de recherche.*

```
Rapports d'intervention et d'entretien : photos, signatures et PDF, hors ligne.
```

## Description complète

*4 000 caractères maximum.*

```
Rédigez vos rapports d'intervention sur le chantier, depuis votre téléphone,
et repartez avec le PDF prêt à envoyer au client. Plus de compte rendu à
ressaisir le soir sur un traitement de texte.

L'application ne vous demande pas de remplir un document : elle vous pose des
questions courtes, étape par étape, et se charge de la mise en page.

DEUX MODÈLES DE RAPPORT

• Rapport d'intervention — pour une intervention ponctuelle : débouchage,
  curage, vidange, dépannage. Vous décrivez le contexte, le matériel mis en
  œuvre, ce que vous avez constaté et ce que vous avez fait.

• Rapport d'entretien de poste de relevage — pour la visite contractuelle.
  Le contrôle est toujours le même : environnement, cuve, clapet anti-retour,
  flotteurs, pompes, coffret électrique, exutoire. Chaque point se coche d'un
  geste : Excellent, Correct ou À remplacer.

DES PHOTOS QUI PARLENT D'ELLES-MÊMES

Prenez vos photos avant et après, autant que nécessaire. Le rapport les
imprime alignées, l'après sous l'avant, si bien que le client voit le travail
accompli d'un coup d'œil. Sur un rapport d'intervention, les photos se
rangent par lot — le poste, puis les WC — chacun avec son avant, son pendant
et son après.

SIGNATURES SUR PLACE

Le client signe du doigt sur l'écran, à la fin de l'intervention. Votre
cachet d'entreprise, composé à partir de votre fiche, ferme le document.

UN PDF PROFESSIONNEL, TOUT DE SUITE

Page de garde avec votre logo, en-tête et coordonnées sur chaque page,
mentions légales et pagination en pied : le PDF sort mis en page, prêt à
imprimer. Vous pouvez l'afficher, l'imprimer, le télécharger sur le téléphone
ou l'envoyer au client par e-mail, SMS ou messagerie.

CONFIGURÉE UNE FOIS, RÉUTILISÉE TOUJOURS

Renseignez votre entreprise à la première ouverture — nom, adresse, logo,
SIRET, APE, RCS, TVA — et vos intervenants. Tout est repris automatiquement
sur chaque rapport. Les listes de choix rapides (types d'intervention,
matériel, constats, actions) sont livrées remplies et restent modifiables :
ajoutez les vôtres, elles vous seront proposées la fois suivante.

Les numéros de rapport sont attribués tout seuls, à partir du préfixe de
votre choix, de la date et des initiales du client.

RETROUVEZ N'IMPORTE QUEL RAPPORT

Recherche par client, adresse ou numéro, et filtres par statut : en cours,
à suivre, terminés. Un rapport commencé sur le chantier se termine plus tard,
il est enregistré à chaque étape.

100 % HORS LIGNE

Aucun compte, aucune inscription, aucune connexion nécessaire. Tout reste sur
votre téléphone, y compris les photos et les PDF — ce qui compte dans un
sous-sol ou au fond d'un terrain, là où le réseau ne passe pas.

POUR QUI

Assainissement, plomberie, maintenance, entretien de postes de relevage :
toute entreprise qui doit rendre compte d'une intervention par écrit, photos
à l'appui.
```

---

## Classification et informations

| Champ | Valeur |
|---|---|
| Catégorie | Professionnels (Business) |
| Type | Application |
| Application payante | Non, gratuite |
| Publicités | Aucune |
| Achats intégrés | Aucun |
| Public visé | Professionnels, 18 ans et plus |
| Pays | France (à étendre selon vos besoins) |
| Langue | Français |

### Sécurité des données

À déclarer dans la console, section **Sécurité des données** :

- **Aucune donnée collectée ni partagée.** L'application n'envoie rien à
  aucun serveur. Elle n'a pas de compte, pas d'inscription, pas d'analyse
  d'audience.
- Les données saisies (rapports, photos, signatures, PDF) restent dans
  l'espace privé de l'application sur le téléphone, et disparaissent avec sa
  désinstallation.
- **Chiffrement en transit** : sans objet, rien n'est transmis.
- **Suppression des données** : l'utilisateur supprime chaque rapport depuis
  l'application, ou désinstalle l'application.

La politique de confidentialité à publier est dans
[`confidentialite.md`](confidentialite.md) — Google Play en exige l'URL.

### Autorisations demandées

| Autorisation | Pourquoi |
|---|---|
| Appareil photo | Photographier l'intervention |
| Photos et médias | Choisir une photo déjà prise, et le logo de l'entreprise |

---

## Visuels

| Fichier | Usage | Format exigé |
|---|---|---|
| [`icone-512.png`](icone-512.png) | Icône de la fiche | 512 × 512, PNG 32 bits, sans transparence |
| [`banniere-1024x500.png`](banniere-1024x500.png) | Image mise en avant | 1024 × 500, JPEG ou PNG 24 bits |

### Captures d'écran — à faire depuis un vrai téléphone

Google Play en demande **au moins 2**, jusqu'à 8, en 16:9 ou 9:16, chaque
côté entre 320 et 3 840 px. Les plus parlantes, dans cet ordre :

1. La liste des rapports, avec deux ou trois rapports terminés.
2. Le choix du modèle au moment de créer un rapport.
3. Une étape de l'assistant — les constats cochés, par exemple.
4. Une section du poste de relevage avec ses trois états.
5. L'étape des photos, avec un avant et un après.
6. La signature du client.
7. Une page du PDF généré.

Videz vos vrais clients avant de capturer : ces images seront publiques.

---

## Avant de publier — à vérifier

- [ ] Renseigner votre entreprise dans l'application, puis **regénérer un
      rapport** pour vérifier l'en-tête, le logo et les mentions légales.
- [ ] Publier la politique de confidentialité à une URL publique et coller
      l'adresse dans la console.
- [ ] Signer l'application avec votre clé de publication (`key.properties` +
      `android/app/build.gradle.kts`) — la clé de débogage est refusée.
- [ ] Incrémenter `version:` dans `pubspec.yaml` à chaque envoi.
- [ ] `flutter build appbundle --release`, puis envoyer le `.aab`.

Le nom de paquet est `fr.auservicedeleau.rapport_intervention`. Il identifie
l'application pour toujours : **il ne pourra plus changer** après la première
publication.
