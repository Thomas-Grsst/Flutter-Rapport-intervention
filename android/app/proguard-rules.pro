# Règles R8 propres à l'application.
#
# R8 raccourcit et élague le code Java et Kotlin au moment de construire
# l'APK en release. Il décide quoi garder en suivant les références depuis les
# points d'entrée ; ce qu'il croit inatteignable disparaît. Un plugin élagué à
# tort ne se voit qu'à l'exécution, et seulement en release : l'application
# s'ouvre et se referme aussitôt, sans message.
#
# Ce fichier doit par ailleurs exister : la chaîne de compilation le déclare
# parmi ses fichiers de règles, et son absence fait échouer minifyRelease.

# Le point d'entrée Android. Il est déclaré dans le manifeste, donc déjà
# préservé par les règles qu'engendre AGP, mais le perdre coûte si cher qu'on
# ne s'en remet pas à une génération automatique.
-keep class fr.auservicedeleau.rapport_intervention.MainActivity { *; }

# Les greffons de l'application. Ils ne sont appelés que depuis du code Dart,
# par leur nom de canal : rien dans le code Java ne pointe vers leurs méthodes,
# et R8 s'est déjà trompé sur ce motif (flutter/flutter#154580).
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class net.nfet.flutter.printing.** { *; }

# image_picker rend la main par une activité que le système relance, et relit
# alors son état enregistré par réflexion.
-keep class androidx.lifecycle.DefaultLifecycleObserver

# Les classes engendrées par Pigeon portent le dialogue entre Dart et Java des
# greffons ci-dessus : leurs constructeurs et leurs champs sont lus par nom.
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }

# Avertissements sans objet : ces classes ne sont pas dans l'APK, mais rien ne
# les appelle non plus. Sans cette ligne, R8 refuse de continuer.
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
