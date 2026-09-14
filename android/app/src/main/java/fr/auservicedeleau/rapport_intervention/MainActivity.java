package fr.auservicedeleau.rapport_intervention;

import io.flutter.embedding.android.FlutterActivity;

/**
 * Le point d'entree Android de l'application : il n'existe que pour porter le
 * moteur Flutter, tout le reste est ecrit en Dart.
 *
 * Il est en Java, et non en Kotlin, a dessein. Compiler du Kotlin dans le
 * module de l'application demande le plugin Gradle Kotlin, que le bloc
 * `plugins` ne declare pas : Flutter l'appliquait de lui-meme, ce qu'il ne
 * fait plus. Le fichier Kotlin cessait alors d'etre compile en silence — la
 * construction de l'APK reussissait, et le telephone refermait l'application
 * des son ouverture, faute de trouver cette classe. Le Java d'un module
 * Android, lui, se compile sans rien reclamer.
 */
public class MainActivity extends FlutterActivity {
}
