# Règles R8 propres à l'application.
#
# R8 raccourcit et élague le code Java et Kotlin au moment de construire
# l'APK en release. Flutter ajoute déjà ses propres règles, et chaque greffon
# livre les siennes : ce fichier n'a donc rien à contenir tant que rien ne
# casse à l'exécution.
#
# Il doit malgré tout exister : la chaîne de compilation le déclare parmi ses
# fichiers de règles, et son absence fait échouer la tâche minifyRelease.
#
# En cas de plantage qui n'arrive qu'en release — un greffon qui cherche une
# classe par son nom, typiquement — c'est ici qu'on la préserve :
#
#     -keep class fr.exemple.MaClasse { *; }
