"""Dessine l'icone de l'application et la decline dans toutes les tailles.

L'icone dit ce que fait l'application : un rapport (la feuille) sur un metier
de l'eau (la goutte). Elle est dessinee en grand puis reduite, pour que les
bords restent nets a 48 pixels comme a 1024.

    python3 tool/icone.py

reecrit les icones d'Android, d'iOS et du web, plus les visuels de la fiche
Google Play. Aucune dependance en dehors de Pillow :

    pip install Pillow
"""
import json
import pathlib

from PIL import Image, ImageDraw

RACINE = pathlib.Path(__file__).resolve().parent.parent

# Android : densites classiques, en dp.
DENSITES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}

BLEU_FONCE = (16, 76, 126)     # #104C7E, le bleu de l'application
BLEU_MOYEN = (27, 106, 168)
BLEU_CLAIR = (143, 184, 232)   # #8FB8E8
BLEU_PALE = (205, 225, 245)
BLANC = (255, 255, 255)

SS = 4  # facteur de suréchantillonnage


def fond(taille, rayon_ratio=0.2235):
    """Le carré bleu dégradé, coins arrondis."""
    t = taille * SS
    degrade = Image.new('RGB', (1, t))
    for y in range(t):
        k = y / (t - 1)
        degrade.putpixel((0, y), tuple(
            round(BLEU_FONCE[i] + (BLEU_MOYEN[i] - BLEU_FONCE[i]) * k)
            for i in range(3)))
    image = degrade.resize((t, t))

    if rayon_ratio > 0:
        masque = Image.new('L', (t, t), 0)
        ImageDraw.Draw(masque).rounded_rectangle(
            [0, 0, t - 1, t - 1], radius=int(t * rayon_ratio), fill=255)
        sortie = Image.new('RGBA', (t, t), (0, 0, 0, 0))
        sortie.paste(image, (0, 0), masque)
        return sortie

    return image.convert('RGBA')


def goutte(dessin, cx, cy, largeur, couleur):
    """Une goutte d'eau : un disque surmonté d'une pointe."""
    r = largeur / 2
    bas = cy + r
    haut = cy - largeur * 0.92
    dessin.ellipse([cx - r, cy - r, cx + r, cy + r], fill=couleur)
    # Les flancs de la pointe partent des côtés du disque, un peu au-dessus de
    # son centre, pour que le raccord ne fasse pas d'angle.
    dessin.polygon(
        [(cx, haut), (cx + r * 0.995, cy + r * 0.08),
         (cx, bas), (cx - r * 0.995, cy + r * 0.08)],
        fill=couleur,
    )


def glyphe(image, echelle, decalage_y=0.0):
    """La feuille et la goutte, posées sur [image].

    [echelle] vaut 1 pour une icône pleine ; l'icône adaptative d'Android la
    réduit, ses bords pouvant être rognés par la forme du lanceur.
    """
    t = image.size[0]
    d = ImageDraw.Draw(image)
    cx, cy = t / 2, t / 2 + t * decalage_y

    # La feuille.
    largeur = t * 0.455 * echelle
    hauteur = t * 0.585 * echelle
    gauche, haut = cx - largeur / 2, cy - hauteur / 2
    d.rounded_rectangle(
        [gauche, haut, gauche + largeur, haut + hauteur],
        radius=largeur * 0.10,
        fill=BLANC,
    )

    # Les lignes de texte du rapport.
    marge = largeur * 0.155
    epaisseur = hauteur * 0.062
    for i, part in enumerate((1.0, 1.0, 0.62)):
        y = haut + hauteur * (0.17 + i * 0.15)
        d.rounded_rectangle(
            [gauche + marge, y,
             gauche + marge + (largeur - 2 * marge) * part, y + epaisseur],
            radius=epaisseur / 2,
            fill=BLEU_PALE if i < 2 else BLEU_CLAIR,
        )

    # La goutte, posée sur le coin bas-droit de la feuille : un cerne blanc la
    # détache du papier sans la coller au bord.
    gx = gauche + largeur * 0.90
    gy = haut + hauteur * 0.80
    goutte(d, gx, gy, largeur * 0.60, BLANC)
    goutte(d, gx, gy, largeur * 0.60 * 0.80, BLEU_MOYEN)


def icone(taille, rayon_ratio=0.2235, echelle=1.0):
    image = fond(taille, rayon_ratio)
    glyphe(image, echelle)
    return image.resize((taille, taille), Image.LANCZOS)


def premier_plan(taille, echelle=0.66):
    """L'avant-plan de l'icône adaptative Android : le glyphe, fond nu."""
    t = taille * SS
    image = Image.new('RGBA', (t, t), (0, 0, 0, 0))
    glyphe(image, echelle)
    return image.resize((taille, taille), Image.LANCZOS)


def banniere(largeur, hauteur, titre_hauteur=0.62):
    """Le visuel large de la fiche Play Store."""
    degrade = Image.new('RGB', (largeur, 1))
    for x in range(largeur):
        k = x / (largeur - 1)
        degrade.putpixel((x, 0), tuple(
            round(BLEU_FONCE[i] + (BLEU_MOYEN[i] - BLEU_FONCE[i]) * k)
            for i in range(3)))
    image = degrade.resize((largeur, hauteur)).convert('RGBA')

    marque = icone(int(hauteur * titre_hauteur), rayon_ratio=0.2235)
    image.paste(marque, (int(largeur * 0.09),
                         (hauteur - marque.size[1]) // 2), marque)
    return image


# --- Ecriture dans les dossiers des plateformes ------------------------------


def ecrire(image, chemin):
    chemin.parent.mkdir(parents=True, exist_ok=True)
    image.save(chemin)
    print(' ', chemin.relative_to(RACINE), image.size)


def android():
    for densite, k in DENSITES.items():
        dossier = RACINE / 'android/app/src/main/res' / f'mipmap-{densite}'
        # L'icone classique, pour les lanceurs d'avant l'icone adaptative.
        ecrire(icone(round(48 * k)), dossier / 'ic_launcher.png')
        # L'avant-plan de l'icone adaptative : 108 dp, dont seuls les 72 dp
        # centraux sont surs — le lanceur rogne le reste a sa guise.
        ecrire(premier_plan(round(108 * k)),
               dossier / 'ic_launcher_foreground.png')


def ios():
    dossier = RACINE / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    contenu = json.loads((dossier / 'Contents.json').read_text())
    for image in contenu['images']:
        cote = float(image['size'].split('x')[0])
        echelle = int(image['scale'].rstrip('x'))
        # iOS arrondit les coins lui-meme et n'accepte pas la transparence.
        plate = icone(round(cote * echelle), rayon_ratio=0).convert('RGB')
        ecrire(plate, dossier / image['filename'])


def web():
    ecrire(icone(16, rayon_ratio=0.18), RACINE / 'web/favicon.png')
    for taille in (192, 512):
        ecrire(icone(taille), RACINE / f'web/icons/Icon-{taille}.png')
        # Les icones « maskable » sont rognees en cercle par le systeme : le
        # dessin y est plus petit, et le fond va jusqu'aux bords.
        ecrire(icone(taille, rayon_ratio=0, echelle=0.72),
               RACINE / f'web/icons/Icon-maskable-{taille}.png')


def boutique():
    dossier = RACINE / 'store'
    ecrire(icone(512, rayon_ratio=0).convert('RGB'), dossier / 'icone-512.png')
    ecrire(banniere(1024, 500).convert('RGB'),
           dossier / 'banniere-1024x500.png')


if __name__ == '__main__':
    android()
    ios()
    web()
    boutique()
