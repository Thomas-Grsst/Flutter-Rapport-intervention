import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapport_intervention/widgets/app_text_field.dart';

/// Monte un champ dont la valeur vit à l'extérieur, comme dans l'assistant :
/// le brouillon la détient, l'étape la relit à chaque reconstruction.
Future<void> _pump(
  WidgetTester tester, {
  required String Function() lire,
  required void Function(String) ecrire,
  required void Function(StateSetter) exposeSetState,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            exposeSetState(setState);
            return AppTextField(
              initialValue: lire(),
              onChanged: (value) => setState(() => ecrire(value)),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('affiche une valeur changée de l\'extérieur', (tester) async {
    // C'est ce qui arrive quand un client est repris du carnet, ou qu'une
    // réponse rapide est cochée : le brouillon change sous le champ.
    var valeur = '';
    late StateSetter refresh;

    await _pump(
      tester,
      lire: () => valeur,
      ecrire: (v) => valeur = v,
      exposeSetState: (setState) => refresh = setState,
    );

    refresh(() => valeur = 'Association La Roseraie');
    await tester.pump();

    expect(find.text('Association La Roseraie'), findsOneWidget);
  });

  testWidgets('laisse le curseur tranquille pendant la frappe',
      (tester) async {
    // Recopier la valeur à chaque reconstruction ramènerait le curseur à la
    // fin du texte, et la saisie deviendrait impossible au milieu d'un mot.
    var valeur = 'Montanay';
    await _pump(
      tester,
      lire: () => valeur,
      ecrire: (v) => valeur = v,
      exposeSetState: (_) {},
    );

    final champ = find.byType(TextField);
    tester.widget<TextField>(champ).controller!.selection =
        const TextSelection.collapsed(offset: 4);
    await tester.pump();

    expect(
      tester.widget<TextField>(champ).controller!.selection.baseOffset,
      4,
    );
  });

  testWidgets('survit à un brouillon qui élague ce qu\'on lui donne',
      (tester) async {
    // Le rapport range les relevés en retirant les espaces de fin : ce qu'il
    // renvoie n'est donc pas toujours ce qui vient d'être tapé. Réécrire le
    // champ à ce moment-là ramenait le curseur au début du texte, et la
    // frappe suivante s'y insérait — une phrase entière ressortait mélangée.
    var valeur = '';
    await _pump(
      tester,
      lire: () => valeur,
      ecrire: (v) => valeur = v.trim(),
      exposeSetState: (_) {},
    );

    final champ = find.byType(TextField);
    await tester.enterText(champ, 'Nettoyage ');
    await tester.pumpAndSettle();

    // L'espace de fin est encore là : le brouillon l'a retiré de son côté,
    // mais le champ garde ce qui a été tapé tant qu'on y écrit.
    final controleur = tester.widget<TextField>(champ).controller!;
    expect(controleur.text, 'Nettoyage ');
    expect(controleur.selection.baseOffset, 'Nettoyage '.length);

    await tester.enterText(champ, 'Nettoyage du préfiltre');
    await tester.pumpAndSettle();
    expect(valeur, 'Nettoyage du préfiltre');
  });
}
