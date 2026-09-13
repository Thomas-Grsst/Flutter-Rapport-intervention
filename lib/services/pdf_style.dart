import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/company.dart';
import '../models/enums.dart';
import '../models/photo_item.dart';

/// La charte des rapports en PDF : les couleurs et les elements de mise en
/// page communs aux deux modeles.
///
/// Les deux rapports sortent de la meme entreprise et se lisent l'un apres
/// l'autre : ils portent le meme en-tete, le meme pied de page, les memes
/// titres de section et les memes cadres. Tout cela vit ici plutot qu'en deux
/// exemplaires, pour qu'une retouche de style les suive tous les deux.
class PdfStyle {
  const PdfStyle._();

  static const PdfColor brandDark = PdfColor.fromInt(0xFF104C7E);
  static const PdfColor brandLight = PdfColor.fromInt(0xFF8FB8E8);
  static const PdfColor paleBlue = PdfColor.fromInt(0xFFEAF2FB);
  static const PdfColor lineGrey = PdfColor.fromInt(0xFFD5DEE8);
  static const PdfColor textGrey = PdfColor.fromInt(0xFF5A6773);

  // --- Page de garde --------------------------------------------------------

  /// La page de garde : le titre du rapport, son objet et sa date, sous le
  /// logo et le long d'un bandeau bleu.
  static pw.Page coverPage({
    required String title,
    required String subtitle,
    required String dateLine,
    required Company company,
    pw.MemoryImage? logo,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (context) {
        return pw.Stack(
          children: [
            // Bandeau bleu vertical à gauche.
            pw.Positioned(
              left: 0,
              top: 0,
              child: pw.Container(
                width: 18,
                height: PdfPageFormat.a4.height,
                color: brandLight,
              ),
            ),
            // Largeur et hauteur explicites : la colonne ci-dessous utilise
            // des Spacer, qui ont besoin de contraintes bornées.
            pw.Container(
              width: PdfPageFormat.a4.width,
              height: PdfPageFormat.a4.height,
              padding: const pw.EdgeInsets.fromLTRB(60, 70, 45, 45),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logo != null)
                    pw.Container(
                      height: 110,
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    ),
                  pw.Spacer(),
                  pw.Text(
                    title,
                    style: const pw.TextStyle(
                      fontSize: 34,
                      fontWeight: pw.FontWeight.bold,
                      color: brandDark,
                    ),
                  ),
                  pw.SizedBox(height: 14),
                  pw.Container(width: 120, height: 3, color: brandLight),
                  pw.SizedBox(height: 22),
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(
                      fontSize: 18,
                      color: brandDark,
                      letterSpacing: 0.6,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    dateLine,
                    style: const pw.TextStyle(fontSize: 14, color: textGrey),
                  ),
                  pw.Spacer(),
                  if (company.name.isNotEmpty)
                    pw.Text(
                      company.name.toUpperCase(),
                      style: const pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: brandDark,
                      ),
                    ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    company.contactLine,
                    style: const pw.TextStyle(fontSize: 9.5, color: textGrey),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // --- En-tête et pied de page ----------------------------------------------

  /// En-tête de chaque page : le logo à gauche, les coordonnées de
  /// l'entreprise à droite, comme sur le modèle papier.
  static pw.Widget pageHeader(Company company, pw.MemoryImage? logo) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: brandLight, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logo != null)
            pw.Container(
              height: 46,
              width: 90,
              alignment: pw.Alignment.centerLeft,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            )
          else
            pw.SizedBox(width: 90),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (company.displayName.isNotEmpty)
                pw.Text(
                  company.displayName,
                  style: const pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: brandDark,
                  ),
                ),
              for (final line in company.contactLines)
                pw.Text(
                  line,
                  style: const pw.TextStyle(fontSize: 8, color: textGrey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Pied de page : les mentions légales de l'entreprise et la pagination.
  ///
  /// Les mentions sont centrées sur toute la largeur et la pagination passe
  /// en dessous : mises côte à côte, une raison sociale un peu longue passait
  /// à la ligne et le numéro de page se retrouvait au milieu du texte.
  static pw.Widget pageFooter(pw.Context context, Company company) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: lineGrey)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            company.legalLine,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 6.5, color: textGrey),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7.5, color: textGrey),
          ),
        ],
      ),
    );
  }

  // --- Blocs de texte -------------------------------------------------------

  static pw.Widget sectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: brandDark,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(width: 60, height: 2, color: brandLight),
        ],
      ),
    );
  }

  static pw.Widget paragraph(String text) => pw.Paragraph(
        text: text,
        style: const pw.TextStyle(fontSize: 10, lineSpacing: 2.5),
        margin: const pw.EdgeInsets.only(bottom: 6),
      );

  static pw.Widget label(String text) => pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          color: brandDark,
        ),
      );

  /// Une ligne à puce. [value], quand il est donné, se détache du reste :
  /// c'est l'état relevé, ce que le lecteur cherche des yeux.
  static pw.Widget bullet(String text, {String value = ''}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4, left: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 4,
              height: 4,
              margin: const pw.EdgeInsets.only(top: 4, right: 7),
              decoration: const pw.BoxDecoration(
                color: brandDark,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.Expanded(
              child: value.isEmpty
                  ? pw.Text(
                      text,
                      style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
                    )
                  : pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(
                            text: '$text : ',
                            style: const pw.TextStyle(
                                fontSize: 10, lineSpacing: 2),
                          ),
                          pw.TextSpan(
                            text: value,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              lineSpacing: 2,
                              fontWeight: pw.FontWeight.bold,
                              color: brandDark,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      );

  /// Regroupe des éléments pour que la coupure entre deux pages ne tombe
  /// jamais entre eux.
  ///
  /// Sert à ne pas laisser un titre de section seul en bas d'une page, son
  /// contenu commençant sur la suivante. À n'utiliser que sur des blocs dont
  /// la hauteur est bornée : un bloc insécable plus haut qu'une page ne
  /// pourrait être posé nulle part.
  static pw.Widget keepTogether(List<pw.Widget> children) => pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: children,
        ),
      );

  /// Un cadre bleu pâle titré, pour les blocs d'identification.
  static pw.Widget infoBox({
    required String title,
    required List<String> lines,
  }) {
    final visible = lines.map((line) => line.trim()).toList();
    // On retire les lignes vides en fin de bloc mais on garde les séparateurs
    // internes, qui aèrent le bloc "Entreprise".
    while (visible.isNotEmpty && visible.last.isEmpty) {
      visible.removeLast();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: paleBlue,
        border: pw.Border.all(color: lineGrey),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: brandDark,
            ),
          ),
          pw.SizedBox(height: 6),
          for (final line in visible)
            line.isEmpty
                ? pw.SizedBox(height: 6)
                : pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 1.5),
                    child: pw.Text(
                      line,
                      style: const pw.TextStyle(fontSize: 9.5),
                    ),
                  ),
        ],
      ),
    );
  }

  // --- Photographies --------------------------------------------------------

  /// Une photo dans son cadre, avec sa pastille de moment et sa légende.
  ///
  /// [fit] vaut `cover` là où les vignettes doivent toutes faire la même
  /// taille, et `contain` là où la photo se lit pour elle-même : un cadrage
  /// automatique couperait justement ce que l'intervenant a voulu montrer.
  static pw.Widget photoCard(
    PhotoItem photo,
    pw.MemoryImage image, {
    double height = 112,
    pw.BoxFit fit = pw.BoxFit.cover,
    bool showStage = true,
  }) {
    final caption = photo.caption.trim();
    final stamped = showStage && photo.stage != PhotoStage.autre;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: height,
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: lineGrey),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 3,
            verticalRadius: 3,
            child: pw.Image(image, fit: fit),
          ),
        ),
        if (stamped || caption.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (stamped)
                pw.Container(
                  margin: const pw.EdgeInsets.only(right: 6),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1.5),
                  decoration: pw.BoxDecoration(
                    color: brandDark,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                  child: pw.Text(
                    photo.stage.label.toUpperCase(),
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.white),
                  ),
                ),
              pw.Expanded(
                child: pw.Text(
                  caption,
                  style: const pw.TextStyle(fontSize: 8.5, color: textGrey),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Le cadre ou vient une signature, sous son intitule.
  static pw.Widget signatureBox({
    required String title,
    required String caption,
    pw.MemoryImage? signature,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: brandDark,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Container(
          height: 70,
          width: double.infinity,
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: lineGrey)),
          child: signature == null
              ? pw.SizedBox()
              : pw.Image(signature, fit: pw.BoxFit.contain),
        ),
        pw.SizedBox(height: 5),
        pw.Text(caption,
            style: const pw.TextStyle(fontSize: 8.5, color: textGrey)),
      ],
    );
  }

  // --- Mention de bas de document -------------------------------------------

  /// La phrase en petits caractères qui ferme le document.
  static pw.Widget legalNotice(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: lineGrey)),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 7.5,
          color: textGrey,
          fontStyle: pw.FontStyle.italic,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }
}
